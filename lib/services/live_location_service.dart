import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveLocationService {
  static StreamSubscription<Position>? _subscription;

  static Future<void> start({
    required void Function(Position position) onUpdate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final permission = await Permission.location.request();
    if (!permission.isGranted) {
      throw Exception("Location permission denied");
    }

    _subscription?.cancel();

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      // 🔴 SAVE TO FIREBASE
      FirebaseFirestore.instance
          .collection('locations')
          .doc(user.uid)
          .set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
        'sharing': true,
      }, SetOptions(merge: true));

      // 🔵 UPDATE UI
      onUpdate(pos);
    });
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
