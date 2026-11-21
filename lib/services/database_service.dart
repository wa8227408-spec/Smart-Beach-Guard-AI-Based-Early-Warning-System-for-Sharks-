import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc.data();
    }

    return null;
  }
}