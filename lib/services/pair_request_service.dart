import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PairRequestService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 🔵 SEND PAIR REQUEST
  static Future<void> sendRequest(String partnerPairCode) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    final myUid = currentUser.uid;

    // 1️⃣ Find partner by pairId
    final partnerQuery = await _firestore
        .collection('users')
        .where('pairId', isEqualTo: partnerPairCode)
        .limit(1)
        .get();

    if (partnerQuery.docs.isEmpty) {
      throw Exception("Invalid pair code");
    }

    final partnerDoc = partnerQuery.docs.first;
    final partnerUid = partnerDoc.id;

    if (partnerUid == myUid) {
      throw Exception("You cannot pair with yourself");
    }

    if (partnerDoc.data()['paired'] == true) {
      throw Exception("User already paired");
    }

    // 2️⃣ Prevent duplicate request
    final existing = await _firestore
        .collection('pair_requests')
        .where('fromUid', isEqualTo: myUid)
        .where('toUid', isEqualTo: partnerUid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Request already sent");
    }

    // 3️⃣ Create request
    await _firestore.collection('pair_requests').add({
      'fromUid': myUid,
      'toUid': partnerUid,
      'fromPairId': partnerPairCode,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🟢 ACCEPT PAIR REQUEST (FIXED WITH BATCH)
  static Future<void> accept(String requestId, String fromUid) async {
    final currentUid = _auth.currentUser!.uid;

    final batch = _firestore.batch();

    final requestRef =
        _firestore.collection('pair_requests').doc(requestId);

    final pairRef = _firestore.collection('pairs').doc();

    final fromUserRef =
        _firestore.collection('users').doc(fromUid);

    final currentUserRef =
        _firestore.collection('users').doc(currentUid);

    batch.update(requestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    batch.set(pairRef, {
      'user1': fromUid,
      'user2': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(fromUserRef, {
      'paired': true,
      'pairedWith': currentUid,
    });

    batch.update(currentUserRef, {
      'paired': true,
      'pairedWith': fromUid,
    });

    await batch.commit(); // 🔥 ATOMIC
  }

  /// 🔴 REJECT PAIR REQUEST
  static Future<void> reject(String requestId) async {
    await _firestore
        .collection('pair_requests')
        .doc(requestId)
        .update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }
}
