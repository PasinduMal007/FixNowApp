import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/Services/db.dart';

class CustomerSavedAddressesScreen extends StatefulWidget {
  const CustomerSavedAddressesScreen({super.key});

  @override
  State<CustomerSavedAddressesScreen> createState() => _CustomerSavedAddressesScreenState();
}

class _CustomerSavedAddressesScreenState extends State<CustomerSavedAddressesScreen> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  DatabaseReference _customerRef() {
    return DB.instance.ref('users/customers/$_uid');
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) return Icons.home;
    if (l.contains('work') || l.contains('office')) return Icons.work;
    return Icons.location_on;
  }

  DatabaseReference _addressesRef() {
    return DB.instance.ref('users/customers/$_uid/addresses');
  }

  Future<void> _setDefault(String id) async {
    final snap = await _addressesRef().get();
    if (!snap.exists || snap.value is! Map) return;

    final raw = Map<dynamic, dynamic>.from(snap.value as Map);
    final updates = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      updates['$key/isDefault'] = key == id;
    }
    await _addressesRef().update(updates);
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
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _uid.isEmpty ? null : _customerRef().onValue,
                    builder: (context, snapshot) {
                      final raw = snapshot.data?.snapshot.value;
                      final list = <Map<String, dynamic>>[];
                      String currentLocation = '';

                      if (raw is Map) {
                        final map = Map<dynamic, dynamic>.from(raw);
                        currentLocation =
                            (map['locationText'] ?? '').toString().trim();

                        final rawAddresses = map['addresses'];
                        if (rawAddresses is Map) {
                          final addrMap =
                              Map<dynamic, dynamic>.from(rawAddresses);
                          for (final entry in addrMap.entries) {
                            if (entry.value is Map) {
                              final data = Map<String, dynamic>.from(
                                entry.value as Map,
                              );
                              data['id'] = entry.key.toString();
                              list.add(data);
                            }
                          }
                          list.sort((a, b) {
                            final aDef = a['isDefault'] == true;
                            final bDef = b['isDefault'] == true;
                            if (aDef != bDef) return aDef ? -1 : 1;
                            return (a['label'] ?? '')
                                .toString()
                                .compareTo((b['label'] ?? '').toString());
                          });
                        }
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (currentLocation.isNotEmpty)
                            Container(
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
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Color(0xFF4A7FFF),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Current Location',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          currentLocation,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Addresses List
                          ...list.map((address) => _buildAddressCard(address)),

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
              _iconForLabel((address['label'] ?? '').toString()),
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
            onSelected: (value) async {
              if (value == 'default') {
                await _setDefault(address['id'].toString());
              } else if (value == 'edit') {
                _showAddAddressDialog(address: address);
              } else if (value == 'delete') {
                await _addressesRef().child(address['id'].toString()).remove();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog({Map<String, dynamic>? address}) {
    final labelController =
        TextEditingController(text: address?['label']?.toString() ?? '');
    final addressController =
        TextEditingController(text: address?['address']?.toString() ?? '');

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
              controller: labelController,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Street, City, Postal Code',
              ),
              controller: addressController,
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
            onPressed: () async {
              final label = labelController.text.trim();
              final addr = addressController.text.trim();
              if (label.isEmpty || addr.isEmpty) return;

              final isDefault = address?['isDefault'] == true;
              final payload = {
                'label': label,
                'address': addr,
                'isDefault': isDefault,
                'updatedAt': ServerValue.timestamp,
              };

              if (address == null) {
                final ref = _addressesRef().push();
                await ref.set({
                  ...payload,
                  'createdAt': ServerValue.timestamp,
                });
              } else {
                await _addressesRef()
                    .child(address['id'].toString())
                    .update(payload);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      address == null ? 'Address added!' : 'Address updated!',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: Text(address == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
