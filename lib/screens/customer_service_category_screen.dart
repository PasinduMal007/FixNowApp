import 'package:fix_now_app/screens/customer_request_quote_screen.dart';
import 'package:flutter/material.dart';
import 'customer_worker_profile_detail_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

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

  Stream<DatabaseEvent> get _workersStream =>
      DB.ref().child('workersPublic').onValue;

  // ✅ Robust: use snapshot.children, not snapshot.value
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
      final hourlyVal = data['hourlyRate'];

      final rating = (ratingVal is num)
          ? ratingVal.toDouble()
          : double.tryParse(ratingVal?.toString() ?? '') ?? 0.0;

      final reviews = (reviewsVal is num)
          ? reviewsVal.toInt()
          : int.tryParse(reviewsVal?.toString() ?? '') ?? 0;

      final hourlyRate = (hourlyVal is num)
          ? hourlyVal.toInt()
          : int.tryParse(hourlyVal?.toString() ?? '') ?? 2500;

      final isAvailableVal = data['isAvailable'];
      final isAvailable = isAvailableVal is bool ? isAvailableVal : false;

      list.add(<String, dynamic>{
        'uid': (data['uid'] ?? key).toString(),
        'name': fullName.isEmpty ? 'Worker' : fullName,
        'type': profession.isEmpty ? widget.categoryName : profession,
        'rating': rating,
        'reviews': reviews,
        'hourlyRate': hourlyRate,

        // If you later store these in workersPublic, map them here
        'distance': (data['distance'] is num)
            ? (data['distance'] as num).toDouble()
            : 0.0,
        'experience': (data['experience'] ?? 0),
        'description': (data['description'] ?? '').toString(),

        'isAvailable': isAvailable,
        'photoUrl': (data['photoUrl'] ?? '').toString(),
        'locationText': (data['locationText'] ?? '').toString(),
      });
    }

    return list;
  }

  List<Map<String, dynamic>> _applyFilterSort(List<Map<String, dynamic>> list) {
    var out = List<Map<String, dynamic>>.from(list);

    switch (_selectedFilter) {
      case 'Top Rated':
        out.sort(
          (a, b) => (b['rating'] as num).compareTo((a['rating'] as num)),
        );
        out = out.take(20).toList();
        break;
      case 'Nearby':
        // only works if distance is stored
        out.sort(
          (a, b) => (a['distance'] as num).compareTo((b['distance'] as num)),
        );
        break;
      case 'Available Now':
        out = out.where((w) => w['isAvailable'] == true).toList();
        break;
      case 'All':
      default:
        break;
    }

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
                  child: Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: _workersStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            final snap = snapshot.data?.snapshot;
                            if (snap == null) {
                              return const Center(
                                child: Text('No workers found'),
                              );
                            }

                            final workers = _applyFilterSort(
                              _mapWorkersFromSnapshot(snap),
                            );

                            if (workers.isEmpty) {
                              return const Center(
                                child: Text('No workers found'),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: workers.length,
                              itemBuilder: (context, index) {
                                return _buildWorkerCard(workers[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ],
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
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF4A7FFF),
                    size: 32,
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
            Text(
              (worker['description'] ?? '').toString(),
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
                Text(
                  '${worker['distance']} km away',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
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
