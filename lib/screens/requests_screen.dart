import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/pair_request_service.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  void _openRequest(
    BuildContext context,
    String requestId,
    String fromUid,
    String pairCode,
  ) {
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Pair request from $pairCode",
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setState(() => loading = true);
                                  await PairRequestService.reject(requestId);
                                  Navigator.pop(context);
                                },
                          child: const Text("Reject"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setState(() => loading = true);
                                  await PairRequestService.accept(
                                    requestId,
                                    fromUid,
                                  );
                                  Navigator.pop(context);
                                },
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Accept"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Inbox"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pair_requests')
            .where('toUid', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No incoming requests",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(
                  "Pair Request",
                  style: GoogleFonts.ubuntu(color: Colors.white),
                ),
                subtitle: Text(
                  "${doc['fromPairId']} wants to pair with you",
                  style: GoogleFonts.ubuntu(color: Colors.white60),
                ),
                onTap: () => _openRequest(
                  context,
                  doc.id,
                  doc['fromUid'],
                  doc['fromPairId'],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
