import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'customer_chat_conversation_screen.dart';

class CustomerLiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const CustomerLiveTrackingScreen({super.key, required this.booking});

  @override
  State<CustomerLiveTrackingScreen> createState() =>
      _CustomerLiveTrackingScreenState();
}

class _CustomerLiveTrackingScreenState
    extends State<CustomerLiveTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;

  // Simulated locations (in production, these would come from Firebase)
  LatLng _workerLocation = const LatLng(6.9271, 79.8612); // Colombo
  final LatLng _customerLocation = const LatLng(6.9370, 79.8501); // Colombo 03

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  double _distanceKm = 2.5;
  int _etaMinutes = 15;
  bool _isMapReady = false;
  bool _isAnimatingCamera = false;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _startLocationSimulation();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMarkers() {
    setState(() {
      // Worker marker (blue)
      _markers.add(
        Marker(
          markerId: const MarkerId('worker'),
          position: _workerLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: widget.booking['worker'] ?? 'Worker',
            snippet: 'On the way',
          ),
        ),
      );

      // Customer marker (green)
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Destination',
          ),
        ),
      );

      // Route line
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_workerLocation, _customerLocation],
          color: const Color(0xFF4A7FFF),
          width: 4,
        ),
      );
    });
  }

  void _startLocationSimulation() {
    // Simulate worker moving towards customer every 3 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _updateCount++;

        // Move worker 10% closer to customer
        double newLat =
            _workerLocation.latitude +
            (_customerLocation.latitude - _workerLocation.latitude) * 0.1;
        double newLng =
            _workerLocation.longitude +
            (_customerLocation.longitude - _workerLocation.longitude) * 0.1;

        _workerLocation = LatLng(newLat, newLng);

        // Update distance and ETA
        _distanceKm = _calculateDistance(_workerLocation, _customerLocation);
        _etaMinutes = (_distanceKm * 6).round(); // Assume 10 km/h average speed

        if (_distanceKm < 0.1) {
          // Worker arrived
          _etaMinutes = 0;
          timer.cancel();
        }

        _initializeMarkers();
      });

      // Only animate camera every 3rd update (every 9 seconds) to prevent freezing
      if (_isMapReady &&
          _mapController != null &&
          !_isAnimatingCamera &&
          _updateCount % 3 == 0) {
        _isAnimatingCamera = true;

        _mapController!
            .animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    math.min(
                      _workerLocation.latitude,
                      _customerLocation.latitude,
                    ),
                    math.min(
                      _workerLocation.longitude,
                      _customerLocation.longitude,
                    ),
                  ),
                  northeast: LatLng(
                    math.max(
                      _workerLocation.latitude,
                      _customerLocation.latitude,
                    ),
                    math.max(
                      _workerLocation.longitude,
                      _customerLocation.longitude,
                    ),
                  ),
                ),
                100.0, // Padding
              ),
            )
            .then((_) {
              _isAnimatingCamera = false;
            });
      }
    });
  }

  double _calculateDistance(LatLng from, LatLng to) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // km
    double dLat = _degreesToRadians(to.latitude - from.latitude);
    double dLon = _degreesToRadians(to.longitude - from.longitude);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(from.latitude)) *
            math.cos(_degreesToRadians(to.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _workerLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              setState(() {
                _isMapReady = true;
              });

              // Fit both markers in view
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      LatLngBounds(
                        southwest: LatLng(
                          math.min(
                            _workerLocation.latitude,
                            _customerLocation.latitude,
                          ),
                          math.min(
                            _workerLocation.longitude,
                            _customerLocation.longitude,
                          ),
                        ),
                        northeast: LatLng(
                          math.max(
                            _workerLocation.latitude,
                            _customerLocation.latitude,
                          ),
                          math.max(
                            _workerLocation.longitude,
                            _customerLocation.longitude,
                          ),
                        ),
                      ),
                      100.0,
                    ),
                  );
                }
              });
            },
          ),

          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),

          // ETA Card - Compact Version
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A7FFF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text(
                        'ETA',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$_etaMinutes min',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Worker Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _etaMinutes == 0
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _etaMinutes == 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _etaMinutes == 0
                                ? 'Worker has arrived'
                                : 'Worker is on the way',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Worker Info
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF4A7FFF),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking['worker'] ??
                                    widget.booking['workerName'] ??
                                    'Kasun Perera',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.booking['workerType'] ??
                                    'Service Professional',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Color(0xFFFBBF24),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.booking['rating'] ?? widget.booking['workerRating'] ?? 4.8}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Service Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.flash_on,
                              color: Color(0xFFFBBF24),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.booking['service'] ??
                                      'Electrical Repair',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.booking['date'] ?? 'Today',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message Button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to chat with specific worker
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerChatConversationScreen(
                                  threadId: '',
                                  otherUid: '',
                                  otherName: '',
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A7FFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
