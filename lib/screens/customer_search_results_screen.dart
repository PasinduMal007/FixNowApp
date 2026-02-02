import 'package:flutter/material.dart';
import 'customer_worker_profile_detail_screen.dart';
import 'customer_service_category_screen.dart';

class CustomerSearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const CustomerSearchResultsScreen({super.key, required this.searchQuery});

  @override
  State<CustomerSearchResultsScreen> createState() =>
      _CustomerSearchResultsScreenState();
}

class _CustomerSearchResultsScreenState
    extends State<CustomerSearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredResults = [];

  // Comprehensive worker database
  final List<Map<String, dynamic>> _allWorkers = [
    // Nearby Workers
    {
      'type': 'worker',
      'id': 1,
      'name': 'Kasun Perera',
      'workerType': 'Expert Electrician',
      'profession': 'Electrician',
      'rating': 4.8,
      'reviews': 420,
      'hourlyRate': 2500,
      'distance': 1.2,
      'experience': 8,
      'description': 'Specialized in residential and commercial wiring',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 2,
      'name': 'Nimal Silva',
      'workerType': 'Master Plumber',
      'profession': 'Plumber',
      'rating': 4.6,
      'reviews': 350,
      'hourlyRate': 2200,
      'distance': 2.4,
      'experience': 7,
      'description': 'Expert in pipe installations and repairs',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 3,
      'name': 'Amal Fernando',
      'workerType': 'Professional Carpenter',
      'profession': 'Carpenter',
      'rating': 4.9,
      'reviews': 480,
      'hourlyRate': 2800,
      'distance': 1.8,
      'experience': 10,
      'description': 'Furniture making and woodwork specialist',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 4,
      'name': 'Sunil Dias',
      'workerType': 'Senior Electrician',
      'profession': 'Electrician',
      'rating': 4.7,
      'reviews': 390,
      'hourlyRate': 2400,
      'distance': 2.1,
      'experience': 9,
      'description': 'Electrical installations and maintenance',
      'isAvailable': false,
    },
    {
      'type': 'worker',
      'id': 5,
      'name': 'Chamara Wickrama',
      'workerType': 'Expert Mason',
      'profession': 'Mason',
      'rating': 4.5,
      'reviews': 310,
      'hourlyRate': 2100,
      'distance': 3.0,
      'experience': 6,
      'description': 'Building and construction masonry',
      'isAvailable': true,
    },
    // Available Workers
    {
      'type': 'worker',
      'id': 6,
      'name': 'Ravi Kumara',
      'workerType': 'Professional Electrician',
      'profession': 'Electrician',
      'rating': 4.9,
      'reviews': 510,
      'hourlyRate': 2600,
      'distance': 1.5,
      'experience': 11,
      'description': 'Advanced electrical systems installation',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 7,
      'name': 'Saman Jayasinghe',
      'workerType': 'Expert Plumber',
      'profession': 'Plumber',
      'rating': 4.7,
      'reviews': 400,
      'hourlyRate': 2300,
      'distance': 2.0,
      'experience': 8,
      'description': 'Plumbing repairs and installations',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 8,
      'name': 'Tharindu Bandara',
      'workerType': 'Master Carpenter',
      'profession': 'Carpenter',
      'rating': 4.8,
      'reviews': 440,
      'hourlyRate': 2700,
      'distance': 1.9,
      'experience': 9,
      'description': 'Custom furniture and woodwork',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 9,
      'name': 'Indunil Perera',
      'workerType': 'Professional Painter',
      'profession': 'Painter',
      'rating': 4.6,
      'reviews': 360,
      'hourlyRate': 2000,
      'distance': 2.3,
      'experience': 7,
      'description': 'Interior and exterior painting',
      'isAvailable': true,
    },
    {
      'type': 'worker',
      'id': 10,
      'name': 'Lakmal Rodrigo',
      'workerType': 'Expert Mason',
      'profession': 'Mason',
      'rating': 4.5,
      'reviews': 330,
      'hourlyRate': 2200,
      'distance': 2.7,
      'experience': 6,
      'description': 'Concrete and brickwork specialist',
      'isAvailable': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _performSearch(widget.searchQuery);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredResults = _allWorkers;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredResults = _allWorkers.where((worker) {
        final name = worker['name'].toString().toLowerCase();
        final profession = worker['profession'].toString().toLowerCase();
        final workerType = worker['workerType'].toString().toLowerCase();

        return name.contains(lowerQuery) ||
            profession.contains(lowerQuery) ||
            workerType.contains(lowerQuery);
      }).toList();
    });
  }

  List<Map<String, dynamic>> _getDisplayResults() {
    return _filteredResults;
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
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
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
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _performSearch,
                                    autofocus: true,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1F2937),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Search for services or pros...',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_getDisplayResults().length} results found',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Results
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _getDisplayResults().length,
                    itemBuilder: (context, index) {
                      final result = _getDisplayResults()[index];
                      if (result['type'] == 'service') {
                        return _buildServiceCard(result);
                      } else {
                        return _buildWorkerCard(result);
                      }
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

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerServiceCategoryScreen(
              categoryName: service['category'],
              categoryIcon: service['icon'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service['icon'],
                color: const Color(0xFF4A7FFF),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERVICE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A7FFF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['name'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service['providersCount']} professionals available',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF), size: 20),
          ],
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WORKER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF4A7FFF),
                    size: 28,
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
                              worker['name'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (worker['isAvailable'])
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
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
                      const SizedBox(height: 2),
                      Text(
                        worker['profession'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${worker['rating']} (${worker['reviews']})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
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
