import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final String bookingId;

  const PaymentWaitingScreen({super.key, required this.bookingId});

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  bool _popped = false;
  StreamSubscription<DatabaseEvent>? _sub;

  @override
  void initState() {
    super.initState();

    final ref = FirebaseDatabase.instance.ref(
      'bookings/${widget.bookingId}/status',
    );

    _sub = ref.onValue.listen((event) {
      final status = event.snapshot.value?.toString() ?? '';

      if (!_popped && status == 'payment_paid') {
        _popped = true;
        if (mounted) Navigator.of(context).pop(true); // ✅ return success
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref(
      'bookings/${widget.bookingId}/status',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirming payment'),
        actions: [
          TextButton(
            onPressed: () {
              if (!_popped) {
                _popped = true;
                Navigator.of(context).pop(false);
              }
            },
            child: const Text('Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not listen for payment update:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final status = snap.data?.snapshot.value?.toString() ?? '';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for PayHere confirmation...',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text('Current status: $status', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
