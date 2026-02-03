import 'package:fix_now_app/app_entry.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screens.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/worker_profession_screen.dart';
import 'screens/worker_experience_screen.dart';
import 'screens/worker_profile_screen.dart';
import 'screens/worker_verification_screen.dart';
import 'screens/worker_dashboard.dart';
import 'screens/customer_personal_info_screen.dart';
import 'screens/customer_photo_screen.dart';
import 'screens/customer_location_setup_screen.dart';
import 'screens/customer_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'screens/customer_view_quotation_screen.dart';
import 'screens/worker_create_invoice_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // Android already has google-services.json and auto-initializes [DEFAULT]
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixNow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => OnboardingScreens(
          onComplete: () {
            Navigator.of(context).pushReplacementNamed('/app-entry');
          },
        ),
        '/app-entry': (context) => const AppEntry(),
        // Worker onboarding routes
        '/worker-profession': (context) => const WorkerProfessionScreen(),
        '/worker-profile': (context) => const WorkerProfileScreen(),
        '/worker-verification': (context) => const WorkerVerificationScreen(),
        '/worker-dashboard': (context) => const WorkerDashboard(),
        // Customer onboarding routes
        '/customer-personal-info': (context) =>
            const CustomerPersonalInfoScreen(),
        '/customer-photo': (context) => const CustomerPhotoScreen(),
        '/customer-location-setup': (context) =>
            const CustomerLocationSetupScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          final role = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => LoginScreen(role: role),
          );
        }
        if (settings.name == '/signup') {
          final role = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => SignUpScreen(role: role),
          );
        }
        if (settings.name == '/worker-experience') {
          final profession = settings.arguments as String? ?? 'this profession';
          return MaterialPageRoute(
            builder: (context) =>
                WorkerExperienceScreen(profession: profession),
          );
        }
        if (settings.name == '/customer-dashboard') {
          return MaterialPageRoute(
            builder: (context) => const CustomerDashboard(),
          );
        }
        return null;
      },
    );
  }
}
