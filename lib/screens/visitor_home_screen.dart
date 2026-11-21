import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';

import 'auth/login_screen.dart';
import 'map_screen.dart';
import 'visitor_profile_screen.dart';
import 'alert_history_screen.dart';

class VisitorHomeScreen extends StatefulWidget {
  final String fullName;

  const VisitorHomeScreen({
    super.key,
    required this.fullName,
  });

  @override
  State<VisitorHomeScreen> createState() => _VisitorHomeScreenState();
}

class _VisitorHomeScreenState extends State<VisitorHomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AlertProvider>().startListening();
      }
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,

      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,

        title: const Text(
          'Smart Beach Guard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white,
            ),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const VisitorProfileScreen(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.fullName}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Stay informed and enjoy a safer beach experience.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              _buildMonitoringCard(),

              const SizedBox(height: 20),

              _buildAlertHistoryButton(context),

              const SizedBox(height: 25),

              const Text(
                'Latest Alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _buildAlertsSection(context),

              const SizedBox(height: 25),

              const Text(
                'Safety Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _buildSafetyTip(
                Icons.warning_amber_rounded,
                'Follow beach warning signs.',
              ),

              _buildSafetyTip(
                Icons.groups_outlined,
                'Follow instructions from the rescue team.',
              ),

              _buildSafetyTip(
                Icons.beach_access,
                'Stay within designated swimming areas.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Monitoring Card
  Widget _buildMonitoringCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.oceanBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.oceanBlue,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.radar,
                color: AppColors.oceanBlue,
                size: 30,
              ),

              SizedBox(width: 12),

              Text(
                'Beach Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            'The system monitors the beach and displays safety alerts when detected.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Alert History Button
  Widget _buildAlertHistoryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,

      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const AlertHistoryScreen(),
            ),
          );
        },

        icon: const Icon(
          Icons.history,
          size: 25,
        ),

        label: const Text(
          'View Alert History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.oceanBlue,
          side: const BorderSide(
            color: AppColors.oceanBlue,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Provider Alerts Section
  Widget _buildAlertsSection(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    if (alertProvider.errorMessage != null) {
      return _buildMessageCard(
        icon: Icons.error_outline,
        title: 'Unable to load alerts',
        message: 'Please check your internet connection.',
      );
    }

    if (alertProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: CircularProgressIndicator(
            color: AppColors.oceanBlue,
          ),
        ),
      );
    }

    final alerts = alertProvider.activeAlerts;

    if (alerts.isEmpty) {
      return _buildMessageCard(
        icon: Icons.notifications_active_outlined,
        title: 'No active alerts',
        message: 'New safety alerts will appear here.',
      );
    }

    return Column(
      children: alerts.map((alert) {
        return _buildAlertCard(
          context,
          alert,
        );
      }).toList(),
    );
  }

  // Alert Card
  Widget _buildAlertCard(
      BuildContext context,
      Map<String, dynamic> alert,
      ) {
    final latitude = alert['latitude'];
    final longitude = alert['longitude'];

    final hasLocation =
        latitude is num && longitude is num;

    final confidence = alert['confidence'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF102B40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dangerRed,
          width: 1.5,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppColors.dangerRed,
                size: 30,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Shark Detection Alert',
                  style: TextStyle(
                    color: AppColors.dangerRed,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Text(
                'ACTIVE',
                style: TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            alert['message'] ??
                'A shark detection alert has been reported.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),

          if (confidence is num) ...[
            const SizedBox(height: 10),

            Text(
              'Detection confidence: '
                  '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 15),

          if (hasLocation)
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
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
                label: const Text('View Alert Location'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.oceanBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            )
          else
            Text(
              'Location is currently unavailable.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  // Empty / Error Message Card
  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF102B40),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.oceanBlue,
            size: 40,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Safety Tip
  Widget _buildSafetyTip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: const Color(0xFF102B40),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.safeGreen,
            size: 25,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}