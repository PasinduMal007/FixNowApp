import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final String buttonText;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonText,
  });
}

class OnboardingScreens extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreens({super.key, this.onComplete});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens>
    with SingleTickerProviderStateMixin {
  int _currentScreen = 0;
  bool _isCompleted = false;
  Timer? _autoAdvanceTimer;
  late AnimationController _floatController;
  final PageController _pageController = PageController();

  final List<OnboardingData> _screens = [
    OnboardingData(
      title: 'Find Trusted Pros',
      description:
          'Connect with verified local experts for all your home repair needs. Fast and reliable service.',
      imagePath: 'assets/images/trusted_pros.png',
      buttonText: 'Next',
    ),
    OnboardingData(
      title: 'Secure Payments',
      description:
          'Pay safely through the app or cash after service. No hidden fees.',
      imagePath: 'assets/images/secure_payments.png',
      buttonText: 'Next',
    ),
    OnboardingData(
      title: 'Fast Booking',
      description:
          'Get help when you need it with real-time scheduling and tracking.',
      imagePath: 'assets/images/fast_booking.png',
      buttonText: 'Get Started',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Float animation controller
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Start auto-advance timer
    _startAutoAdvanceTimer();
  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();
    if (!_isCompleted && _currentScreen < _screens.length - 1) {
      _autoAdvanceTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_isCompleted && _currentScreen < _screens.length - 1) {
          _handleNext();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentScreen < _screens.length - 1) {
      setState(() {
        _currentScreen++;
      });
      _pageController.animateToPage(
        _currentScreen,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startAutoAdvanceTimer();
    } else {
      // Last screen - show completion
      setState(() {
        _isCompleted = true;
      });
      // Navigate to next screen after delay
      Future.delayed(const Duration(seconds: 2), () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);

        if (mounted && widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  void _handleBack() {
    if (_currentScreen > 0) {
      setState(() {
        _currentScreen--;
      });
      _pageController.animateToPage(
        _currentScreen,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startAutoAdvanceTimer();
    }
  }

  void _handleSkip() {
    setState(() {
      _currentScreen = _screens.length - 1;
    });
    _pageController.animateToPage(
      _currentScreen,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _startAutoAdvanceTimer();
  }

  void _handleDotClick(int index) {
    setState(() {
      _currentScreen = index;
    });
    _pageController.animateToPage(
      _currentScreen,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _startAutoAdvanceTimer();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentScreen = index;
    });
    _startAutoAdvanceTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back and Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  if (_currentScreen > 0)
                    IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF5B8CFF)),
                      padding: const EdgeInsets.all(8),
                    )
                  else
                    const SizedBox(width: 48),

                  // Skip Button
                  if (_currentScreen < _screens.length - 1)
                    TextButton(
                      onPressed: _handleSkip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF5B8CFF),
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Image Section with PageView
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _screens.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -10 * _floatController.value),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Image.asset(
                          _screens[index].imagePath,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Content Section
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _screens[_currentScreen].title,
                          key: ValueKey<int>(_currentScreen),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2334),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _screens[_currentScreen].description,
                          key: ValueKey<int>(_currentScreen * 10),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Progress Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_screens.length, (index) {
                          return GestureDetector(
                            onTap: () => _handleDotClick(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == _currentScreen ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == _currentScreen
                                    ? const Color(0xFF5B8CFF)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Next/Get Started Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B8CFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            _screens[_currentScreen].buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF2563EB),
              Color(0xFF1D4ED8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkmark Circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: Color(0xFF5B8CFF),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'All Set!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: Text(
                  'You\'re ready to connect with trusted pros',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
