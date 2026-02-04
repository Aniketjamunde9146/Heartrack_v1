import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/pair_request_service.dart';
import 'requests_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  String? myPairCode;
  bool isPaired = false;
  bool sending = false;
  final TextEditingController _partnerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyData();
  }

  Future<void> _loadMyData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      myPairCode = doc['pairId'];
      isPaired = doc['paired'] == true;
    });
  }

  Future<void> _sendRequest() async {
    if (_partnerController.text.trim().length < 6) return;

    setState(() => sending = true);
    try {
      await PairRequestService.sendRequest(
        _partnerController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pair request sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [

              // HEADER
              Row(
                children: [
                  Text(
                    "HearTrack",
                    style: GoogleFonts.ubuntu(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    color: const Color(0xFF38BDF8),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // STATUS
              Text(
                isPaired ? "Connected" : "Pending approval",
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // MY PAIR CODE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Your pair code",
                  style: GoogleFonts.ubuntu(color: Colors.white60),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      myPairCode ?? "--",
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      color: const Color(0xFF38BDF8),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: myPairCode ?? ""),
                        );
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PARTNER CODE INPUT
              TextField(
                controller: _partnerController,
                maxLength: 6,
                style: GoogleFonts.ubuntu(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Partner’s code",
                  hintStyle: GoogleFonts.ubuntu(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SEND BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isPaired || sending ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: sending
                      ? const CircularProgressIndicator()
                      : Text(
                          "Send Pair Request",
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
