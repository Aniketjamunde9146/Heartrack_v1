import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/pair_id_generator.dart';

class UserService {
  static Future<void> createUserIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser!;
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'pairId': generatePairId(),
        'paired': false,
        'partnerId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
 