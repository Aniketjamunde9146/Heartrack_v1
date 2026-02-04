import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  Future<void> onGooglePressed() async {
    setState(() => isLoading = true);

    try {
      // 1️⃣ Google Sign-In
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // 2️⃣ Google Auth
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3️⃣ Firebase Login
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 4️⃣ Create Firestore user + Pair ID (ONLY FIRST TIME)
      await UserService.createUserIfNotExists();

      // ❌ NO NAVIGATION HERE
      // AppGate will auto-handle it

    } catch (e) {
      debugPrint("Login error: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      body: Stack(
        children: [

          Align(
            alignment: const Alignment(0, -0.35),
            child: Text(
              "HearTrack",
              style: GoogleFonts.changaOne(
                fontSize: 44,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
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

                  Text(
                    "Share location with trust",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Stay connected with your loved ones by securely sharing real-time location whenever you choose.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onGooglePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6F0FF),
                        disabledBackgroundColor: const Color(0xFFE6F0FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0F172A),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: const Center(child: Text("G")),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Continue with Google",
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Your location is shared only with consent. Privacy always comes first.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
