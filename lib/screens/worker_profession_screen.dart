import 'package:flutter/material.dart';

class WorkerProfessionScreen extends StatefulWidget {
  final Function(String profession)? onNext;

  const WorkerProfessionScreen({super.key, this.onNext});

  @override
  State<WorkerProfessionScreen> createState() => _WorkerProfessionScreenState();
}

class _WorkerProfessionScreenState extends State<WorkerProfessionScreen> {
  String selectedProfession = '';
  bool showOtherInput = false;
  String addedCustomProfession = '';
  final TextEditingController _customProfessionController = TextEditingController();

  final List<Map<String, dynamic>> professions = [
    {'name': 'Electrician', 'icon': Icons.flash_on},
    {'name': 'Plumber', 'icon': Icons.water_drop},
    {'name': 'Carpenter', 'icon': Icons.handyman},
    {'name': 'Mason', 'icon': Icons.home},
    {'name': 'Painter', 'icon': Icons.brush},
    {'name': 'Mechanic', 'icon': Icons.build},
    {'name': 'Welder', 'icon': Icons.whatshot},
    {'name': 'AC Technician', 'icon': Icons.ac_unit},
    {'name': 'Tile Setter', 'icon': Icons.grid_4x4},
    {'name': 'Roofer', 'icon': Icons.roofing},
    {'name': 'Gardener', 'icon': Icons.grass},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services},
  ];

  @override
  void dispose() {
    _customProfessionController.dispose();
    super.dispose();
  }

  void handleProfessionClick(String profession) {
    setState(() {
      selectedProfession = profession;
      showOtherInput = false;
    });
  }

  void handleOtherClick() {
    setState(() {
      showOtherInput = true;
      selectedProfession = '';
    });
  }

  void handleAddCustomProfession() {
    if (_customProfessionController.text.trim().isNotEmpty) {
      setState(() {
        addedCustomProfession = _customProfessionController.text.trim();
        selectedProfession = _customProfessionController.text.trim();
        showOtherInput = false;
        _customProfessionController.clear();
      });
    }
  }

  void handleRemoveCustomProfession() {
    setState(() {
      addedCustomProfession = '';
      selectedProfession = '';
    });
  }

  void handleNext() {
    if (canProceed()) {
      final professionToSubmit = selectedProfession;      
      
      // Navigate to experience screen with profession
      Navigator.pushNamed(
        context,
        '/worker-experience',
        arguments: professionToSubmit,
      );
      
      if (widget.onNext != null) {
        widget.onNext!(professionToSubmit);
      }
    }
  }

  bool canProceed() {
    return selectedProfession.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              height: 4,
              color: const Color(0xFFE5E7EB),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.33,
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
                      child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1C2334)),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What is your profession?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2334),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Profession grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: professions.length,
                      itemBuilder: (context, index) {
                        final profession = professions[index];
                        final isSelected = selectedProfession == profession['name'];

                        return GestureDetector(
                          onTap: () => handleProfessionClick(profession['name']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF5B8CFF) : const Color(0xFFE5E7EB),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        profession['icon'],
                                        size: 20,
                                        color: isSelected ? const Color(0xFF5B8CFF) : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          profession['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected ? const Color(0xFF5B8CFF) : const Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5B8CFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Other option
                    GestureDetector(
                      onTap: handleOtherClick,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: showOtherInput ? const Color(0xFFE8F0FF) : Colors.white,
                          border: Border.all(
                            color: showOtherInput ? const Color(0xFF5B8CFF) : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                'Other',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: showOtherInput ? const Color(0xFF5B8CFF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            if (showOtherInput)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5B8CFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Custom profession input
                    if (showOtherInput) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enter your profession',
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customProfessionController,
                                  autofocus: true,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) {
                                    if (_customProfessionController.text.trim().isNotEmpty) {
                                      handleAddCustomProfession();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g., HVAC Technician',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF5B8CFF), width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF5B8CFF), width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF5B8CFF), width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _customProfessionController.text.trim().isEmpty
                                    ? null
                                    : handleAddCustomProfession,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B8CFF),
                                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Add', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please specify your profession',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ],

                    // Added custom profession card
                    if (addedCustomProfession.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          if (selectedProfession != addedCustomProfession) {
                            setState(() => selectedProfession = addedCustomProfession);
                          }
                        },
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: selectedProfession == addedCustomProfession
                                ? const Color(0xFFE8F0FF)
                                : Colors.white,
                            border: Border.all(
                              color: selectedProfession == addedCustomProfession
                                  ? const Color(0xFF5B8CFF)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.work,
                                size: 20,
                                color: selectedProfession == addedCustomProfession
                                    ? const Color(0xFF5B8CFF)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  addedCustomProfession,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selectedProfession == addedCustomProfession
                                        ? const Color(0xFF5B8CFF)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: handleRemoveCustomProfession,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                                ),
                              ),
                              if (selectedProfession == addedCustomProfession) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5B8CFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 100), // Extra space for bottom button
                  ],
                ),
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
                  onPressed: canProceed() ? handleNext : null,
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
                      color: canProceed() ? Colors.white : const Color(0xFF9CA3AF),
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
