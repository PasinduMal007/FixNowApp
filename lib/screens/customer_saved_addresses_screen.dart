import 'package:flutter/material.dart';

class CustomerSavedAddressesScreen extends StatefulWidget {
  const CustomerSavedAddressesScreen({super.key});

  @override
  State<CustomerSavedAddressesScreen> createState() => _CustomerSavedAddressesScreenState();
}

class _CustomerSavedAddressesScreenState extends State<CustomerSavedAddressesScreen> {
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': 1,
      'label': 'Home',
      'address': '1234 Main Street, Colombo 03',
      'icon': Icons.home,
      'isDefault': true,
    },
    {
      'id': 2,
      'label': 'Work',
      'address': '567 Office Plaza, Colombo 07',
      'icon': Icons.work,
      'isDefault': false,
    },
    {
      'id': 3,
      'label': 'Other',
      'address': '89 Park Avenue, Colombo 05',
      'icon': Icons.location_on,
      'isDefault': false,
    },
  ];

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
                        'Saved Addresses',
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
                      // Addresses List
                      ..._addresses.map((address) => _buildAddressCard(address)),
                      
                      const SizedBox(height: 12),
                      
                      // Add Address Button
                      GestureDetector(
                        onTap: () => _showAddAddressDialog(),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4A7FFF),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFF4A7FFF),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add New Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A7FFF),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              address['icon'],
              color: const Color(0xFF4A7FFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address['label'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (address['isDefault']) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address['address'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Set as Default'),
                onTap: () {
                  setState(() {
                    for (var addr in _addresses) {
                      addr['isDefault'] = addr['id'] == address['id'];
                    }
                  });
                },
              ),
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () => _showAddAddressDialog(address: address),
              ),
              PopupMenuItem(
                child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () {
                  setState(() => _addresses.remove(address));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog({Map<String, dynamic>? address}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(address == null ? 'Add New Address' : 'Edit Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Home, Work, etc.',
              ),
              controller: TextEditingController(text: address?['label']),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Street, City, Postal Code',
              ),
              controller: TextEditingController(text: address?['address']),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(address == null ? 'Address added!' : 'Address updated!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: Text(address == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
