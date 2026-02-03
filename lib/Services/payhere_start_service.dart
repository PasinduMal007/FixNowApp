import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PayHereStartService {
  // Your function base URL (api function)
  static const String _base =
      'https://asia-southeast1-fixnow-app-75722.cloudfunctions.net/api';

  Future<Map<String, dynamic>> startPayment({required String bookingId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    final idToken = await user.getIdToken(true);

    final uri = Uri.parse('$_base/payhere/start');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bookingId': bookingId}),
    );

    final body = jsonDecode(resp.body);
    if (resp.statusCode != 200 || body['ok'] != true) {
      throw Exception(body['message'] ?? 'Failed to start payment');
    }

    return body as Map<String, dynamic>;
  }
}
