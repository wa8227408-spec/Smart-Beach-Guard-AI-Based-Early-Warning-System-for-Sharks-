import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';

class VisitorProfileScreen extends StatefulWidget {
  const VisitorProfileScreen({super.key});

  @override
  State<VisitorProfileScreen> createState() =>
      _VisitorProfileScreenState();
}

class _VisitorProfileScreenState extends State<VisitorProfileScreen> {
  final TextEditingController _fullNameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _email = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final authProvider = context.read<AuthProvider>();

      await authProvider.loadUserProfile();

      if (!mounted) return;

      final user = authProvider.user;

      if (user == null) {
        _showMessage('Unable to load user profile.');
        return;
      }

      setState(() {
        _fullNameController.text = user.fullName;
        _phoneController.text = user.phoneNumber ?? '';
        _email = user.email;
      });
    } catch (e) {
      _showMessage('Failed to load profile.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.updateProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _isEditing = false;

          final user = authProvider.user;

          if (user != null) {
            _fullNameController.text = user.fullName;
            _phoneController.text = user.phoneNumber ?? '';
            _email = user.email;
          }
        });

        _showMessage('Profile updated successfully!');
      } else {
        _showMessage('Failed to update profile.');
      }
    } catch (e) {
      _showMessage('Failed to update profile.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEditing() {
    final user = context.read<AuthProvider>().user;

    setState(() {
      _isEditing = false;

      if (user != null) {
        _fullNameController.text = user.fullName;
        _phoneController.text = user.phoneNumber ?? '';
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,

      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _isSaving
                  ? null
                  : () {
                if (_isEditing) {
                  _cancelEditing();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },

              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
              ),

              tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
            ),
        ],
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.oceanBlue,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Picture
            const CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.oceanBlue,

              child: Icon(
                Icons.person,
                size: 65,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Visitor Account',

              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _buildProfileField(
              label: 'Full Name',
              icon: Icons.person_outline,
              controller: _fullNameController,
            ),

            const SizedBox(height: 18),

            _buildReadOnlyField(
              label: 'Email Address',
              icon: Icons.email_outlined,
              value: _email,
            ),

            const SizedBox(height: 18),

            _buildProfileField(
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 30),

            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton.icon(
                  onPressed:
                  _isSaving ? null : _saveProfile,

                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,

                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),

                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save Changes',
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oceanBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,

      style: const TextStyle(
        color: Colors.white,
      ),

      decoration: InputDecoration(
        labelText: label,

        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
        ),

        prefixIcon: Icon(
          icon,
          color: AppColors.oceanBlue,
        ),

        filled: true,
        fillColor: const Color(0xFF102B40),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 17,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFF102B40),
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.oceanBlue,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value.isEmpty ? 'Not available' : value,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}