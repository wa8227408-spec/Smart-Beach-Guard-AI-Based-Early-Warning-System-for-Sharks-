import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<Map<String, dynamic>> _alerts = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get alerts => _alerts;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Get active alerts only
  List<Map<String, dynamic>> get activeAlerts {
    return _alerts
        .where((alert) => alert['status'] == 'active')
        .toList();
  }

  // Start listening to Firebase alerts
  void startListening() {
    if (_subscription != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _firestore
        .collection('alerts')
        .snapshots()
        .listen(
          (snapshot) {
        _alerts = snapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'id': doc.id,
          };
        }).toList();

        // Sort alerts by creation date
        _alerts.sort((a, b) {
          final dateA = a['createdAt'] as Timestamp?;
          final dateB = b['createdAt'] as Timestamp?;

          final timeA = dateA?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final timeB = dateB?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return timeB.compareTo(timeA);
        });

        _isLoading = false;
        _errorMessage = null;

        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;

        notifyListeners();
      },
    );
  }

  // Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}