import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/alert_provider.dart';
import 'map_screen.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AlertProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    final alerts = alertProvider.alerts;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,

      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Alert History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Builder(
        builder: (context) {

          if (alertProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.oceanBlue,
              ),
            );
          }

          if (alertProvider.errorMessage != null) {
            return _buildMessage(
              Icons.error_outline,
              'Unable to load alert history.',
            );
          }

          if (alerts.isEmpty) {
            return _buildMessage(
              Icons.notifications_none,
              'No alert history yet.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              return _buildAlertCard(
                context,
                alerts[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context,
      Map<String, dynamic> alert,
      ) {

    final status = alert['status']?.toString() ?? 'unknown';

    final isActive = status == 'active';

    final latitude = alert['latitude'];
    final longitude = alert['longitude'];

    final hasLocation =
        latitude is num && longitude is num;

    final timestamp = alert['createdAt'] as Timestamp?;

    final date = timestamp?.toDate();

    final dateText = date == null
        ? 'Date unavailable'
        : '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    final confidence = alert['confidence'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF102B40),
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isActive
              ? AppColors.dangerRed
              : AppColors.safeGreen,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Icon(
                isActive
                    ? Icons.warning_rounded
                    : Icons.check_circle_outline,

                color: isActive
                    ? AppColors.dangerRed
                    : AppColors.safeGreen,

                size: 28,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  alert['title'] ?? 'Shark Detection Alert',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            alert['message'] ?? 'No details available.',

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Date: $dateText',

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Status: ${isActive ? 'Active' : status}',

            style: TextStyle(
              color: isActive
                  ? AppColors.dangerRed
                  : AppColors.safeGreen,

              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          if (confidence is num) ...[

            const SizedBox(height: 8),

            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',

              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],

          if (hasLocation) ...[

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(

                onPressed: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        alertPosition: LatLng(
                          latitude.toDouble(),
                          longitude.toDouble(),
                        ),
                      ),
                    ),
                  );
                },

                icon: const Icon(Icons.location_on),

                label: const Text('View Location'),

                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.oceanBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage(IconData icon, String message) {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            color: AppColors.oceanBlue,
            size: 55,
          ),

          const SizedBox(height: 15),

          Text(
            message,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}