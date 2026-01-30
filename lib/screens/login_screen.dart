import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/Services/auth_login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final String? role; // 'worker' or 'customer'

  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailTouched = false;
  bool _roleInitialized = false;

  // ✅ resolved role for this screen (from route args or widget.role)
  String _role = 'customer';

  @override
  void initState() {
    super.initState();
    _loadPrefError();
  }

  Future<void> _loadPrefError() async {
    final prefs = await SharedPreferences.getInstance();
    final msg = prefs.getString('authError');

    if (!mounted) return;

    if (msg != null && msg.trim().isNotEmpty) {
      // Avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _errorMessage = msg);
      });

      await prefs.remove('authError');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roleInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    String? routeRole;
    if (args is String && (args == 'customer' || args == 'worker')) {
      routeRole = args;
    }

    final widgetRole = (widget.role == 'customer' || widget.role == 'worker')
        ? widget.role
        : null;

    // ✅ set once WITHOUT setState (safe)
    _role = routeRole ?? widgetRole ?? 'customer';
    _roleInitialized = true;

    // Optional: load any saved error after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrefError(); // only if you have this method
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = AuthLoginService();

      // ✅ enforce selected role
      final result = await service.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        expectedRole: _role,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedRole', result.role);

      if (!mounted) return;

      // ✅ Route based on role and onboarding
      if (result.role == 'customer') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/customer-dashboard',
          (route) => false,
        );
        return;
      }

      // worker onboarding routing
      final onboarding = (result.profile["onboarding"] as Map?) ?? {};
      final completed = (onboarding["completed"] == true);
      final step = (onboarding["step"] is int) ? onboarding["step"] as int : 0;

      if (completed) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/worker-dashboard',
          (route) => false,
        );
        return;
      }

      switch (step) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/worker-profession',
            (r) => false,
          );
          break;
        case 1:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/worker-experience',
            (r) => false,
          );
          break;
        case 2:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/worker-profile',
            (r) => false,
          );
          break;
        case 3:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/worker-verification',
            (r) => false,
          );
          break;
        case 4:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/worker-rates',
            (r) => false,
          );
          break;
        default:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/worker-profession',
            (r) => false,
          );
      }
    } on FirebaseAuthException catch (e) {
      final msg = _friendlyAuthError(e);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authError', msg);

      if (!mounted) return;
      setState(() => _errorMessage = msg);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authError', msg);

      if (!mounted) return;
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Invalid email or password.';

      // Newer Firebase Auth codes (very common now)
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password.';

      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';

      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Console.';
      default:
        // If Firebase provided a useful message, show it
        final m = (e.message ?? '').trim();
        if (m.isNotEmpty) return m;
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailIsValid =
        _emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text);
    final emailIsInvalid =
        _emailTouched &&
        _emailController.text.isNotEmpty &&
        !_isValidEmail(_emailController.text);

    final roleTitle = _role == 'worker' ? 'Worker Login' : 'Customer Login';
    final roleSubtitle = _role == 'worker'
        ? 'Sign in to continue as a worker'
        : 'Sign in to continue as a customer';

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
            _buildFloatingIcon(
              top: 80,
              left: 32,
              icon: Icons.build_rounded,
              size: 48,
            ),
            _buildFloatingIcon(
              top: 160,
              right: 48,
              icon: Icons.hardware_rounded,
              size: 40,
              delay: 1000,
            ),
            _buildFloatingIcon(
              top: 256,
              left: 64,
              icon: Icons.handyman_rounded,
              size: 36,
              delay: 2000,
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 64, bottom: 32),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: -0.5, end: 0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 3.14159,
                              child: Transform.scale(
                                scale: 1 + value.abs(),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 70,
                                  color: Color(0xFFF59E0B),
                                ),
                                Positioned(
                                  child: Icon(
                                    Icons.build,
                                    size: 35,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

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
                          child: Column(
                            children: [
                              Text(
                                roleTitle,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                roleSubtitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFCCCCCC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role Selection Toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() => _role = 'customer');
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          await prefs.setString(
                                            'selectedRole',
                                            'customer',
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _role == 'customer'
                                                ? const Color(0xFF3B82F6)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person,
                                                size: 18,
                                                color: _role == 'customer'
                                                    ? Colors.white
                                                    : const Color(0xFF6B7280),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Customer',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: _role == 'customer'
                                                      ? Colors.white
                                                      : const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() => _role = 'worker');
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          await prefs.setString(
                                            'selectedRole',
                                            'worker',
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _role == 'worker'
                                                ? const Color(0xFF3B82F6)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.build_circle,
                                                size: 18,
                                                color: _role == 'worker'
                                                    ? Colors.white
                                                    : const Color(0xFF6B7280),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Worker',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: _role == 'worker'
                                                      ? Colors.white
                                                      : const Color(0xFF6B7280),
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
                              const SizedBox(height: 24),

                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) => setState(() {}),
                                onTap: () =>
                                    setState(() => _emailTouched = true),
                                decoration: InputDecoration(
                                  hintText: 'john@example.com',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: emailIsValid
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF10B981),
                                          size: 20,
                                        )
                                      : emailIsInvalid
                                      ? const Icon(
                                          Icons.error,
                                          color: Color(0xFFEF4444),
                                          size: 20,
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: emailIsValid
                                          ? const Color(0xFF10B981)
                                          : emailIsInvalid
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: emailIsValid
                                          ? const Color(0xFF10B981)
                                          : emailIsInvalid
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF5B8CFF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Please enter your email';
                                  if (!_isValidEmail(value))
                                    return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              const Text(
                                'PASSWORD',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5B8CFF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Please enter your password';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) => setState(
                                            () => _rememberMe = value ?? false,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5B8CFF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B8CFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 24),

                              _SocialButton(
                                onPressed: () {},
                                icon: 'google',
                                label: 'Continue with Google',
                              ),
                              const SizedBox(height: 12),
                              _SocialButton(
                                onPressed: () {},
                                icon: 'apple',
                                label: 'Continue with Apple',
                                isBlack: true,
                              ),
                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  GestureDetector(
                                    // ✅ keep role when going to signup
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/signup',
                                      arguments: _role,
                                    ),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5B8CFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
    required double top,
    double? left,
    double? right,
    required IconData icon,
    required double size,
    int delay = 0,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 6000),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -20 * (0.5 - (value - 0.5).abs())),
            child: child,
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

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String icon;
  final String label;
  final bool isBlack;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isBlack = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isBlack ? Colors.black : Colors.white,
          side: BorderSide(
            color: isBlack ? Colors.black : const Color(0xFFE5E7EB),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon == 'google' ? Icons.g_mobiledata : Icons.apple,
              color: isBlack ? Colors.white : Colors.black,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isBlack ? Colors.white : const Color(0xFF1C2334),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
