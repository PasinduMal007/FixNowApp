import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:intl/intl.dart';

class WorkerReviewsScreen extends StatefulWidget {
  const WorkerReviewsScreen({super.key});

  @override
  State<WorkerReviewsScreen> createState() => _WorkerReviewsScreenState();
}

class _WorkerReviewsScreenState extends State<WorkerReviewsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = DB.instance.ref();

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  void _fetchReviews() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to reviews for this worker
    _db.child('reviews/${user.uid}').onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      final List<Map<String, dynamic>> loadedReviews = [];

      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            loadedReviews.add({
              'id': key,
              'customerName': value['customerName'] ?? 'Anonymous',
              'rating': (value['rating'] ?? 0).toDouble(),
              'date': _formatDate(value['timestamp']),
              'service': value['service'] ?? 'Service',
              'comment': value['comment'] ?? '',
              'response': value['response'],
              'timestamp': value['timestamp'] ?? 0,
            });
          }
        });

        // Sort by date (newest first)
        loadedReviews.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
        );
      }

      setState(() {
        _reviews = loadedReviews;
        _calculateStats();
        _isLoading = false;
      });
    });
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y').format(date);
      }
    }
    return '';
  }

  void _calculateStats() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    double totalRating = 0;
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var review in _reviews) {
      totalRating += review['rating'];
      int star = review['rating'].floor();
      if (star >= 1 && star <= 5) {
        distribution[star] = (distribution[star] ?? 0) + 1;
      }
    }

    _averageRating = totalRating / _reviews.length;
    _ratingDistribution = distribution;
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
                child: Row(
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
                    const Expanded(
                      child: Text(
                        'Reviews & Ratings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Rating Summary Card
                            Container(
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
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Average Rating
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              _averageRating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(5, (
                                                index,
                                              ) {
                                                return Icon(
                                                  index < _averageRating.floor()
                                                      ? Icons.star
                                                      : (index < _averageRating
                                                            ? Icons.star_half
                                                            : Icons
                                                                  .star_border),
                                                  color: const Color(
                                                    0xFFFBBF24,
                                                  ),
                                                  size: 18,
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${_reviews.length} reviews',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Rating Breakdown
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [5, 4, 3, 2, 1].map((
                                            stars,
                                          ) {
                                            final count =
                                                _ratingDistribution[stars] ?? 0;
                                            final percentage = _reviews.isEmpty
                                                ? 0.0
                                                : (count / _reviews.length);
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '$stars',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Color(0xFFFBBF24),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      child: LinearProgressIndicator(
                                                        value: percentage,
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFE5E7EB,
                                                            ),
                                                        valueColor:
                                                            const AlwaysStoppedAnimation(
                                                              Color(0xFFFBBF24),
                                                            ),
                                                        minHeight: 8,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 30,
                                                    child: Text(
                                                      '$count',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Reviews List Header
                            const Text(
                              'Customer Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Reviews List
                            _reviews.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text(
                                        'No reviews yet',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _reviews
                                        .map(
                                          (review) => _buildReviewCard(review),
                                        )
                                        .toList(),
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

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Color(0xFF4A7FFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['customerName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['date'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              // Rating Stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review['rating'].floor()
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color(0xFFFBBF24),
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Service Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review['service'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A7FFF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Review Comment
          Text(
            review['comment'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          // Response
          if (review['response'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: Color(0xFF4A7FFF)),
                      SizedBox(width: 6),
                      Text(
                        'Your Response',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A7FFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['response'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _showResponseDialog(review);
              },
              icon: const Icon(Icons.reply, size: 18),
              label: const Text('Respond to review'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A7FFF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResponseDialog(Map<String, dynamic> review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  review['response'] = controller.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response posted successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7FFF),
            ),
            child: const Text('Post Response'),
          ),
        ],
      ),
    );
  }
}
