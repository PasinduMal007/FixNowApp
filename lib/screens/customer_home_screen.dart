import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/services/db.dart';
import 'customer_notifications_screen.dart';
import 'customer_search_results_screen.dart';
import 'customer_service_category_screen.dart';
import 'customer_live_tracking_screen.dart';
import 'customer_chat_conversation_screen.dart';
import 'customer_view_quotation_screen.dart';
import 'customer_worker_profile_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_static_view_quotation_screen.dart';
import 'customer_job_completion_screen.dart';
import 'package:fix_now_app/Services/chat_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  final String customerName;

  const CustomerHomeScreen({super.key, required this.customerName});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // Service categories
  final List<Map<String, dynamic>> _serviceCategories = [
    {'name': 'Electrician', 'icon': Icons.bolt, 'color': Color(0xFFFBBF24)},
    {'name': 'Plumber', 'icon': Icons.plumbing, 'color': Color(0xFF3B82F6)},
    {'name': 'Carpenter', 'icon': Icons.handyman, 'color': Color(0xFF10B981)},
    {'name': 'Mason', 'icon': Icons.foundation, 'color': Color(0xFF8B5CF6)},
    {'name': 'Painter', 'icon': Icons.format_paint, 'color': Color(0xFFEC4899)},
    {'name': 'Mechanic', 'icon': Icons.settings, 'color': Color(0xFF6B7280)},
    {'name': 'Welder', 'icon': Icons.flash_on, 'color': Color(0xFFF59E0B)},
    {
      'name': 'AC Technician',
      'icon': Icons.ac_unit,
      'color': Color(0xFF60A5FA),
    },
    {'name': 'Tile Setter', 'icon': Icons.grid_on, 'color': Color(0xFF9CA3AF)},
    {'name': 'Roofer', 'icon': Icons.roofing, 'color': Color(0xFFB45309)},
    {'name': 'Gardener', 'icon': Icons.grass, 'color': Color(0xFF22C55E)},
    {
      'name': 'Cleaner',
      'icon': Icons.cleaning_services_outlined,
      'color': Color(0xFF06B6D4),
    },
  ];

  late Stream<DatabaseEvent> _workersStream;
  late Stream<List<Map<String, dynamic>>> _activeServiceStream;
  StreamSubscription<DatabaseEvent>? _districtSub;
  String _customerDistrict = '';

  @override
  void initState() {
    super.initState();
    _workersStream = DB.ref().child('workersPublic').onValue;
    _activeServiceStream = _createActiveServiceStream();
    _startRealTimeUpdates();
    _listenCustomerDistrict();
  }

  Stream<List<Map<String, dynamic>>> _createActiveServiceStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final customerId = user.uid;

    final q = DB.instance
        .ref('bookings')
        .orderByChild('customerId')
        .equalTo(customerId);

    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      return 0;
    }

    return q.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return [];

      final all = Map<dynamic, dynamic>.from(raw as Map);
      final List<Map<String, dynamic>> active = [];

      all.forEach((bookingId, value) {
        if (value is! Map) return;

        final b = Map<String, dynamic>.from(value as Map);

        final status = (b['status'] ?? '').toString();

        // Include both 'invoice_sent' (Quotation Ready) and 'started' (In Progress)
        if (status != 'invoice_sent' && status != 'started') return;

        b['id'] = bookingId.toString();
        b['updatedAt'] = _asInt(b['updatedAt']);
        active.add(b);
      });

      // Sort by updatedAt descending (newest first)
      active.sort((a, b) {
        final ua = _asInt(a['updatedAt']);
        final ub = _asInt(b['updatedAt']);
        return ub.compareTo(ua);
      });

      return active;
    });
  }

  // Helper method restored
  List<Map<String, dynamic>> _mapWorkersFromSnapshot(DataSnapshot snap) {
    final list = <Map<String, dynamic>>[];
    for (final child in snap.children) {
      final key = (child.key ?? '').toString();
      if (child.value is! Map) continue;
      final data = Map<String, dynamic>.from(child.value as Map);

      final fullName = (data['fullName'] ?? '').toString().trim();
      final profession = (data['profession'] ?? '').toString().trim();
      final ratingVal = data['rating'];
      final reviewsVal = data['reviews'];

      final rating = (ratingVal is num)
          ? ratingVal.toDouble()
          : double.tryParse(ratingVal?.toString() ?? '') ?? 0.0;

      final reviews = (reviewsVal is num)
          ? reviewsVal.toInt()
          : int.tryParse(reviewsVal?.toString() ?? '') ?? 0;

      final isAvailableVal = data['isAvailable'];
      final isAvailable = isAvailableVal is bool ? isAvailableVal : false;
      final district = (data['district'] ?? '').toString().trim();

      final rawLat = (data['lat'] is num)
          ? (data['lat'] as num).toDouble()
          : 6.9271;
      final rawLng = (data['lng'] is num)
          ? (data['lng'] as num).toDouble()
          : 79.8612;

      // ⚠️ FIX: Spread markers if they are at default location or identical
      // using a deterministic offset based on UID hash
      double lat = rawLat;
      double lng = rawLng;

      if ((rawLat - 6.9271).abs() < 0.0001 &&
          (rawLng - 79.8612).abs() < 0.0001) {
        final hash = key.codeUnits.fold(0, (p, c) => p + c);
        final offsetLat = ((hash % 100) - 50) / 5000.0; // +/- 0.01
        final offsetLng = ((hash % 90) - 45) / 5000.0;
        lat += offsetLat;
        lng += offsetLng;
      }

      list.add(<String, dynamic>{
        'uid': (data['uid'] ?? key).toString(),
        'name': fullName.isEmpty ? 'Worker' : fullName,
        'type': profession,
        'rating': rating,
        'reviews': reviews,
        'distance': (data['distance'] is num)
            ? (data['distance'] as num).toDouble()
            : 0.0,
        'experience': (data['experience'] ?? 0),
        'description': (data['description'] ?? '').toString(),
        'isAvailable': isAvailable,
        'photoUrl': (data['photoUrl'] ?? '').toString(),
        'locationText': (data['locationText'] ?? '').toString(),
        'district': district,
        'lat': lat,
        'lng': lng,
      });
    }
    return list;
  }

  String _selectedFilter = 'Top Rated';

  // Real-time update variables
  Timer? _updateTimer;
  int _arrivingMinutes = 15;
  double _distanceKm = 1.3;

  @override
  void dispose() {
    _updateTimer?.cancel();
    _districtSub?.cancel();
    super.dispose();
  }

  void _listenCustomerDistrict() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _districtSub?.cancel();
    _districtSub = DB.ref()
        .child('users/customers/$uid/district')
        .onValue
        .listen((event) {
      final v = event.snapshot.value;
      final next = (v ?? '').toString().trim();
      if (!mounted) return;
      setState(() => _customerDistrict = next);
    });
  }

  void _startRealTimeUpdates() {
    // Update arrival time and distance every 3 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Decrease arrival time
        if (_arrivingMinutes > 0) {
          _arrivingMinutes--;
        }

        // Decrease distance (assume worker moving at ~10 km/h)
        if (_distanceKm > 0.1) {
          _distanceKm -= 0.05; // Reduce by 50 meters every 3 seconds
        } else {
          _distanceKm = 0.0;
          _arrivingMinutes = 0;
          timer.cancel(); // Stop when arrived
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting and Icons
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hi there 👋',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.customerName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        StreamBuilder<DatabaseEvent>(
                          stream: DB.instance
                              .ref('notifications')
                              .child(FirebaseAuth.instance.currentUser!.uid)
                              .onValue,
                          builder: (context, snapshot) {
                            bool hasUnread = false;

                            if (snapshot.hasData &&
                                snapshot.data!.snapshot.value != null) {
                              final raw = snapshot.data!.snapshot.value;

                              if (raw is Map) {
                                final map = Map<dynamic, dynamic>.from(raw);

                                for (final n in map.values) {
                                  if (n is Map) {
                                    final isRead = n['isRead'];
                                    if (isRead != true &&
                                        isRead.toString() != 'true') {
                                      hasUnread = true;
                                      break;
                                    }
                                  }
                                }
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CustomerNotificationsScreen(),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),

                                  if (hasUnread)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Colombo 03, Sri Lanka',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CustomerSearchResultsScreen(
                                  searchQuery: 'Services',
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Search for services or pros...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Filter Chips
                        SizedBox(
                          height: 36,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildFilterChip(
                                'Top Rated',
                                Icons.star_outline,
                                _selectedFilter == 'Top Rated',
                              ),
                              const SizedBox(width: 12),
                              _buildFilterChip(
                                'Nearby',
                                Icons.location_on_outlined,
                                _selectedFilter == 'Nearby',
                              ),
                              const SizedBox(width: 12),
                              _buildFilterChip(
                                'Available Now',
                                Icons.schedule,
                                _selectedFilter == 'Available Now',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Active Service Card (from RTDB)
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _activeServiceStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  'Failed to load bookings: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final bookings = snapshot.data!;

                            return Column(
                              children: bookings.map((booking) {
                                final invoice = booking['invoice'] is Map
                                    ? booking['invoice'] as Map
                                    : null;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 24,
                                    right: 24,
                                    bottom: 20,
                                  ),
                                  child: _buildActiveServiceCardFromRtdb(
                                    booking,
                                    invoice,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        // Browse Services
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Browse Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            scrollDirection: Axis.horizontal,
                            itemCount: _serviceCategories.length,
                            itemBuilder: (context, index) {
                              final category = _serviceCategories[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CustomerServiceCategoryScreen(
                                            categoryName: category['name'],
                                            categoryIcon: category['icon'],
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        category['icon'],
                                        color: category['color'],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        category['name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Conditional display based on Stream
                        StreamBuilder<DatabaseEvent>(
                          stream: _workersStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final snap = snapshot.data?.snapshot;
                            final allWorkers = snap == null
                                ? <Map<String, dynamic>>[]
                                : _mapWorkersFromSnapshot(snap);

                            // Apply Filtering and Sorting
                            var filteredWorkers =
                                List<Map<String, dynamic>>.from(allWorkers);

                            if (_selectedFilter == 'Top Rated') {
                              filteredWorkers.sort(
                                (a, b) => (b['rating'] as num).compareTo(
                                  a['rating'] as num,
                                ),
                              );
                            } else if (_selectedFilter == 'Nearby') {
                              final target = _customerDistrict.toLowerCase();
                              filteredWorkers = filteredWorkers.where((w) {
                                final d = (w['district'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return target.isNotEmpty && d.isNotEmpty && d == target;
                              }).toList();
                            } else if (_selectedFilter == 'Available Now') {
                              filteredWorkers = filteredWorkers
                                  .where((w) => w['isAvailable'] == true)
                                  .toList();
                            }

                            if (_selectedFilter == 'Nearby') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4A7FFF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Nearby Workers',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: filteredWorkers.isEmpty
                                        ? Text(
                                            _customerDistrict.isEmpty
                                                ? 'Select your district to see nearby workers.'
                                                : 'No workers found in your district.',
                                            style: const TextStyle(
                                              color: Color(0xFF6B7280),
                                            ),
                                          )
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.65,
                                            ),
                                            itemCount: filteredWorkers.length,
                                            itemBuilder: (context, index) {
                                              final worker =
                                                  filteredWorkers[index];
                                              return _buildWorkerGridCard(
                                                worker,
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              );
                            } else if (_selectedFilter == 'Available Now') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Available Workers',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.65,
                                          ),
                                      itemCount: filteredWorkers.length,
                                      itemBuilder: (context, index) {
                                        final worker = filteredWorkers[index];
                                        return _buildWorkerGridCard(worker);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Top Rated or default
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFBBF24),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Top Rated Pros',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 165,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: filteredWorkers.length,
                                      itemBuilder: (context, index) {
                                        final worker = filteredWorkers[index];
                                        return _buildTopRatedProCard(worker);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isInvoice = status == 'invoice_sent';

    Color bgColor = const Color(0xFF3B82F6);
    if (isInvoice) bgColor = const Color(0xFF10B981);

    String label = 'In Progress';
    if (isInvoice) label = 'Quotation Ready';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveServiceCardFromRtdb(
    Map<String, dynamic> booking,
    Map? invoiceRaw,
  ) {
    final status = (booking['status'] ?? '').toString();

    final serviceName =
        (booking['serviceName'] ?? booking['service'] ?? 'Service').toString();

    final invoice = (invoiceRaw is Map)
        ? Map<String, dynamic>.from(invoiceRaw as Map)
        : null;

    final workerName =
        (invoice?['workerName'] ??
                booking['workerName'] ??
                booking['worker'] ??
                'Worker')
            .toString();

    num? _num(dynamic v) {
      if (v is num) return v;
      return null;
    }

    final inspectionFee = _num(invoice?['inspectionFee']);
    final laborHours = _num(invoice?['laborHours']);
    final laborPrice = _num(invoice?['laborPrice']);
    final materials = _num(invoice?['materials']);
    final subtotal = _num(invoice?['subtotal']) ?? 0.0;

    // For passing to detail view
    final total = materials != null ? (subtotal) : subtotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A7FFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBadge(status),
          const SizedBox(height: 16),

          Text(
            serviceName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            workerName,
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
          const SizedBox(height: 14),

          // Show invoice snippet when invoice is present and status is invoice_sent
          if (status == 'invoice_sent' && invoice != null) ...[
            _invoiceLine('Subtotal', subtotal),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _invoiceLine('Inspection', inspectionFee)),
                const SizedBox(width: 12),
                Expanded(child: _invoiceLine('Materials', materials)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _invoiceLine('Labor hours', laborHours)),
                const SizedBox(width: 12),
                Expanded(child: _invoiceLine('Labor price', laborPrice)),
              ],
            ),
            const SizedBox(height: 14),
          ],

          if (status == 'invoice_sent')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerViewQuotationScreen(
                      bookingId: (booking['id'] ?? booking['bookingId'] ?? '')
                          .toString(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('View Quotation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4A7FFF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            )
          else if (status == 'started')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerStaticViewQuotationScreen(
                                workerName: workerName,
                                serviceName: serviceName,
                                inspectionFee: (inspectionFee ?? 0).toDouble(),
                                laborPrice: (laborPrice ?? 0).toDouble(),
                                laborHours: (laborHours ?? 0).toDouble(),
                                materials: (materials ?? 0).toDouble(),
                                total: (total).toDouble(),
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('View Quotation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A7FFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerJobCompletionScreen(
                            booking: booking,
                            invoice: invoice ?? {},
                            total: (total).toDouble(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Job Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final workerId = (booking['workerId'] ?? '').toString();
                      final workerName = (booking['workerName'] ?? 'Worker')
                          .toString();
                      final myUid = FirebaseAuth.instance.currentUser?.uid;

                      if (workerId.isNotEmpty && myUid != null) {
                        final chat = ChatService();
                        final customerName =
                            widget.customerName; // Pass customer name

                        final threadId = await chat.createOrGetThread(
                          otherUid: workerId,
                          otherName: workerName,
                          otherRole: 'worker',
                          myRole: 'customer',
                          myName: customerName,
                        );

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerChatConversationScreen(
                                  threadId: threadId,
                                  otherUid: workerId,
                                  otherName: workerName,
                                ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A7FFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerLiveTrackingScreen(booking: booking),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Track'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _invoiceLine(String label, num? value) {
    final text = value == null ? '-' : value.toStringAsFixed(0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _buildTopRatedProCard(Map<String, dynamic> worker) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CustomerWorkerProfileDetailScreen(worker: worker),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person, color: Color(0xFF4A7FFF)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    worker['name'].toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (worker['status'] == 'approved' ||
                    worker['status'] == 'verified') ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 12,
                    color: Color(0xFF4A7FFF),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 12, color: Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                Text(
                  (worker['rating'] as num).toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            IconButton(
              onPressed: () {
                final workerId = worker['uid'] ?? worker['id'];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerChatConversationScreen(
                      threadId: 'mock_$workerId',
                      otherUid: workerId.toString(),
                      otherName: worker['name'] ?? 'Worker',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Color(0xFF10B981),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerGridCard(Map<String, dynamic> worker) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CustomerWorkerProfileDetailScreen(worker: worker),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF4A7FFF),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    worker['name'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (worker['status'] == 'approved' ||
                    worker['status'] == 'verified') ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 14,
                    color: Color(0xFF4A7FFF),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              worker['type'].toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                Text(
                  worker['rating'].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final workerId = worker['uid'] ?? worker['id'];
                  final workerName = worker['name'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerChatConversationScreen(
                        threadId: 'mock_$workerId',
                        otherUid: workerId.toString(),
                        otherName: workerName?.toString() ?? 'Worker',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 14),
                label: const Text('Message', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A7FFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A7FFF)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

