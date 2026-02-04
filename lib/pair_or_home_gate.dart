import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/pairing_screen.dart';
import 'screens/home_screen.dart';

class PairOrHomeGate extends StatelessWidget {
  const PairOrHomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const PairingScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        if (data['paired'] != true) {
          return const PairingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
