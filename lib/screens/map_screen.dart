import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  final LatLng alertPosition;

  const MapScreen({super.key, required this.alertPosition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071B2C),
      appBar: AppBar(
        title: const Text('Alert Map'),
        backgroundColor: const Color(0xFF0A6C67),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: alertPosition, zoom: 16),
        markers: {
          Marker(
            markerId: const MarkerId('shark_alert'),
            position: alertPosition,
            infoWindow: const InfoWindow(
              title: 'Shark Alert',
              snippet: 'Detection Location',
            ),
          ),
        },
        mapType: MapType.normal,
        zoomControlsEnabled: true,
      ),
    );
  }
}
