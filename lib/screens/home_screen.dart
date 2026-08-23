import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../layouts/main_layout.dart';
import '../services/gemini_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/network_service.dart';
import 'meal_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _userBmi = 22.5;
  double _dailyCalorieLimit = 2000.0;
  double _dailyProteinLimit = 0.0;
  double _dailyFatLimit = 0.0;
  double _dailyCarbsLimit = 0.0;
  double _caloriesEaten = 0.0;
  double _proteinEaten = 0.0;
  double _fatEaten = 0.0;
  double _carbsEaten = 0.0;
  bool _isLoading = true;

  double _lastAddedCalories = 0.0;
  double _lastAddedProtein = 0.0;
  double _lastAddedFat = 0.0;
  double _lastAddedCarbs = 0.0;
  bool _canUndo = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('lastDate') ?? '';

    if (lastDate != todayStr) {
      await prefs.setDouble('caloriesEaten', 0.0);
      await prefs.setDouble('proteinEaten', 0.0);
      await prefs.setDouble('fatEaten', 0.0);
      await prefs.setDouble('carbsEaten', 0.0);
      await prefs.setString('lastDate', todayStr);
    }

    setState(() {
      _userBmi = prefs.getDouble('userBmi') ?? 22.5;
      _dailyCalorieLimit = prefs.getDouble('dailyCalorieLimit') ?? 2000.0;
      _dailyProteinLimit = prefs.getDouble('dailyProteinLimit') ?? (_dailyCalorieLimit * 0.30 / 4);
      _dailyFatLimit = prefs.getDouble('dailyFatLimit') ?? (_dailyCalorieLimit * 0.30 / 9);
      _dailyCarbsLimit = prefs.getDouble('dailyCarbsLimit') ?? (_dailyCalorieLimit * 0.40 / 4);
      _caloriesEaten = prefs.getDouble('caloriesEaten') ?? 0.0;
      _proteinEaten = prefs.getDouble('proteinEaten') ?? 0.0;
      _fatEaten = prefs.getDouble('fatEaten') ?? 0.0;
      _carbsEaten = prefs.getDouble('carbsEaten') ?? 0.0;
      _isLoading = false;
    });

    _updateNotificationState();
  }

  void _updateNotificationState() {
    if (!kIsWeb) {
      if (_caloriesEaten < _dailyCalorieLimit) {
        NotificationService().scheduleDailyReminder();
      } else {
        NotificationService().cancelReminder();
      }
    }
  }

  void _editDailyLimit() {
    final controller = TextEditingController(text: _dailyCalorieLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text('Edit Daily Limit', style: TextStyle(color: Theme.of(context).primaryColor)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g., 2000',
            hintStyle: TextStyle(color: Colors.white30),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final newLimit = double.tryParse(controller.text) ?? 2000.0;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('dailyCalorieLimit', newLimit);
              setState(() {
                _dailyCalorieLimit = newLimit;
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('SAVE', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void _openCalorieScanner() {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera found on this device.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalorieScannerSheet(
        onScanComplete: (data) async {
          await _applyIntakeUpdate(data);
        },
      ),
    );
  }

  Future<void> _showAddFoodOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Food',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openTypedFoodDialog();
                  },
                  icon: const Icon(Icons.edit_note, color: Colors.black),
                  label: const Text('Type Food Name'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openCalorieScanner();
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                  label: const Text('Scan Food'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTypedFoodDialog() async {
    final controller = TextEditingController();
    final foodInput = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(
          'Type Food',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g., 2 boiled eggs',
            hintStyle: TextStyle(color: Colors.white30),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              'ANALYZE',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );

    if (!mounted || foodInput == null || foodInput.isEmpty) return;

    if (!await NetworkService.checkAndWarn(context)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await GeminiService.analyzeFoodText(foodInput);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (result == null || result.isEmpty) {
      await _showScanError(
        GeminiService.lastScanError ?? 'Could not analyze this food.',
      );
      return;
    }

    final food = (result['food'] ?? foodInput).toString();
    final cal = _toDouble(result['calories']).toStringAsFixed(0);
    final protein = _toDouble(result['protein']).toStringAsFixed(1);
    final fat = _toDouble(result['fat']).toStringAsFixed(1);
    final carbs = _toDouble(result['carbs']).toStringAsFixed(1);

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Add to Daily Intake?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$food\n$cal kcal\n${protein}g P | ${fat}g F | ${carbs}g C',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'YES, ADD',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );

    if (shouldAdd == true) {
      await _applyIntakeUpdate(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added to daily intake.')),
      );
    }
  }

  Future<void> _applyIntakeUpdate(Map<String, dynamic> data) async {
    final cal = _toDouble(data['calories']);
    final protein = _toDouble(data['protein']);
    final fat = _toDouble(data['fat']);
    final carbs = _toDouble(data['carbs']);

    final newCal = _caloriesEaten + cal;
    final newProtein = _proteinEaten + protein;
    final newFat = _fatEaten + fat;
    final newCarbs = _carbsEaten + carbs;

    Future<void> updateStats() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('caloriesEaten', newCal);
      await prefs.setDouble('proteinEaten', newProtein);
      await prefs.setDouble('fatEaten', newFat);
      await prefs.setDouble('carbsEaten', newCarbs);

      if (!mounted) return;
      setState(() {
        _lastAddedCalories = cal;
        _lastAddedProtein = protein;
        _lastAddedFat = fat;
        _lastAddedCarbs = carbs;
        _canUndo = true;

        _caloriesEaten = newCal;
        _proteinEaten = newProtein;
        _fatEaten = newFat;
        _carbsEaten = newCarbs;
      });
      _updateNotificationState();
    }

    if (newCal > _dailyCalorieLimit) {
      final overage = newCal - _dailyCalorieLimit;
      final shouldLog = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: Text(
            'Calorie Limit Exceeded!',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          content: Text(
            'Logging this meal will put you ${overage.toStringAsFixed(0)} kcal over your daily limit. Do you still want to log it?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'LOG ANYWAY',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
      );

      if (shouldLog == true) {
        await updateStats();
      }
      return;
    }

    await updateStats();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final text = value?.toString() ?? '';
    final numeric = RegExp(r'-?\d+(\.\d+)?').firstMatch(text);
    return double.tryParse(numeric?.group(0) ?? '') ?? 0.0;
  }

  Future<void> _showScanError(String message) async {
    if (!mounted) return;
    if (GeminiService.isDailyLimitError(message)) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: Text(
            'Daily Scan Limit Reached',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          content: const Text(
            'Daily limit reached. Upgrade to Premium for unlimited scans.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _undoLastMeal() async {
    if (!_canUndo) return;

    final newCal = (_caloriesEaten - _lastAddedCalories).clamp(0.0, double.infinity);
    final newProtein = (_proteinEaten - _lastAddedProtein).clamp(0.0, double.infinity);
    final newFat = (_fatEaten - _lastAddedFat).clamp(0.0, double.infinity);
    final newCarbs = (_carbsEaten - _lastAddedCarbs).clamp(0.0, double.infinity);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('caloriesEaten', newCal);
    await prefs.setDouble('proteinEaten', newProtein);
    await prefs.setDouble('fatEaten', newFat);
    await prefs.setDouble('carbsEaten', newCarbs);

    setState(() {
      _caloriesEaten = newCal;
      _proteinEaten = newProtein;
      _fatEaten = newFat;
      _carbsEaten = newCarbs;
      _canUndo = false;
    });

    _updateNotificationState();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Last added meal undone.')),
      );
    }
  }

  Widget _buildDailyCaloriesSection(Color primaryColor) {
    final targetProtein = _dailyProteinLimit;
    final targetFat = _dailyFatLimit;
    final targetCarbs = _dailyCarbsLimit;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY INTAKE',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (_canUndo)
                    IconButton(
                      onPressed: _undoLastMeal,
                      icon: const Icon(Icons.undo, size: 26, color: Colors.orange),
                      tooltip: 'Undo last add',
                    ),
                  IconButton(
                    onPressed: _showAddFoodOptions,
                    icon: Icon(Icons.add_circle, size: 26, color: primaryColor),
                    tooltip: 'Add food',
                  ),
                  GestureDetector(
                    onTap: _editDailyLimit,
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'EDIT GOAL',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: (_caloriesEaten / _dailyCalorieLimit).clamp(0.0, 1.0),
                  strokeWidth: 16,
                  backgroundColor: const Color(0xFF222222),
                  color: primaryColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    _caloriesEaten.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '/ ${_dailyCalorieLimit.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroStat('PROTEIN', _proteinEaten, targetProtein, Colors.blueAccent),
              _buildMacroStat('FAT', _fatEaten, targetFat, Colors.redAccent),
              _buildMacroStat('CARBS', _carbsEaten, targetCarbs, Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, double eaten, double target, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: target > 0 ? (eaten / target).clamp(0.0, 1.0) : 0.0,
                strokeWidth: 6,
                backgroundColor: const Color(0xFF222222),
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${eaten.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '/ ${target.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 12, color: Colors.white30),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 24,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'F',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fittig',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: const [],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BMI CARD
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 32.0,
                      horizontal: 24,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR BMI STATUS',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: (_userBmi / 40.0).clamp(0.0, 1.0),
                                strokeWidth: 16,
                                backgroundColor: const Color(0xFF222222),
                                color: primaryColor,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  _userBmi.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  _getBmiStatus(_userBmi),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Ideal BMI: 18.5 - 24.9',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // DAILY CALORIES CARD
                  _buildDailyCaloriesSection(primaryColor),

                  const SizedBox(height: 40),

                  // AI Meal Planner section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'AI Integrated Meal Planner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MealPlannerScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu, color: Colors.black),
                        label: const Text(
                          'GENERATE MEAL PLAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100), // Space for fab
                ],
              ),
            ),

            // Floating Calorie Scanner
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                onPressed: _openCalorieScanner,
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                label: const Text('Calorie Scanner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Keeping the older mock AI scanner sheet
class CalorieScannerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onScanComplete;

  const CalorieScannerSheet({super.key, required this.onScanComplete});

  @override
  State<CalorieScannerSheet> createState() => _CalorieScannerSheetState();
}

class _CalorieScannerSheetState extends State<CalorieScannerSheet> {
  CameraController? _controller;
  bool _isScanning = false;
  String _scanResult = '';
  Map<String, dynamic>? _lastScannedData;

  Future<void> _showScanError(String message) async {
    if (!mounted) return;
    if (GeminiService.isDailyLimitError(message)) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: Text(
            'Daily Scan Limit Reached',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          content: const Text(
            'Daily limit reached. Upgrade to Premium for unlimited scans.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      _controller!
          .initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
          })
          .catchError((e) {
            debugPrint('Camera Error: $e');
          });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _simulateScan() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (!await NetworkService.checkAndWarn(context)) return;

    AdService.showRewardedAd(() async {
      setState(() {
        _isScanning = true;
        _scanResult = 'Capturing image...';
      });

      try {
        final XFile imageFile = await _controller!.takePicture();
        
        if (!mounted) return;
        
        final descController = TextEditingController();
        final String? optionalDetails = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            title: Text('Food Details (Optional)', style: TextStyle(color: Theme.of(context).primaryColor)),
            content: TextField(
              controller: descController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g., portion size, ingredients. Leave blank if unsure.',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, descController.text),
                child: Text('ANALYZE', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
        );

        if (optionalDetails == null) {
          if (mounted) {
            setState(() {
              _isScanning = false;
              _scanResult = '';
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _scanResult = 'Analyzing image...';
          });
        }

        final Map<String, dynamic>? result = await GeminiService.scanFood(imageFile, optionalDetails);

        if (mounted) {
          setState(() {
            _isScanning = false;
            if (result != null && result.isNotEmpty) {
              final food = result['food'] ?? 'Unknown';
              final cal = (result['calories'] ?? 0).toString();
              final protein = (result['protein'] ?? 0).toString();
              final fat = (result['fat'] ?? 0).toString();
              final carbs = (result['carbs'] ?? 0).toString();
              _scanResult = '$food: $cal kcal\n${protein}g P | ${fat}g F | ${carbs}g C';
              _lastScannedData = result;
            } else {
              _scanResult = GeminiService.lastScanError ??
                  'Could not parse nutritional data.';
              _lastScannedData = null;
            }
          });

          if (_lastScannedData != null) {
            _askToAddScannedFood();
          } else {
            await _showScanError(
              GeminiService.lastScanError ??
                  'Could not parse nutritional data.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _scanResult = 'Error: $e';
          });
        }
      }
    });
  }

  Future<void> _askToAddScannedFood() async {
    if (!mounted || _lastScannedData == null) return;
    final foodName = (_lastScannedData!['food'] ?? 'this meal').toString();
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Add to Daily Intake?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to add $foodName to your daily intake?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'NO',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'YES, ADD',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );

    if (shouldAdd == true && _lastScannedData != null) {
      widget.onScanComplete(_lastScannedData!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added to daily intake.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'AI Calorie Scanner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'Initializing camera...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (_scanResult.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _scanResult,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _simulateScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isScanning
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'SCAN MEAL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
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
