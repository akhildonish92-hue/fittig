import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../layouts/main_layout.dart';
import '../services/update_service.dart';
import '../widgets/animated_popup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UpdateService _updateService = UpdateService();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _calorieController = TextEditingController();
  double _userBmi = 0.0;
  bool _isLoading = true;
  bool _updateAvailable = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final isAvailable = await _updateService.checkForUpdates();
    if (!mounted) return;
    setState(() {
      _updateAvailable = isAvailable;
    });
  }

  Future<void> _handleUpdateNow() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final updated = await _updateService.attemptUpdate();
    if (!mounted) return;

    setState(() {
      _isUpdating = false;
      if (updated) {
        _updateAvailable = false;
      }
    });

    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Update downloaded. Please restart the app to apply fixes.',
          ),
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      _weightController.text = (prefs.getDouble('userWeight') ?? 0.0)
          .toString();
      _heightController.text = (prefs.getDouble('userHeight') ?? 0.0)
          .toString();
      _calorieController.text = (prefs.getDouble('dailyCalorieLimit') ?? 2000.0)
          .toStringAsFixed(0);
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
      final calorieLimit = double.tryParse(_calorieController.text) ?? 2000.0;

      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);

      await prefs.setString('userName', name);
      await prefs.setDouble('userWeight', weight);
      await prefs.setDouble('userHeight', height);
      await prefs.setDouble('dailyCalorieLimit', calorieLimit);
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

  void _showAboutDialog() {
    showAnimatedPopup(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text('About Us', style: TextStyle(color: Theme.of(context).primaryColor)),
        content: const Text(
          'Fittig is your ultimate fitness companion. Designed to track your daily progress, provide AI-integrated meal plans, and keep your workout streaks alive.\n\nKeep pushing your limits!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://doc-hosting.flycricket.io/fittig-privacy-policy/7dbb2cad-3705-40fd-b90c-f56b69c2fb8c/privacy');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy.')),
        );
      }
    }
  }

  Future<void> _launchSupportEmail() async {
    const supportEmail = 'fittigsupport@gmail.com';
    final gmailComposeUri = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$supportEmail',
    );
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Fittig Support',
      },
    );

    if (await canLaunchUrl(gmailComposeUri)) {
      await launchUrl(gmailComposeUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email composer.')),
      );
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
    _calorieController.dispose();
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
                showAnimatedPopup(
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

                      const SizedBox(height: 16),

                      _buildLabel('DAILY CALORIE LIMIT (KCAL)'),
                      TextFormField(
                        controller: _calorieController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
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

                      const SizedBox(height: 48),

                      // Info Section
                      if (_updateAvailable)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.system_update_alt_rounded,
                            color: primaryColor,
                          ),
                          title: const Text(
                            'Update available',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Tap to download latest fixes',
                            style: TextStyle(color: Colors.white54),
                          ),
                          trailing: _isUpdating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : TextButton(
                                  onPressed: _handleUpdateNow,
                                  child: Text(
                                    'Update Now',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                          onTap: _isUpdating ? null : _handleUpdateNow,
                        ),
                      if (_updateAvailable) const SizedBox(height: 8),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.info_outline, color: primaryColor),
                        title: const Text('About Us', style: TextStyle(color: Colors.white)),
                        onTap: _showAboutDialog,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
                        title: const Text('Privacy Protection', style: TextStyle(color: Colors.white)),
                        onTap: _launchPrivacyPolicy,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.email_outlined, color: primaryColor),
                        title: const Text('Customer Support', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('fittigsupport@gmail.com', style: TextStyle(color: Colors.white54)),
                        onTap: _launchSupportEmail,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          '© ${DateTime.now().year} Fittig. All rights reserved.',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
