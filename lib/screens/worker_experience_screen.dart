import 'package:flutter/material.dart';
import 'package:fix_now_app/services/worker_onboarding_service.dart';

class WorkerExperienceScreen extends StatefulWidget {
  final String profession;
  final Function(String experience)? onNext;

  const WorkerExperienceScreen({
    super.key,
    required this.profession,
    this.onNext,
  });

  @override
  State<WorkerExperienceScreen> createState() => _WorkerExperienceScreenState();
}

class _WorkerExperienceScreenState extends State<WorkerExperienceScreen> {
  String selectedExperience = '';

  final List<Map<String, dynamic>> experienceOptions = [
    {
      'value': 'less-than-1',
      'label': 'Less than 1 Year',
      'badge': 'Beginner',
      'icon': Icons.work_outline,
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
    },
    {
      'value': '1-3',
      'label': '1 - 3 Years',
      'badge': 'Beginner',
      'icon': Icons.work,
      'gradient': [Color(0xFF3B82F6), Color(0xFF2563EB)],
    },
    {
      'value': '3-5',
      'label': '3 - 5 Years',
      'badge': 'Intermediate',
      'icon': Icons.emoji_events_outlined,
      'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    },
    {
      'value': '5-10',
      'label': '5 - 10 Years',
      'badge': 'Experienced',
      'icon': Icons.star_outline,
      'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
    },
    {
      'value': '10+',
      'label': '10+ Years',
      'badge': 'Expert',
      'icon': Icons.star,
      'gradient': [Color(0xFFEF4444), Color(0xFFDC2626)],
    },
  ];

  Future<void> handleNext() async {
    if (selectedExperience.isEmpty) return;

    try {
      final service = WorkerOnboardingService();
      await service.saveExperience(selectedExperience);

      if (!mounted) return;
      Navigator.pushNamed(context, '/worker-profile');

      if (widget.onNext != null) {
        widget.onNext!(selectedExperience);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save experience: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar (50%)
            Container(
              height: 4,
              color: const Color(0xFFE5E7EB),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.50,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B8CFF), Color(0xFF4A7FFF)],
                    ),
                  ),
                ),
              ),
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF1C2334),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title and subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Years of Experience',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2334),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How many years have you worked as ${widget.profession}?',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Experience options - Scrollable
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: experienceOptions.length,
                itemBuilder: (context, index) {
                  final option = experienceOptions[index];
                  final isSelected = selectedExperience == option['value'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedExperience = option['value']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE8F0FF),
                                    Color(0xFFF0F6FF),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF5B8CFF)
                                : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF5B8CFF,
                                    ).withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Icon with gradient
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: option['gradient'],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option['icon'],
                                size: 24,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['label'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1C2334),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option['badge'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? const Color(0xFF5B8CFF)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Checkmark
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF5B8CFF)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5B8CFF)
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Next button - Fixed at bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedExperience.isEmpty ? null : () => handleNext(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8CFF),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedExperience.isEmpty
                          ? const Color(0xFF9CA3AF)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
