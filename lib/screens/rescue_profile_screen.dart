import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class RescueProfileScreen extends StatefulWidget {
  const RescueProfileScreen({super.key});

  @override
  State<RescueProfileScreen> createState() =>
      _RescueProfileScreenState();
}

class _RescueProfileScreenState extends State<RescueProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _teamIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();

  UserModel? _user;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _isLoading = true;
    });

    await authProvider.loadUserProfile();

    if (!mounted) return;

    final user = authProvider.user;

    if (user != null) {
      _user = user;

      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _teamIdController.text = user.teamId ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _organizationController.text = user.organization ?? '';
    }

    setState(() {
      _isLoading = false;
    });

    if (user == null && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      teamId: _teamIdController.text.trim(),
      organization: _organizationController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      setState(() {
        _user = authProvider.user;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Update failed',
          ),
        ),
      );
    }
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: !_isEditing || readOnly,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF45C4B0),
          ),
          filled: true,
          fillColor: const Color(0xFF12364A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _cancelEditing() {
    if (_user == null) return;

    _nameController.text = _user!.fullName;
    _teamIdController.text = _user!.teamId ?? '';
    _phoneController.text = _user!.phoneNumber ?? '';
    _organizationController.text = _user!.organization ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _teamIdController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071B2C),

      appBar: AppBar(
        title: const Text('Rescue Team Profile'),
        backgroundColor: const Color(0xFF0A6C67),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _user != null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
              ),
              onPressed: () {
                if (_isEditing) {
                  _cancelEditing();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
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
          : _user == null
          ? const Center(
        child: Text(
          'Profile not found',
          style: TextStyle(color: Colors.white),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFF0A6C67),
              child: Icon(
                Icons.health_and_safety,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _user!.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Rescue Team Member',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 30),

            _buildProfileField(
              label: 'Full Name',
              icon: Icons.person,
              controller: _nameController,
            ),

            _buildProfileField(
              label: 'Email Address',
              icon: Icons.email,
              controller: _emailController,
              readOnly: true,
            ),

            _buildProfileField(
              label: 'Team ID',
              icon: Icons.badge,
              controller: _teamIdController,
            ),

            _buildProfileField(
              label: 'Phone Number',
              icon: Icons.phone,
              controller: _phoneController,
            ),

            _buildProfileField(
              label: 'Organization',
              icon: Icons.business,
              controller: _organizationController,
            ),

            const SizedBox(height: 20),

            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                  _isSaving ? null : _saveProfile,
                  icon: const Icon(Icons.save),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save Changes',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF0A6C67),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}