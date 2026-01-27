import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelectionScreen extends StatelessWidget {
  final Function(String role)? onSelectRole;

  const RoleSelectionScreen({super.key, this.onSelectRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
        ),
        child: Stack(
          children: [
            // Floating tool icons in background
            _buildFloatingIcon(
              top: 80,
              left: 30,
              icon: Icons.build_rounded,
              size: 60,
              duration: 4000,
            ),
            _buildFloatingIcon(
              top: 200,
              right: 40,
              icon: Icons.hardware_rounded,
              size: 50,
              duration: 5000,
              delay: 500,
            ),
            _buildFloatingIcon(
              bottom: 150,
              left: 50,
              icon: Icons.handyman_rounded,
              size: 55,
              duration: 6000,
              delay: 1000,
            ),
            _buildFloatingIcon(
              bottom: 350,
              right: 30,
              icon: Icons.construction_rounded,
              size: 45,
              duration: 5500,
              delay: 1500,
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 80, bottom: 32),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: const Column(
                            children: [
                              Text(
                                'Welcome to FixNow!',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'How do you want to use FixNow?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Role cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // I want to Hire card
                          _RoleCard(
                            icon: Icons.person,
                            iconColor: const Color(0xFF5B8CFF),
                            iconGradient: const LinearGradient(
                              colors: [Color(0xFF5B8CFF), Color(0xFF4A7FFF)],
                            ),
                            title: 'I want to Hire',
                            description:
                                'Find trusted professionals for repairs and services',
                            benefits: const [
                              'Verified professionals',
                              'Secure payment protection',
                              '24/7 customer support',
                            ],
                            socialProof: 'Trusted by 50,000+ homeowners',
                            socialProofColor: const Color(0xFF5B8CFF),
                            hoverColor: const Color(0xFF5B8CFF),
                            onTap: () async {
                              if (onSelectRole != null) {
                                onSelectRole!('customer');
                              }
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('selectedRole', 'customer');

                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                '/signup',
                                arguments: 'customer',
                              );
                            },
                            delay: 200,
                          ),
                          const SizedBox(height: 16),

                          // I want to Work card
                          _RoleCard(
                            icon: Icons.work,
                            iconColor: const Color(0xFFF59E0B),
                            iconGradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            title: 'I want to Work',
                            description:
                                'Offer your skills and earn money on your schedule',
                            benefits: const [
                              'Flexible working hours',
                              'Get paid instantly',
                              'Build your reputation',
                            ],
                            socialProof: 'Join 10,000+ professionals earning',
                            socialProofColor: const Color(0xFFF59E0B),
                            hoverColor: const Color(0xFFF59E0B),
                            onTap: () async {
                              if (onSelectRole != null) {
                                onSelectRole!('worker');
                              }
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('selectedRole', 'worker');

                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                '/signup',
                                arguments: 'worker',
                              );
                            },
                            delay: 350,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom branding
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.build_rounded,
                                  size: 16,
                                  color: Color(0xFF5B8CFF),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'FixNow',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connecting people with trusted professionals',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required IconData icon,
    required double size,
    required int duration,
    int delay = 0,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: duration),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -20 * (0.5 - (value - 0.5).abs())),
            child: Transform.rotate(
              angle: 0.1 * (0.5 - (value - 0.5).abs()),
              child: child,
            ),
          );
        },
        child: Opacity(
          opacity: 0.1,
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Gradient iconGradient;
  final String title;
  final String description;
  final List<String> benefits;
  final String socialProof;
  final Color socialProofColor;
  final Color hoverColor;
  final VoidCallback onTap;
  final int delay;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconGradient,
    required this.title,
    required this.description,
    required this.benefits,
    required this.socialProof,
    required this.socialProofColor,
    required this.hoverColor,
    required this.onTap,
    this.delay = 0,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 20 : 10,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: widget.iconGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(widget.icon, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2334),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Benefits
                        ...widget.benefits.map(
                          (benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
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

                  // Arrow
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isHovered ? 0.05 : 0,
                    child: Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: _isHovered
                          ? widget.hoverColor
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),

              // Social proof
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Text(
                  widget.socialProof,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
