import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/network_service.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _dietController = TextEditingController();
  String _goal = 'Lose Weight';
  String _activity = 'Lightly Active';
  bool _isLoading = false;

  final List<String> _goals = ['Lose Weight', 'Maintain Weight', 'Build Muscle'];
  final List<String> _activities = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active'
  ];

  double _activityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'Sedentary':
        return 1.2;
      case 'Lightly Active':
        return 1.375;
      case 'Moderately Active':
        return 1.55;
      case 'Very Active':
        return 1.725;
      case 'Extra Active':
        return 1.9;
      default:
        return 1.375;
    }
  }

  Map<String, double> _calculateFallbackGoals(
    double weight,
    double height,
    String goal,
    String activityLevel,
  ) {
    // Use a practical maintenance formula when AI is unavailable.
    final baseCalories = (10 * weight) + (6.25 * height) - 100;
    final maintenanceCalories = baseCalories * _activityMultiplier(activityLevel);

    double calories = maintenanceCalories;
    if (goal == 'Lose Weight') {
      calories -= 450;
    } else if (goal == 'Build Muscle') {
      calories += 300;
    }

    final safeCalories = calories.clamp(1200, 4200).toDouble();
    final protein = (weight * 1.8).clamp(60, 260).toDouble();
    final fat = (safeCalories * 0.25 / 9).clamp(35, 130).toDouble();
    final carbs = ((safeCalories - (protein * 4) - (fat * 9)) / 4).clamp(80, 600).toDouble();

    return {
      'calories': safeCalories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }

  Future<void> _analyzeAndSave() async {
    if (!await NetworkService.checkAndWarn(context)) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final weight = prefs.getDouble('userWeight') ?? 70.0;
    final height = prefs.getDouble('userHeight') ?? 170.0;
    final bmi = prefs.getDouble('userBmi') ?? 22.5;

    final aiResult = await GeminiService.generateDailyGoals(
      weight, height, bmi, _goal, _activity, _dietController.text,
    );
    final result = aiResult ?? _calculateFallbackGoals(weight, height, _goal, _activity);

    if (!mounted) return;

    await prefs.setDouble('dailyCalorieLimit', result['calories']!.toDouble());
    await prefs.setDouble('dailyProteinLimit', result['protein']!.toDouble());
    await prefs.setDouble('dailyFatLimit', result['fat']!.toDouble());
    await prefs.setDouble('dailyCarbsLimit', result['carbs']!.toDouble());
    await prefs.setBool('surveyCompleted', true);

    if (mounted) {
      if (aiResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI unavailable right now. Used smart default goals.'),
          ),
        );
      }
      Navigator.pushReplacementNamed(context, '/home');
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
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AI Personalization',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tell us a bit about your lifestyle, and our AI will calculate your optimal calorie and macro goals.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _buildLabel('PRIMARY GOAL'),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                dropdownColor: const Color(0xFF141414),
                decoration: _inputDecoration(),
                items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _goal = val!),
              ),

              _buildLabel('ACTIVITY LEVEL'),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                dropdownColor: const Color(0xFF141414),
                decoration: _inputDecoration(),
                items: _activities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (val) => setState(() => _activity = val!),
              ),

              _buildLabel('DIETARY PREFERENCES (OPTIONAL)'),
              TextField(
                controller: _dietController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration().copyWith(
                  hintText: 'e.g., Vegan, Keto, No Nuts...',
                  hintStyle: const TextStyle(color: Colors.white30),
                ),
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                      )
                    : const Text(
                        'ANALYZE WITH AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
