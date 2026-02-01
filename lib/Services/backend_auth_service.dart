import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class BackendAuthService {
  static const String _baseUrl =
      'https://asia-southeast1-fixnow-app-75722.cloudfunctions.net/api';

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to obtain auth token');
    }

    return token;
  }

  Future<Map<String, dynamic>> loginInfo({String? expectedRole}) async {
    final token = await _requireToken();

    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/login-info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (expectedRole == 'customer' || expectedRole == 'worker')
          'expectedRole': expectedRole,
      }),
    );

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    if (resp.statusCode != 200 || data['ok'] != true) {
      final msg = (data['message'] ?? 'Login verification failed').toString();
      throw Exception(msg);
    }

    return data;
  }

  // Convenience method: profile only (customer)
  Future<Map<String, dynamic>> getCustomerProfile() async {
    final data = await loginInfo(expectedRole: 'customer');
    final profile =
        (data['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return profile;
  }

  // Update profile through backend (recommended)
  Future<Map<String, dynamic>> updateCustomerProfile({
    required String fullName,
    String? email,
    String? phoneNumber9Digits, // 9 digits only, e.g. 771234567
    String? locationText,
    String? dob, // YYYY-MM-DD
    String? aboutMe,
  }) async {
    final token = await _requireToken();

    final payload = <String, dynamic>{
      'fullName': fullName.trim(),
      if (email != null) 'email': email.trim(),
      if (phoneNumber9Digits != null) 'phoneNumber': phoneNumber9Digits.trim(),
      if (locationText != null) 'locationText': locationText.trim(),
      if (dob != null) 'dob': dob.trim(),
      if (aboutMe != null) 'aboutMe': aboutMe.trim(),
    };

    final resp = await http.post(
      Uri.parse('$_baseUrl/customer/profile/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    if (resp.statusCode != 200 || data['ok'] != true) {
      final msg = (data['message'] ?? 'Update failed').toString();
      throw Exception(msg);
    }

    // backend returns updated profile
    final profile =
        (data['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    return profile;
  }

  Future<void> updateCustomerLocation({required String locationText}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');

    final token = await user.getIdToken();

    final resp = await http.post(
      Uri.parse('$_baseUrl/customer/location/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'locationText': locationText.trim()}),
    );

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    if (resp.statusCode != 200 || data['ok'] != true) {
      final msg = (data['message'] ?? 'Failed to save location').toString();
      throw Exception(msg);
    }
  }

  // Convenience method: profile only (worker)
  Future<Map<String, dynamic>> getWorkerProfile() async {
    final data = await loginInfo(expectedRole: 'worker');
    final profile =
        (data['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return profile;
  }

  // Update worker profile through backend
  Future<Map<String, dynamic>> updateWorkerProfile({
    required String fullName,
    String? email,
    String? phoneNumber9Digits,
    String? locationText,
    String? profession,
    String? aboutMe,
  }) async {
    final token = await _requireToken();

    final payload = <String, dynamic>{
      'fullName': fullName.trim(),
      if (email != null) 'email': email.trim(),
      if (phoneNumber9Digits != null) 'phoneNumber': phoneNumber9Digits.trim(),
      if (locationText != null) 'locationText': locationText.trim(),
      if (profession != null) 'profession': profession.trim(),
      if (aboutMe != null) 'aboutMe': aboutMe.trim(),
    };

    final resp = await http.post(
      Uri.parse('$_baseUrl/worker/profile/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    if (resp.statusCode != 200 || data['ok'] != true) {
      final msg = (data['message'] ?? 'Update failed').toString();
      throw Exception(msg);
    }

    final profile =
        (data['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    return profile;
  }

  Future<void> createCustomerProfile({
    required String fullName,
    required String email,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _db.ref('users/customers/$uid').set({
      'fullName': fullName,
      'email': email,
      'createdAt': ServerValue.timestamp,
    });
  }
}
