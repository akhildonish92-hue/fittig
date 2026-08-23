import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/animated_popup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Select';

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      if (_gender == 'Select') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select gender')));
        return;
      }
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

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/survey');
      }
    }
  }

  void _showTermsDialog() {
    showAnimatedPopup(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text('Terms of Service', style: TextStyle(color: Theme.of(context).primaryColor)),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to Fittig!\n\n1. Acceptance of Terms\nBy continuing, you agree to be bound by these Terms of Service.\n\n2. User Responsibilities\nYou must provide accurate information for BMI calculation and personalized plans. The fitness and meal advice provided are for informational purposes only.\n\n3. Privacy & Data\nYour profile data is stored locally. We use the Gemini API securely to generate meal plans. We do not sell your personal data.\n\n4. Limitation of Liability\nFittig is a fitness tracking utility and not a certified medical or healthcare app. Please consult a doctor before starting any serious fitness regimen.',
            style: TextStyle(color: Colors.white70),
          ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'FITTIG',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Let's set up your profile to personalize your\nfitness journey.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('FULL NAME'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration().copyWith(
                    hintText: 'John Doe',
                    hintStyle: const TextStyle(color: Colors.white30),
                  ),
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
                            decoration: _inputDecoration().copyWith(
                              hintText: '70',
                              hintStyle: const TextStyle(color: Colors.white30),
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
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
                            decoration: _inputDecoration().copyWith(
                              hintText: '175',
                              hintStyle: const TextStyle(color: Colors.white30),
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('AGE'),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration().copyWith(
                              hintText: '25',
                              hintStyle: const TextStyle(color: Colors.white30),
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('GENDER'),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            dropdownColor: const Color(0xFF141414),
                            decoration: _inputDecoration(),
                            items: ['Select', 'Male', 'Female', 'Other']
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CALCULATE BMI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'By continuing, you agree to our ',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service.',
                          style: TextStyle(color: primaryColor),
                          recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                        ),
                      ],
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
