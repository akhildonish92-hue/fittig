import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layouts/main_layout.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  List<String> _streaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreaks();
  }

  Future<void> _loadStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streaks = prefs.getStringList('workoutStreaks') ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;
    final today = DateTime.now();

    return MainLayout(
      currentIndex: 1, // STATS tab
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'FITTIG',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 2.0,
            ),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Text(
                            'TOTAL WORKOUTS',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_streaks.length}',
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DAYS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    const Text(
                      'ACTIVITY CALENDAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: 30, // Show last 30 days
                        itemBuilder: (context, index) {
                          final day = today.subtract(
                            Duration(days: 29 - index),
                          );
                          final dayStr = day.toIso8601String().substring(0, 10);
                          final isTrained = _streaks.contains(dayStr);
                          final isToday = index == 29;

                          return Container(
                            decoration: BoxDecoration(
                              color: isTrained
                                  ? primaryColor
                                  : (isToday
                                        ? Colors.white24
                                        : const Color(0xFF141414)),
                              shape: BoxShape.circle,
                              border: isToday && !isTrained
                                  ? Border.all(color: primaryColor, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isTrained
                                      ? Colors.black
                                      : Colors.white54,
                                  fontWeight: isTrained || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
