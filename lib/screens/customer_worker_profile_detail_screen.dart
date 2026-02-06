import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:fix_now_app/Services/chat_service.dart';
import 'customer_request_quote_screen.dart';
import 'customer_chat_conversation_screen.dart';

class CustomerWorkerProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> worker;

  const CustomerWorkerProfileDetailScreen({super.key, required this.worker});

  @override
  State<CustomerWorkerProfileDetailScreen> createState() =>
      _CustomerWorkerProfileDetailScreenState();
}

class _CustomerWorkerProfileDetailScreenState
    extends State<CustomerWorkerProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;
  final _db = DB.instance;

  final List<Map<String, dynamic>> _reviews = [
    {
      'customerName': 'Sarah Johnson',
      'rating': 5.0,
      'date': 'Dec 20, 2024',
      'comment': 'Excellent work! Very professional and punctual.',
    },
    {
      'customerName': 'Michael Brown',
      'rating': 4.8,
      'date': 'Dec 15, 2024',
      'comment': 'Great service, highly recommend!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final workerId = (widget.worker['uid'] ?? widget.worker['id'])
        .toString()
        .trim();
    final uid = _auth.currentUser?.uid;
    final favRef = (uid != null && workerId.isNotEmpty)
        ? _db.ref('users/customers/$uid/favoriteWorkers/$workerId')
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF4A7FFF),
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
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
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: favRef == null
                        ? IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in'),
                                ),
                              );
                            },
                          )
                        : StreamBuilder<DatabaseEvent>(
                            stream: favRef.onValue,
                            builder: (context, snap) {
                              final isFav =
                                  snap.data?.snapshot.value != null;
                              return IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  if (isFav) {
                                    await favRef.remove();
                                  } else {
                                    await favRef.set(true);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8F0FF), Color(0xFFFFFFFF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF4A7FFF),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.worker['name'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (widget.worker['status'] == 'approved' ||
                                  widget.worker['status'] == 'verified') ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.verified,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.worker['type'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 18,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.worker['rating']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.worker['reviews']} reviews)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF4A7FFF),
                    unselectedLabelColor: const Color(0xFF9CA3AF),
                    indicatorColor: const Color(0xFF4A7FFF),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),

              // Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildAboutTab(), _buildReviewsTab()],
                ),
              ),
            ],
          ),

          // Floating Book Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerRequestQuoteScreen(
                            worker: widget.worker,
                            categoryName: widget.worker['type'] ?? 'Service',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7FFF),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Book Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final workerId =
                          (widget.worker['uid'] ?? widget.worker['id'])
                              .toString()
                              .trim();
                      final workerName =
                          (widget.worker['name'] ?? 'Worker').toString().trim();
                      final myUid = _auth.currentUser?.uid;
                      if (workerId.isEmpty || myUid == null) return;

                      final chat = ChatService();
                      chat
                          .createOrGetThread(
                            otherUid: workerId,
                            otherName: workerName,
                            otherRole: 'worker',
                            myRole: 'customer',
                            myName: 'Customer',
                          )
                          .then((threadId) {
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
                          });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Experience',
                  '${widget.worker['experience'] ?? 0} years',
                  Icons.work_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Jobs',
                  '${widget.worker['reviews']}+',
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About Section
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              (widget.worker['aboutMe'] ?? widget.worker['description'] ?? '')
                      .toString()
                      .isNotEmpty
                  ? (widget.worker['aboutMe'] ?? widget.worker['description'])
                        .toString()
                  : 'Specializing in residential and commercial electrical work with over ${widget.worker['experience'] ?? "0"} years of experience. Licensed and insured professional committed to quality service and customer satisfaction.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF4A7FFF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['customerName'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review['rating']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review['comment'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A7FFF)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF8FAFC), child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
