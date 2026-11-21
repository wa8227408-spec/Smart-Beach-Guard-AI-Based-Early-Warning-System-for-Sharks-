import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/monitoring_provider.dart';
import '../providers/auth_provider.dart';

import '../services/ai_service.dart';
import '../services/alarm_service.dart';

import 'map_screen.dart';
import 'rescue_profile_screen.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() =>
      _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState
    extends State<LiveMonitoringScreen> {
  CameraController? _cameraController;

  final AlarmService _alarmService = AlarmService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  MonitoringProvider? _monitoringProvider;

  Timer? _timer;

  bool _isLoading = true;
  bool _alertLocationCaptured = false;

  String _message = 'Initializing camera...';

  String? _error;
  String? _locationError;

  String? _activeAlertId;

  LatLng? _alertPosition;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _monitoringProvider =
          context.read<MonitoringProvider>();

      _initializeCamera();
    });
  }

  // Initialize rear camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found');
      }

      final backCamera = cameras.firstWhere(
            (camera) =>
        camera.lensDirection ==
            CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      _monitoringProvider?.startMonitoring();

      setState(() {
        _isLoading = false;
        _message = 'Camera is ready';
      });

      _timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => _analyzeFrame(),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
        _message = 'Camera initialization failed';
      });
    }
  }

  // Capture and send image to AI
  Future<void> _analyzeFrame() async {
    final monitoringProvider = _monitoringProvider;

    if (monitoringProvider == null ||
        monitoringProvider.isAnalyzing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    monitoringProvider.setAnalyzing(true);

    try {
      final image =
      await _cameraController!.takePicture();

      final result =
      await AIService.predictImage(image.path);

      if (!mounted) return;

      final prediction =
      result['prediction'].toString();

      final confidence =
      (result['confidence'] as num).toDouble();

      final shouldTriggerAlarm =
      monitoringProvider.updatePrediction(
        prediction: prediction,
        confidence: confidence,
      );

      setState(() {
        _error = null;
      });

      if (shouldTriggerAlarm) {
        await _triggerAlarm();
      } else if (prediction.toLowerCase() == 'shark') {
        setState(() {
          _message =
          'Possible shark detected. Verifying...';
        });
      } else {
        await _stopAlarm();

        if (!mounted) return;

        setState(() {
          _message = 'No shark detected';
          _alertLocationCaptured = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _message = 'AI connection error';
      });
    } finally {
      if (mounted) {
        monitoringProvider.setAnalyzing(false);
      }
    }
  }

  // Start alarm and create Firebase alert
  Future<void> _triggerAlarm() async {
    final monitoringProvider = _monitoringProvider;

    if (monitoringProvider == null ||
        monitoringProvider.isAlarmActive) {
      return;
    }

    monitoringProvider.setAlarmActive(true);

    if (mounted) {
      setState(() {
        _message = 'WARNING! SHARK DETECTED!';
      });
    }

    await _alarmService.playAlarm();

    if (!mounted) return;

    if (!_alertLocationCaptured) {
      _alertLocationCaptured = true;

      await _getAlertLocation();

      if (!mounted) return;

      await _saveAlertToFirebase();
    }
  }

  // Get current GPS location
  Future<void> _getAlertLocation() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please enable Location Services (GPS).',
        );
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
              'Enable it from app settings.',
        );
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        _alertPosition = LatLng(
          position.latitude,
          position.longitude,
        );

        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationError = e.toString();
      });
    }
  }

  // Save alert to Firebase Firestore
  Future<void> _saveAlertToFirebase() async {
    try {
      final currentUser =
          context.read<AuthProvider>().user;

      final confidence =
          _monitoringProvider?.confidence ?? 0.0;

      final alertData = {
        'type': 'shark',
        'title': 'Shark Detected',
        'message':
        'A shark has been detected. Please follow safety instructions.',
        'status': 'active',
        'latitude': _alertPosition?.latitude,
        'longitude': _alertPosition?.longitude,
        'locationAvailable': _alertPosition != null,
        'locationError': _locationError,
        'confidence': confidence,
        'createdBy': currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
      };

      final document = await _firestore
          .collection('alerts')
          .add(alertData);

      _activeAlertId = document.id;

      debugPrint(
        'Alert saved successfully: ${document.id}',
      );
    } catch (e) {
      debugPrint('Firebase alert error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save alert: $e'),
        ),
      );
    }
  }

  // Resolve alert in Firebase
  Future<void> _resolveAlertInFirebase() async {
    if (_activeAlertId == null) return;

    try {
      await _firestore
          .collection('alerts')
          .doc(_activeAlertId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Alert resolved: $_activeAlertId');

      _activeAlertId = null;
    } catch (e) {
      debugPrint('Could not resolve alert: $e');
    }
  }

  // Stop warning alarm
  Future<void> _stopAlarm() async {
    final monitoringProvider = _monitoringProvider;

    await _alarmService.stopAlarm();

    if (monitoringProvider?.isAlarmActive == true) {
      await _resolveAlertInFirebase();
    }

    monitoringProvider?.setAlarmActive(false);
  }

  @override
  void dispose() {
    _timer?.cancel();

    _cameraController?.dispose();

    _alarmService.dispose();

    _monitoringProvider?.stopMonitoring();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringProvider =
    context.watch<MonitoringProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF071B2C),

      appBar: AppBar(
        title: const Text('Live Monitoring'),
        backgroundColor: const Color(0xFF0A6C67),
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My Profile',

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const RescueProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      )
          : _error != null && _cameraController == null
          ? Center(
        child: Text(
          _error!,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // Camera Preview
              ClipRRect(
                borderRadius:
                BorderRadius.circular(16),

                child: AspectRatio(
                  aspectRatio: _cameraController!
                      .value.aspectRatio,

                  child: CameraPreview(
                    _cameraController!,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Detection Result
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: monitoringProvider
                      .isSharkDetected
                      ? Colors.red.shade900
                      : const Color(0xFF12364A),

                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Column(
                  children: [
                    Icon(
                      monitoringProvider
                          .isSharkDetected
                          ? Icons.warning_rounded
                          : Icons.radar,

                      color: monitoringProvider
                          .isSharkDetected
                          ? Colors.white
                          : Colors.greenAccent,

                      size: 50,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _message,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Prediction: ${monitoringProvider.prediction}',

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Shark Probability: '
                          '${monitoringProvider.confidence.toStringAsFixed(2)}%',

                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    if (monitoringProvider.isAnalyzing)
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 12,
                        ),

                        child:
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),

                    if (_error != null)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 12,
                        ),

                        child: Text(
                          _error!,

                          style: const TextStyle(
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // View Alert Location Button
              if (_alertPosition != null)
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MapScreen(
                                alertPosition:
                                _alertPosition!,
                              ),
                        ),
                      );
                    },

                    icon: const Icon(Icons.map),

                    label: const Text(
                      'View Alert Location',
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF0A6C67),
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.all(16),
                    ),
                  ),
                ),

              // Location Error
              if (_locationError != null)
                Padding(
                  padding: const EdgeInsets.all(12),

                  child: Text(
                    'Location Error: $_locationError',
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              const Text(
                'AI Monitoring System Active',

                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}