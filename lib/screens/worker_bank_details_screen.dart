import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class WorkerBankDetailsScreen extends StatefulWidget {
  const WorkerBankDetailsScreen({super.key});

  @override
  State<WorkerBankDetailsScreen> createState() =>
      _WorkerBankDetailsScreenState();
}

class _WorkerBankDetailsScreenState extends State<WorkerBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _holderNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accountNumberController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchBankDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await DB.ref().child('users/workers/$uid/bankDetails').get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        _bankNameController.text = data['bankName'] ?? '';
        _branchNameController.text = data['branchName'] ?? '';
        _accountNumberController.text = data['accountNumber'] ?? '';
        _holderNameController.text = data['holderName'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching bank details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      await DB.ref().child('users/workers/$uid/bankDetails').set({
        'bankName': _bankNameController.text.trim(),
        'branchName': _branchNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'holderName': _holderNameController.text.trim(),
        'updatedAt': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bank Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These details will be used for transferring your earnings.',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField('Bank Name', _bankNameController),
                    const SizedBox(height: 16),
                    _buildTextField('Branch Name', _branchNameController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Account Number',
                      _accountNumberController,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Account Holder Name',
                      _holderNameController,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBankDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7FFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A7FFF)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
