import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class MockDataService {
  final _db = DB.instance;

  Future<void> seedPendingWorkers() async {
    final Map<String, Map<String, dynamic>> mockWorkers = {
      'mock_worker_001': {
        'fullName': 'Saman Kumara',
        'email': 'saman.test@gmail.com',
        'phone': '+94771234567',
        'role': 'worker',
        'status': 'pending_verification',
        'photoUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
        'createdAt': ServerValue.timestamp,
        'verification': {
          'idType': 'nic',
          'idFrontUrl': 'https://placehold.co/600x400/png?text=NIC+Front+Side',
          'idBackUrl': 'https://placehold.co/600x400/png?text=NIC+Back+Side',
          'updatedAt': ServerValue.timestamp,
          'profilePhotoPending': true,
          'idFrontPending': true,
          'idBackPending': true,
        },
        'rating': 4.5,
        'reviews': 0,
        'workerType': 'Electrician',
      },
      'mock_worker_002': {
        'fullName': 'Nimali Perera',
        'email': 'nimali.test@gmail.com',
        'phone': '+94719876543',
        'role': 'worker',
        'status': 'pending_verification',
        'photoUrl': 'https://randomuser.me/api/portraits/women/44.jpg',
        'createdAt': ServerValue.timestamp,
        'verification': {
          'idType': 'passport',
          'idFrontUrl': 'https://placehold.co/600x400/png?text=Passport+Front',
          'idBackUrl': 'https://placehold.co/600x400/png?text=Passport+Back',
          'updatedAt': ServerValue.timestamp,
          'profilePhotoPending': true,
          'idFrontPending': true,
          'idBackPending': true,
        },
        'rating': 0.0,
        'reviews': 0,
        'workerType': 'Plumber',
      },
      'mock_worker_003': {
        'fullName': 'Kasun Bandara',
        'email': 'kasun.test@gmail.com',
        'phone': '+94701122334',
        'role': 'worker',
        'status': 'pending_verification',
        'photoUrl': 'https://randomuser.me/api/portraits/men/85.jpg',
        'createdAt': ServerValue.timestamp,
        'verification': {
          'idType': 'driving-license',
          'idFrontUrl': 'https://placehold.co/600x400/png?text=License+Front',
          'idBackUrl': 'https://placehold.co/600x400/png?text=License+Back',
          'updatedAt': ServerValue.timestamp,
          'profilePhotoPending': true,
          'idFrontPending': true,
          'idBackPending': true,
        },
        'rating': 4.8,
        'reviews': 12,
        'workerType': 'Carpenter',
      },
    };

    for (var entry in mockWorkers.entries) {
      // Use set to overwrite if exists, or just push() if you want new ones every time.
      // Using set with specific IDs to avoid spamming duplicates if clicked multiple times.
      await _db.ref('users/workers/${entry.key}').set(entry.value);
    }
  }
}
