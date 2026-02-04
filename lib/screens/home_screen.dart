import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/live_location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  LatLng? myLocation;
  LatLng? partnerLocation;

  double distanceKm = 0;

  final Set<Marker> _markers = {};

  StreamSubscription<DocumentSnapshot>? _partnerSub;
  bool navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _startMyLocationTracking();
    _startNavigation(); // 🔥 AUTO listen to partner
  }

  // 🔴 START MY LIVE LOCATION
  Future<void> _startMyLocationTracking() async {
    await LiveLocationService.start(
      onUpdate: (pos) {
        myLocation = LatLng(pos.latitude, pos.longitude);

        _updateMarkers();

        if (_mapController != null && partnerLocation == null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: myLocation!,
                zoom: 16,
              ),
            ),
          );
        }

        setState(() {});
      },
    );
  }

  // 🔵 AUTO READ PARTNER LOCATION
  Future<void> _startNavigation() async {
    if (navigationStarted) return;
    navigationStarted = true;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists || userDoc['paired'] != true) return;

    final partnerUid = userDoc['pairedWith'];

    _partnerSub = FirebaseFirestore.instance
        .collection('locations')
        .doc(partnerUid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      partnerLocation = LatLng(data['lat'], data['lng']);

      _updateMarkers();
      _calculateDistance();
      _fitBounds();

      setState(() {});
    });
  }

  // 🟢 MARKERS
  void _updateMarkers() {
    _markers.clear();

    if (myLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: myLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    if (partnerLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("partner"),
          position: partnerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
  }

  // 📏 DISTANCE
  void _calculateDistance() {
    if (myLocation == null || partnerLocation == null) return;

    distanceKm = Geolocator.distanceBetween(
          myLocation!.latitude,
          myLocation!.longitude,
          partnerLocation!.latitude,
          partnerLocation!.longitude,
        ) /
        1000;
  }

  // 🎯 CAMERA FIT
  void _fitBounds() {
    if (_mapController == null ||
        myLocation == null ||
        partnerLocation == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(myLocation!.latitude, partnerLocation!.latitude),
        min(myLocation!.longitude, partnerLocation!.longitude),
      ),
      northeast: LatLng(
        max(myLocation!.latitude, partnerLocation!.latitude),
        max(myLocation!.longitude, partnerLocation!.longitude),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void dispose() {
    LiveLocationService.stop();
    _partnerSub?.cancel();
    super.dispose();
  }

  // 🖥️ UI (UNCHANGED)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [

          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(19.0760, 72.8777),
              zoom: 14,
            ),
            zoomControlsEnabled: false,
            markers: _markers,
            padding: const EdgeInsets.only(bottom: 220), // 🔥 FIX
            onMapCreated: (c) => _mapController = c,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                "HearTrack",
                style: GoogleFonts.ubuntu(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Row(
                    children: [
                      _infoCard(
                        icon: Icons.straighten,
                        value: partnerLocation == null
                            ? "--"
                            : "${distanceKm.toStringAsFixed(2)} km",
                        label: "Distance",
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 12),
                      _infoCard(
                        icon: Icons.circle,
                        value: partnerLocation != null ? "Active" : "Idle",
                        label: "Status",
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 12),
                      _infoCard(
                        icon: Icons.schedule,
                        value: "Live",
                        label: "Update",
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
