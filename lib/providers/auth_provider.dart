import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _user;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> signup({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      return _user;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _user = await _authService.getUserProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? teamId,
    String? organization,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (_user == null) {
        throw Exception('User is not logged in.');
      }

      await _authService.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        teamId: teamId ?? _user!.teamId ?? '',
        organization: organization ?? _user!.organization ?? '',
      );

      _user = await _authService.getUserProfile();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}