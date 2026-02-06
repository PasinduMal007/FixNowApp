import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'customer_request_quote_screen.dart';
import 'customer_worker_profile_detail_screen.dart';

class CustomerFavoriteWorkersScreen extends StatefulWidget {
  const CustomerFavoriteWorkersScreen({super.key});

  @override
  State<CustomerFavoriteWorkersScreen> createState() => _CustomerFavoriteWorkersScreenState();
}

class _CustomerFavoriteWorkersScreenState extends State<CustomerFavoriteWorkersScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = DB.instance;

  String _selectedFilter = 'All';

  String? get _uid => _auth.currentUser?.uid;

  Stream<DatabaseEvent> _favoritesStream() {
    final uid = _uid;
    if (uid == null) return const Stream<DatabaseEvent>.empty();
    return _db.ref('users/customers/$uid').onValue;
  }

  List<String> _extractFavoriteIds(dynamic userValue) {
    if (userValue is! Map) return [];
    final data = Map<String, dynamic>.from(userValue as Map);
    final favRaw =
        (data['favoriteWorkers'] ?? data['favorites'] ?? data['favourites']);
    if (favRaw is! Map) return [];
    final favMap = Map<String, dynamic>.from(favRaw as Map);
    return favMap.entries
        .where((e) => e.value != null)
        .map((e) => e.key.toString())
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchWorkers(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) async {
      final snap = await _db.ref('workersPublic/$id').get();
      if (!snap.exists || snap.value is! Map) return null;
      final m = Map<String, dynamic>.from(snap.value as Map);
      return {
        'uid': id,
        'name': (m['fullName'] ?? 'Worker').toString(),
        'type': (m['profession'] ?? 'Service').toString(),
        'rating': (m['rating'] is num) ? m['rating'] : 0,
        'reviews': (m['reviews'] is num) ? m['reviews'] : 0,
        'experience': (m['experience'] ?? '').toString(),
        'aboutMe': (m['aboutMe'] ?? '').toString(),
        'photoUrl': m['photoUrl']?.toString(),
        'isAvailable': m['isAvailable'] == true,
      };
    }).toList();

    final results = await Future.wait(futures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> workers) {
    if (_selectedFilter == 'All') return workers;
    final needle = _selectedFilter.toLowerCase();
    return workers.where((w) {
      final type = (w['type'] ?? '').toString().toLowerCase();
      return type.contains(needle);
    }).toList();
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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Favorite Workers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DatabaseEvent>(
                      stream: _favoritesStream(),
                      builder: (context, snap) {
                        final ids = _extractFavoriteIds(
                          snap.data?.snapshot.value,
                        );
                        return Text(
                          '${ids.length} saved professionals',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Electrical'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Plumbing'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Carpentry'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
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
                    stream: _favoritesStream(),
                    builder: (context, snap) {
                      if (_uid == null) {
                        return const Center(child: Text('Please sign in'));
                      }

                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load favorites: ${snap.error}',
                          ),
                        );
                      }

                      final ids = _extractFavoriteIds(
                        snap.data?.snapshot.value,
                      );

                      if (ids.isEmpty) {
                        return _buildEmptyState();
                      }

                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchWorkers(ids),
                        builder: (context, workersSnap) {
                          if (!workersSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final workers =
                              _applyFilter(workersSnap.data ?? []);
                          if (workers.isEmpty) return _buildEmptyState();

                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: workers.length,
                            itemBuilder: (context, index) {
                              return _buildWorkerCard(workers[index]);
                            },
                          );
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
            builder: (context) => CustomerWorkerProfileDetailScreen(worker: worker),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF4A7FFF), size: 28),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker['name'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                            iconSize: 20,
                            onPressed: () async {
                              final uid = _uid;
                              if (uid == null) return;
                              final workerId =
                                  (worker['uid'] ?? worker['id']).toString();
                              await _db
                                  .ref(
                                    'users/customers/$uid/favoriteWorkers/$workerId',
                                  )
                                  .remove();
                              await _db
                                  .ref('users/customers/$uid/favorites/$workerId')
                                  .remove();
                              await _db
                                  .ref(
                                    'users/customers/$uid/favourites/$workerId',
                                  )
                                  .remove();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Removed from favorites')),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        (worker['type'] ?? 'Service').toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            '${worker['rating'] ?? 0} (${worker['reviews'] ?? 0})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (worker['isAvailable'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
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
            if ((worker['aboutMe'] ?? '').toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (worker['aboutMe'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    worker['experience'] != null &&
                            worker['experience'].toString().isNotEmpty
                        ? 'Experience: ${worker['experience']}'
                        : 'Rate: negotiable',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerRequestQuoteScreen(
                          worker: worker,
                          categoryName: (worker['type'] ?? 'Service').toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7FFF),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Quick Book',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Favorite Workers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add workers to your favorites for quick access',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
