import 'package:fix_now_app/screens/customer_request_quote_screen.dart';
import 'package:flutter/material.dart';
import 'customer_worker_profile_detail_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerServiceCategoryScreen extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;

  const CustomerServiceCategoryScreen({
    super.key,
    required this.categoryName,
    this.categoryIcon = Icons.build,
  });

  @override
  State<CustomerServiceCategoryScreen> createState() =>
      _CustomerServiceCategoryScreenState();
}

class _CustomerServiceCategoryScreenState
    extends State<CustomerServiceCategoryScreen> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Top Rated';
  String _customerDistrict = '';

  @override
  void initState() {
    super.initState();
    _loadCustomerDistrict();
  }

  Stream<DatabaseEvent> get _workersStream =>
      DB.ref().child('workersPublic').onValue;

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  bool _toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    final s = (v ?? '').toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  Future<void> _loadCustomerDistrict() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await DB.instance.ref('users/customers/$uid/district').get();
      final v = snap.value;
      if (!mounted) return;
      setState(() => _customerDistrict = (v ?? '').toString().trim());
    } catch (_) {
      // no-op
    }
  }

  Widget _statusBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  List<Map<String, dynamic>> _mapWorkersFromSnapshot(DataSnapshot snap) {
    final list = <Map<String, dynamic>>[];

    for (final child in snap.children) {
      final key = (child.key ?? '').toString();
      if (child.value is! Map) continue;

      final data = Map<String, dynamic>.from(child.value as Map);

      // rules require uid exists and equals auth.uid for writes,
      // but for reads, we still want a stable uid
      final uid = (data['uid'] ?? key).toString().trim();
      if (uid.isEmpty) continue;

      final fullName = (data['fullName'] ?? '').toString().trim();
      final profession = (data['profession'] ?? '').toString().trim();

      final locationText = (data['locationText'] ?? '').toString().trim();
      final photoUrl = (data['photoUrl'] ?? '').toString().trim();
      final aboutMe = (data['aboutMe'] ?? '').toString().trim();

      final rating = _toDouble(data['rating'], fallback: 0.0);
      final reviews = _toInt(data['reviews'], fallback: 0);
      final isAvailable = _toBool(data['isAvailable'], fallback: false);

      final experience = (data['experience'] ?? '').toString().trim();
      final district = (data['district'] ?? '').toString().trim();

      // You did not include status in workersPublic rules, so treat as optional display-only
      final status = (data['status'] ?? '').toString().trim();

      list.add(<String, dynamic>{
        'uid': uid,
        'name': fullName.isEmpty ? 'Worker' : fullName,
        'type': profession.isEmpty ? widget.categoryName : profession,

        'locationText': locationText,
        'photoUrl': photoUrl,
        'aboutMe': aboutMe,

        'rating': rating,
        'reviews': reviews,
        'isAvailable': isAvailable,

        'experienceLabel': experience,
        'status': status,
        'district': district,
      });
    }

    return list;
  }

  List<Map<String, dynamic>> _applyFilterSort(List<Map<String, dynamic>> list) {
    var out = List<Map<String, dynamic>>.from(list);

    // Only show available workers
    out = out.where((w) => w['isAvailable'] == true).toList();

    // Filter by Profession == categoryName
    out = out.where((w) {
      final type = (w['type'] ?? '').toString().toLowerCase();
      final target = widget.categoryName.toLowerCase();
      return type == target;
    }).toList();

    // Filter chips
    switch (_selectedFilter) {
      case 'Top Rated':
        out.sort(
          (a, b) => (b['rating'] as num).compareTo((a['rating'] as num)),
        );
        out = out.take(20).toList();
        break;

      case 'Nearby':
        final target = _customerDistrict.toLowerCase();
        out = out.where((w) {
          final d = (w['district'] ?? '').toString().toLowerCase();
          return target.isNotEmpty && d.isNotEmpty && d == target;
        }).toList();
        break;

      case 'Available Now':
        out = out.where((w) => w['isAvailable'] == true).toList();
        break;

      case 'All':
      default:
        break;
    }

    // Sort dropdown
    switch (_selectedSort) {
      case 'Top Rated':
        out.sort(
          (a, b) => (b['rating'] as num).compareTo((a['rating'] as num)),
        );
        break;
      default:
        break;
    }

    return out;
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.categoryName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              StreamBuilder<DatabaseEvent>(
                                stream: _workersStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    );
                                  }

                                  final snap = snapshot.data?.snapshot;
                                  final workers = (snap == null)
                                      ? <Map<String, dynamic>>[]
                                      : _applyFilterSort(
                                          _mapWorkersFromSnapshot(snap),
                                        );

                                  return Text(
                                    '${workers.length} professionals available',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.categoryIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Top Rated'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Nearby'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Available Now'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _workersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final snap = snapshot.data?.snapshot;
                      if (snap == null) {
                        return const Center(child: Text('No workers found'));
                      }

                      final workers = _applyFilterSort(
                        _mapWorkersFromSnapshot(snap),
                      );

                      if (workers.isEmpty) {
                        return const Center(child: Text('No workers found'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: workers.length,
                        itemBuilder: (context, index) {
                          return _buildWorkerCard(workers[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF4A7FFF) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        (worker['photoUrl'] ?? '').toString().trim().isNotEmpty
                        ? Image.network(
                            worker['photoUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF4A7FFF),
                              size: 32,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFF4A7FFF),
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (worker['name'] ?? 'Worker').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (worker['isAvailable'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Text(
                        (worker['type'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),

                      // Optional status badge if you store it in workersPublic
                      Builder(
                        builder: (_) {
                          final status = (worker['status'] ?? '')
                              .toString()
                              .trim();
                          if (status.isEmpty) return const SizedBox();

                          if (status == 'verified') {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _statusBadge(
                                'Verified',
                                const Color(0xFFD1FAE5),
                                const Color(0xFF059669),
                              ),
                            );
                          }

                          if (status == 'pending_verification') {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _statusBadge(
                                'Pending',
                                const Color(0xFFFEF3C7),
                                const Color(0xFF92400E),
                              ),
                            );
                          }

                          return const SizedBox();
                        },
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (worker['rating'] is num)
                                ? (worker['rating'] as num).toStringAsFixed(1)
                                : (worker['rating'] ?? '0').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${worker['reviews']} reviews)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if ((worker['aboutMe'] ?? '').toString().trim().isNotEmpty)
              Text(
                (worker['aboutMe'] ?? '').toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (worker['locationText'] ?? '').toString().trim().isNotEmpty
                        ? (worker['locationText'] ?? '').toString()
                        : 'Location not set',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  (worker['experienceLabel'] ?? '').toString().trim().isNotEmpty
                      ? (worker['experienceLabel'] ?? '').toString()
                      : '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerRequestQuoteScreen(
                          worker: worker,
                          categoryName: widget.categoryName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7FFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
