import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pair_or_home_gate.dart';
import 'screens/login_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return const PairOrHomeGate();
      },
    );
  }
}
