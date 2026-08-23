import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../layouts/main_layout.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  String _trainingType = 'Workout';
  double _caloriesPerMinute = 5.0;

  bool _isSetupMode = true;
  bool _isRunning = false;
  int _totalSeconds = 300; // default 5 mins
  int _remainingSeconds = 300;
  Timer? _timer;
  DateTime? _targetEndTime;

  bool _isResting = false;
  int _restRemainingSeconds = 0;
  Timer? _restTimer;
  DateTime? _restTargetEndTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _trainingType = args;
      if (_trainingType.contains('Cardio')) {
        _caloriesPerMinute = 10.0;
      } else if (_trainingType.contains('Heavy')) {
        _caloriesPerMinute = 8.0;
      } else {
        _caloriesPerMinute = 5.0;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isRunning && _targetEndTime != null) {
        final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;
        setState(() {
          _remainingSeconds = remaining > 0 ? remaining : 0;
        });
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _handleWorkoutComplete();
        }
      }
      
      if (_isResting && _restTargetEndTime != null) {
        final remaining = _restTargetEndTime!.difference(DateTime.now()).inSeconds;
        setState(() {
          _restRemainingSeconds = remaining > 0 ? remaining : 0;
        });
        if (_restRemainingSeconds <= 0) {
          _restTimer?.cancel();
          setState(() => _isResting = false);
        }
      }
    }
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    if (_isResting) _stopRest();

    setState(() {
      _isRunning = true;
      _isSetupMode = false;
      _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetEndTime != null) {
        final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          setState(() {
            _remainingSeconds = remaining;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _remainingSeconds = 0;
            _isRunning = false;
          });
          _handleWorkoutComplete();
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _targetEndTime = null;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _isRunning = false;
      _isResting = false;
      _remainingSeconds = _totalSeconds;
      _targetEndTime = null;
      _restTargetEndTime = null;
    });
  }

  void _startRest() {
    if (_isSetupMode || _remainingSeconds <= 0 || _isResting) return;
    
    _pauseTimer();
    
    setState(() {
      _isResting = true;
      _restRemainingSeconds = 60;
      _restTargetEndTime = DateTime.now().add(const Duration(seconds: 60));
    });

    AdService.showInterstitialAd();
    
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTargetEndTime != null) {
        final remaining = _restTargetEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          setState(() {
            _restRemainingSeconds = remaining;
          });
        } else {
          _restTimer?.cancel();
          setState(() {
            _isResting = false;
            _restRemainingSeconds = 0;
          });
        }
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restRemainingSeconds = 0;
      _restTargetEndTime = null;
    });
  }

  void _showSetTimerDialog() {
    final controller = TextEditingController(
      text: (_totalSeconds / 60).floor().toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Set Timer (Minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 5;
              setState(() {
                _totalSeconds = val * 60;
                _remainingSeconds = _totalSeconds;
                _isSetupMode = true;
                _isRunning = false;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'SET',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWorkoutComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    List<String> streaks = prefs.getStringList('workoutStreaks') ?? [];
    if (!streaks.contains(dateStr)) {
      streaks.add(dateStr);
      await prefs.setStringList('workoutStreaks', streaks);
    }
    
    final String currentMonth = dateStr.substring(0, 7);
    final String calKey = 'calories_$currentMonth';
    double totalCaThisMonth = prefs.getDouble(calKey) ?? 0.0;
    await prefs.setDouble(calKey, totalCaThisMonth + _estimatedCaloriesBurned);

    AdService.showInterstitialAd();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(
          'Workout Complete!',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        content: Text(
          'Awesome job completing your $_trainingType! You burned ${_estimatedCaloriesBurned.toStringAsFixed(0)} kcal.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'DONE',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final m = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _estimatedCaloriesBurned {
    if (_totalSeconds == 0) return 0.0;
    final elapsedMinutes = (_totalSeconds - _remainingSeconds) / 60.0;
    return elapsedMinutes * _caloriesPerMinute;
  }

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      currentIndex: 2,
      child: Scaffold(
        appBar: AppBar(
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
          actions: const [], // Removed settings icon
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // Main Circular Timer
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: CircularProgressIndicator(
                          value: _totalSeconds == 0
                              ? 0
                              : _remainingSeconds / _totalSeconds,
                          strokeWidth: 8,
                          backgroundColor: Colors.white10,
                          color: primaryColor,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formattedTime,
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'REMAINING',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isResting) ...[
                Column(
                  children: [
                    const Text(
                      'RESTING',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_restRemainingSeconds / 60).floor().toString().padLeft(2, '0')}:${(_restRemainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ] else ...[
                const SizedBox(height: 48),
              ],

              // Estimated Burn
              const Text(
                'Estimated Burn',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _estimatedCaloriesBurned.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      'KCAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Set Timer Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SET TIMER (MM:SS)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_totalSeconds / 60).floor().toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _showSetTimerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SET',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Control Buttons
              Row(
                children: [
                  // Reset Button
                  Expanded(
                    child: InkWell(
                      onTap: _resetTimer,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.refresh, color: primaryColor, size: 28),
                            const SizedBox(height: 8),
                            const Text(
                              'RESET',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rest Button
                  Expanded(
                    child: InkWell(
                      onTap: _startRest,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.bedtime, color: Colors.blueAccent, size: 28),
                            const SizedBox(height: 8),
                            const Text(
                              'REST',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Play/Pause Button
                  Container(
                    width: 70, // Made slightly smaller to fit 4 buttons nicely
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          spreadRadius: 8,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                        customBorder: const CircleBorder(),
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Go Button (Stop/Complete functionality)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (!_isSetupMode) _handleWorkoutComplete();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.bolt, color: primaryColor, size: 28),
                            const SizedBox(height: 8),
                            const Text(
                              'GO',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
