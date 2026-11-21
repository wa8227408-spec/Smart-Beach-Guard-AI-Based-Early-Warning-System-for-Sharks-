import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          fullName: fullName,
          role: role,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      debugPrint('Error in signUp: $e');
      rethrow;
    }

    return null;
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!);
        }
      }
    } catch (e) {
      debugPrint('Error in signIn: $e');
      rethrow;
    }

    return null;
  }

  Future<UserModel?> getUserProfile() async {
    final user = currentUser;

    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String teamId,
    required String phoneNumber,
    required String organization,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({
      'fullName': fullName,
      'teamId': teamId,
      'phoneNumber': phoneNumber,
      'organization': organization,
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}