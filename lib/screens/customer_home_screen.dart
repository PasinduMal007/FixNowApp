import 'package:flutter/material.dart';
import 'dart:async';
import 'customer_notifications_screen.dart';
import 'customer_search_results_screen.dart';
import 'customer_service_category_screen.dart';
import 'customer_live_tracking_screen.dart';
import 'customer_chat_conversation_screen.dart';
import 'customer_view_quotation_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final String customerName;

  const CustomerHomeScreen({super.key, this.customerName = 'Sarah'});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final List<Map<String, dynamic>> _serviceCategories = [
    {'name': 'Electrician', 'icon': Icons.flash_on, 'color': Color(0xFFFBBF24)},
    {
      'name': 'Plumber',
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF3B82F6),
    },
    {
      'name': 'Carpenter',
      'icon': Icons.handyman_outlined,
      'color': Color(0xFF8B4513),
    },
    {
      'name': 'Mason',
      'icon': Icons.home_repair_service,
      'color': Color(0xFF6B7280),
    },
    {
      'name': 'Painter',
      'icon': Icons.format_paint_outlined,
      'color': Color(0xFFF97316),
    },
    {
      'name': 'Mechanic',
      'icon': Icons.build_circle_outlined,
      'color': Color(0xFF1F2937),
    },
    {
      'name': 'Welder',
      'icon': Icons.whatshot_outlined,
      'color': Color(0xFFEF4444),
    },
    {
      'name': 'AC Technician',
      'icon': Icons.ac_unit_outlined,
      'color': Color(0xFF06B6D4),
    },
    {
      'name': 'Tile Setter',
      'icon': Icons.grid_on_outlined,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Roofer',
      'icon': Icons.roofing_outlined,
      'color': Color(0xFF78716C),
    },
    {
      'name': 'Gardener',
      'icon': Icons.yard_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'name': 'Cleaner',
      'icon': Icons.cleaning_services_outlined,
      'color': Color(0xFF06B6D4),
    },
  ];

  final Map<String, dynamic>? _activeService = {
    'service': 'Electrical Repair',
    'worker': 'Kasun Perera',
    'workerRating': 4.8,
    'arrivingIn': '15 min',
    'distance': '1.3 km away',
    'status': 'invoice_sent', // Changed to test quotation button
    'id': 'test123',
    'invoice': {
      'workerName': 'Kasun Perera',
      'inspectionFee': 500,
      'laborHours': 2,
      'laborPrice': 2000,
      'materials': 1000,
      'subtotal': 3500,
      'notes': 'Price may vary based on actual materials needed',
    },
  };

  String _selectedFilter = 'Top Rated';

  // Real-time update variables
  Timer? _updateTimer;
  int _arrivingMinutes = 15;
  double _distanceKm = 1.3;

  @override
  void initState() {
    super.initState();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
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

                        GestureDetector(
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

                        // Active Service Card (if exists)
                        if (_activeService != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF4A7FFF),
                                    Color(0xFF6B9FFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4A7FFF,
                                    ).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
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
                                            const Text(
                                              'In Progress',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activeService['service'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _activeService['worker'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Show different buttons based on status
                                  if (_activeService['status'] ==
                                      'invoice_sent')
                                    // Show View Quotation button
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CustomerViewQuotationScreen(
                                                  booking: _activeService,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.receipt_long,
                                        size: 18,
                                      ),
                                      label: const Text('View Quotation'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF4A7FFF,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              // Navigate to chat with specific worker
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CustomerChatConversationScreen(
                                                        threadId: '',
                                                        otherUid: '',
                                                        otherName: '',
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.chat_bubble_outline,
                                              size: 18,
                                            ),
                                            label: const Text('Message'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(
                                                0xFF4A7FFF,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                      CustomerLiveTrackingScreen(
                                                        booking: _activeService,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.location_on,
                                              size: 18,
                                            ),
                                            label: const Text('Track'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white
                                                  .withOpacity(0.2),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

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

                        // Top Rated Pros
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
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
                              TextButton(
                                onPressed: () {},
                                child: const Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF4A7FFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Color(0xFF4A7FFF),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Top Rated Pros List (Placeholder)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE8F0FF),
                                            Color(0xFFD0E2FF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF4A7FFF),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Pro Name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Color(0xFFFBBF24),
                                        ),
                                        const SizedBox(width: 2),
                                        const Text(
                                          '4.9',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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