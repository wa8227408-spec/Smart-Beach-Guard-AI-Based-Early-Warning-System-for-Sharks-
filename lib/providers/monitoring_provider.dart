import 'package:flutter/material.dart';

class MonitoringProvider extends ChangeNotifier {
  bool _isMonitoring = false;
  bool _isAnalyzing = false;
  bool _isSharkDetected = false;
  bool _isAlarmActive = false;

  String _prediction = 'Waiting...';
  double _confidence = 0.0;
  int _consecutiveShark = 0;

  bool get isMonitoring => _isMonitoring;
  bool get isAnalyzing => _isAnalyzing;
  bool get isSharkDetected => _isSharkDetected;
  bool get isAlarmActive => _isAlarmActive;

  String get prediction => _prediction;
  double get confidence => _confidence;
  int get consecutiveShark => _consecutiveShark;

  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _isAnalyzing = false;
    _isAlarmActive = false;
    _isSharkDetected = false;

    _consecutiveShark = 0;
    _prediction = 'Monitoring Stopped';
    _confidence = 0.0;

    notifyListeners();
  }

  void setAnalyzing(bool value) {
    _isAnalyzing = value;
    notifyListeners();
  }

  bool updatePrediction({
    required String prediction,
    required double confidence,
  }) {
    _prediction = prediction;
    _confidence = confidence;

    if (prediction.toLowerCase() == 'shark') {
      _consecutiveShark++;
    } else {
      _consecutiveShark = 0;
    }

    _isSharkDetected = _consecutiveShark >= 2;

    notifyListeners();

    return _isSharkDetected;
  }

  void setAlarmActive(bool value) {
    _isAlarmActive = value;
    notifyListeners();
  }

  void resetDetection() {
    _isSharkDetected = false;
    _isAlarmActive = false;

    _consecutiveShark = 0;
    _prediction = 'Waiting...';
    _confidence = 0.0;

    notifyListeners();
  }
}