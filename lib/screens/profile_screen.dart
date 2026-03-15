import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layouts/main_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _userBmi = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      _weightController.text = (prefs.getDouble('userWeight') ?? 0.0)
          .toString();
      _heightController.text = (prefs.getDouble('userHeight') ?? 0.0)
          .toString();
      _userBmi = prefs.getDouble('userBmi') ?? 0.0;
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final name = _nameController.text;
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);

      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);

      await prefs.setString('userName', name);
      await prefs.setDouble('userWeight', weight);
      await prefs.setDouble('userHeight', height);
      await prefs.setDouble('userBmi', bmi);

      setState(() {
        _userBmi = bmi;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile Updated',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all user data, including streaks
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white70,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF141414),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;

    return MainLayout(
      currentIndex: 3, // PROFILE tab
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'PROFILE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 2.0,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white54),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF141414),
                    title: const Text('Sign Out'),
                    content: const Text(
                      'Are you sure you want to sign out? This will erase all your streaks and data.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _signOut();
                        },
                        child: const Text(
                          'SIGN OUT',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF141414),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _nameController.text.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primaryColor),
                              ),
                              child: Text(
                                'Current BMI: ${_userBmi.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Inputs
                      _buildLabel('FULL NAME'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('WEIGHT (KG)'),
                                TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(),
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('HEIGHT (CM)'),
                                TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(),
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'UPDATE PROFILE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
