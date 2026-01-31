import 'package:flutter/material.dart';
import 'customer_service_category_screen.dart';
import 'customer_worker_profile_detail_screen.dart';
import 'customer_search_results_screen.dart';
import 'customer_chat_conversation_screen.dart';
import 'customer_notifications_screen.dart';
import 'customer_live_tracking_screen.dart';
import 'customer_review_rating_screen.dart';
import 'customer_payment_methods_screen.dart';
import 'customer_saved_addresses_screen.dart';
import 'customer_favorite_workers_screen.dart';

class CustomerFeaturesDemoScreen extends StatelessWidget {
  const CustomerFeaturesDemoScreen({super.key});

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
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Test All Features',
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
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Phase 1: Core Navigation & Discovery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDemoButton(
                        context,
                        'Service Category Detail',
                        'Browse workers by category',
                        Icons.category,
                        const Color(0xFF4A7FFF),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerServiceCategoryScreen(
                              categoryName: 'Electrical',
                              categoryIcon: Icons.flash_on,
                            ),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Worker Profile Detail',
                        'View complete worker profile',
                        Icons.person,
                        const Color(0xFF10B981),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerWorkerProfileDetailScreen(
                              worker: {
                                'id': 1,
                                'name': 'Kasun Perera',
                                'type': 'Expert Electrician',
                                'rating': 4.9,
                                'reviews': 450,
                                'hourlyRate': 2500,
                                'experience': 8,
                                'description': 'Specialized in residential and commercial wiring',
                              },
                            ),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Search Results',
                        'Mixed service & worker search',
                        Icons.search,
                        const Color(0xFFFBBF24),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerSearchResultsScreen(
                              searchQuery: 'electrical',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Phase 2: Communication & Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDemoButton(
                        context,
                        'Individual Chat',
                        'Message with worker',
                        Icons.chat_bubble,
                        const Color(0xFF4A7FFF),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerChatConversationScreen(
                               threadId: '', otherUid: '', otherName: '',
                            ),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Notifications',
                        '4 tabs with unread badges',
                        Icons.notifications,
                        const Color(0xFFEF4444),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerNotificationsScreen(),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Live Tracking',
                        'Track worker arrival',
                        Icons.location_on,
                        const Color(0xFF10B981),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerLiveTrackingScreen(
                              booking: {
                                'worker': 'Kasun Perera',
                                'workerType': 'Expert Electrician',
                                'rating': 4.9,
                                'service': 'Electrical Wiring Repair',
                                'date': 'Tomorrow at 10:00 AM',
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Phase 3: Post-Service & Management',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDemoButton(
                        context,
                        'Review & Rating',
                        '5-star rating with tags & tips',
                        Icons.star,
                        const Color(0xFFFBBF24),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerReviewRatingScreen(
                              booking: {
                                'worker': 'Kasun Perera',
                                'service': 'Electrical Wiring Repair',
                              },
                            ),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Payment Methods',
                        'Manage saved cards',
                        Icons.credit_card,
                        const Color(0xFF4A7FFF),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerPaymentMethodsScreen(),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Saved Addresses',
                        'Manage delivery locations',
                        Icons.home,
                        const Color(0xFF10B981),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerSavedAddressesScreen(),
                          ),
                        ),
                      ),
                      _buildDemoButton(
                        context,
                        'Favorite Workers',
                        'Quick book from favorites',
                        Icons.favorite,
                        const Color(0xFFEF4444),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerFavoriteWorkersScreen(),
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
      ),
    );
  }

  Widget _buildDemoButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
