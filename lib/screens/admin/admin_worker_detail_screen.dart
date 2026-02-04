import 'package:flutter/material.dart';
import 'package:fix_now_app/Services/db.dart';

class AdminWorkerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> worker;

  const AdminWorkerDetailScreen({super.key, required this.worker});

  @override
  State<AdminWorkerDetailScreen> createState() =>
      _AdminWorkerDetailScreenState();
}

class _AdminWorkerDetailScreenState extends State<AdminWorkerDetailScreen> {
  final _db = DB.instance;
  bool _isLoading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final uid = widget.worker['uid'];
      await _db.ref('workers/$uid').update({'status': status});

      // Also update public node if approved
      if (status == 'verified' || status == 'approved') {
        await _db.ref('workersPublic/$uid').update({'isAvailable': true});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Worker $status successfully')));
      Navigator.pop(context); // Go back to list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = Map<String, dynamic>.from(
      widget.worker['verification'] ?? {},
    );
    final idFront = verification['idFrontUrl']?.toString();
    final idBack = verification['idBackUrl']?.toString();
    final idType = verification['idType']?.toString() ?? 'ID';
    final profilePhoto = widget.worker['photoUrl']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker['fullName'] ?? 'Worker Detail'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePhoto != null
                        ? NetworkImage(profilePhoto)
                        : null,
                    child: profilePhoto == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.worker['fullName'] ?? 'Unknown Name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.worker['email'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Verification Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Front ID
            _buildDocCard('Front Side ($idType)', idFront),
            const SizedBox(height: 16),

            // Back ID
            _buildDocCard('Back Side ($idType)', idBack),

            const SizedBox(height: 40),

            // Action Buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('verified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Approve & Verify'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: url != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                )
              : const Center(
                  child: Text(
                    'No Image Uploaded',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
        ),
      ],
    );
  }
}
