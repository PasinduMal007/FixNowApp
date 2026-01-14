import 'package:flutter/material.dart';

class WorkerEmergencyModeScreen extends StatefulWidget {
  const WorkerEmergencyModeScreen({super.key});

  @override
  State<WorkerEmergencyModeScreen> createState() => _WorkerEmergencyModeScreenState();
}

class _WorkerEmergencyModeScreenState extends State<WorkerEmergencyModeScreen> {
  bool _isEmergencyMode = false;
  double _rateMultiplier = 1.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Mode',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Accept urgent jobs only',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFECDD3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDA4AF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_fire_department,
                                  color: Color(0xFFF43F5E),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency Mode',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9F1239),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isEmergencyMode ? 'Currently ON' : 'Currently OFF',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9F1239),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isEmergencyMode,
                                onChanged: (value) => setState(() => _isEmergencyMode = value),
                                activeColor: const Color(0xFFF43F5E),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // How Emergency Mode Works
                        const Text(
                          'How Emergency Mode Works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.priority_high,
                          'Urgent Jobs Only',
                          'You\'ll only receive jobs marked as "Emergency" or "Urgent"',
                          const Color(0xFFF43F5E),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.attach_money,
                          'Higher Rates',
                          'Automatically apply 1.5x surge pricing to emergency jobs',
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.visibility,
                          'Priority Visibility',
                          'Your profile appears first in emergency searches',
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 24),

                        // Emergency Rate Multiplier
                        const Text(
                          'Emergency Rate Multiplier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Current Multiplier',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    '${_rateMultiplier.toStringAsFixed(1)}x',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF43F5E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Slider(
                                value: _rateMultiplier,
                                min: 1.0,
                                max: 3.0,
                                divisions: 20,
                                activeColor: const Color(0xFFF43F5E),
                                label: '${_rateMultiplier.toStringAsFixed(1)}x Rate',
                                onChanged: (value) {
                                  setState(() => _rateMultiplier = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Activate Button
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isEmergencyMode = !_isEmergencyMode);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isEmergencyMode 
                                    ? 'Emergency Mode activated!' 
                                    : 'Emergency Mode deactivated',
                                ),
                                backgroundColor: const Color(0xFFF43F5E),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF43F5E),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _isEmergencyMode ? 'Deactivate Emergency Mode' : 'Activate Emergency Mode',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
