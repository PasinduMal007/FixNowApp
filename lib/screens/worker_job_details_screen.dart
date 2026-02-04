import 'package:flutter/material.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:fix_now_app/screens/worker_create_invoice_screen.dart';
import 'package:firebase_database/firebase_database.dart';

class WorkerJobDetailsScreen extends StatefulWidget {
  final String bookingKey; // RTDB push key

  const WorkerJobDetailsScreen({super.key, required this.bookingKey});

  @override
  State<WorkerJobDetailsScreen> createState() => _WorkerJobDetailsScreenState();
}

class _WorkerJobDetailsScreenState extends State<WorkerJobDetailsScreen> {
  DatabaseReference get _bookingRef =>
      DB.ref().child('bookings/${widget.bookingKey}');

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return <String, dynamic>{};
  }

  List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v.whereType<String>().toList();
    }
    return const <String>[];
  }

  String _pickFirstNonEmpty(List<String> values, {String fallback = ''}) {
    for (final s in values) {
      final t = s.trim();
      if (t.isNotEmpty) return t;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _bookingRef.onValue,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: _errorScaffold(context, 'Failed to load: ${snap.error}'),
          );
        }

        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: _loadingScaffold(context),
          );
        }

        final raw = snap.data!.snapshot.value;
        final booking = _asMap(raw);

        if (booking.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: _errorScaffold(context, 'Booking not found.'),
          );
        }

        // --- Support old + new shapes ---
        final quotationRequest = _asMap(booking['quotationRequest']);
        final quoteRequest = _asMap(booking['quoteRequest']);

        final customerName =
            (booking['customerName'] ?? booking['customer'] ?? 'Customer')
                .toString();

        final serviceName = _pickFirstNonEmpty([
          (quotationRequest['requestNote'] ?? '').toString(),
          (booking['serviceType'] ?? '').toString(),
          (booking['service'] ?? '').toString(),
          (quotationRequest['serviceName'] ?? '').toString(),
          (quoteRequest['title'] ?? '').toString(),
        ], fallback: 'Service');

        final description = _pickFirstNonEmpty([
          (booking['problemDescription'] ?? '').toString(),
          (quotationRequest['requestNote'] ?? '').toString(),
          (quoteRequest['description'] ?? '').toString(),
          (booking['issue'] ?? '').toString(),
          (booking['description'] ?? '').toString(),
        ], fallback: 'No description provided');

        final location = _pickFirstNonEmpty([
          (booking['locationText'] ?? '').toString(),
          (booking['location'] ?? '').toString(),
        ], fallback: 'Not specified');

        String date = (booking['date'] ?? booking['scheduledDate'] ?? '')
            .toString();
        String time = (booking['time'] ?? booking['scheduledTime'] ?? '')
            .toString();

        if (date.contains('PM') || date.contains('AM')) {
          final parts = date.split(' ');
          if (parts.length >= 2) {
            time = '${parts[parts.length - 2]} ${parts[parts.length - 1]}';
            date = parts.sublist(0, parts.length - 2).join(' ');
          }
        }

        date = date.trim().isEmpty ? 'Not specified' : date;
        time = time.trim().isEmpty ? 'Not specified' : time;

        final status = (booking['status'] ?? '').toString();

        final canAccept = status == 'pending';
        final canOpenInvoice =
            status == 'confirmed' || status == 'invoice_sent';

        final photos = _asStringList(booking['photos']).isNotEmpty
            ? _asStringList(booking['photos'])
            : _asStringList(quotationRequest['photos']);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),

          // ✅ your existing body (same UI)
          body: Column(
            children: [
              // Header with gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A7FFF), Color(0xFF3B6FE8)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Request Quote from $customerName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('What customer want'),
                      const SizedBox(height: 12),
                      _highlightBox(serviceName),
                      const SizedBox(height: 24),

                      _sectionTitle('Description'),
                      const SizedBox(height: 12),
                      _normalBox(description),
                      const SizedBox(height: 24),

                      if (photos.isNotEmpty) ...[
                        _sectionTitle('Photos'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            itemBuilder: (context, index) {
                              final url = photos[index];
                              return Container(
                                width: 100,
                                height: 100,
                                margin: EdgeInsets.only(
                                  right: index < photos.length - 1 ? 12 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      _sectionTitle('Date:'),
                      const SizedBox(height: 12),
                      _iconRowBox(Icons.calendar_today, date),
                      const SizedBox(height: 20),

                      _sectionTitle('Time:'),
                      const SizedBox(height: 12),
                      _iconRowBox(Icons.access_time, time),
                      const SizedBox(height: 24),

                      _sectionTitle('Location:'),
                      const SizedBox(height: 12),
                      _iconRowBox(
                        Icons.location_on,
                        location,
                        iconColor: const Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 24),

                      _sectionTitle('Status:'),
                      const SizedBox(height: 12),
                      _normalBox(status.isEmpty ? 'Unknown' : status),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ✅ bottom nav now has access to canAccept
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _bookingRef.update({
                          'status': 'declined_by_worker',
                          'updatedAt': DateTime.now().millisecondsSinceEpoch,
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job declined'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canAccept
                          ? () async {
                              final bookingId = widget.bookingKey;

                              try {
                                await DB
                                    .ref()
                                    .child('bookings/$bookingId')
                                    .update({
                                      'status': 'confirmed',
                                      'updatedAt':
                                          DateTime.now().millisecondsSinceEpoch,
                                    });

                                if (!context.mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkerCreateInvoiceScreen(
                                      job: {'id': bookingId},
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to accept job: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : (canOpenInvoice
                                ? () {
                                    final bookingId = widget.bookingKey;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WorkerCreateInvoiceScreen(
                                              job: {'id': bookingId},
                                            ),
                                      ),
                                    );
                                  }
                                : null),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        canAccept
                            ? 'Accept Job'
                            : (canOpenInvoice ? 'Open Invoice' : 'Accept Job'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- UI helpers ----

  Widget _loadingScaffold(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A7FFF), Color(0xFF3B6FE8)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _errorScaffold(BuildContext context, String message) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A7FFF), Color(0xFF3B6FE8)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Request details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _highlightBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A7FFF), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _normalBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF374151),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _iconRowBox(IconData icon, String text, {Color? iconColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? const Color(0xFF4A7FFF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
