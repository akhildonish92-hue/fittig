import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      currentIndex: 2, // ACTIVITY tab
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
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            const Text(
              'Choose your training session',
              style: TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildTrainingCard(
              context,
              'Easy Weight\nTraining',
              'Focus on form and high reps',
              Icons.horizontal_rule,
              primaryColor,
            ),
            const SizedBox(height: 24),
            _buildTrainingCard(
              context,
              'Heavy Weight\nTraining',
              'Strength focused, low rep sets',
              Icons.sports_martial_arts,
              primaryColor,
            ),
            const SizedBox(height: 24),
            _buildTrainingCard(
              context,
              'Cardio Workouts',
              'Endurance and high intensity',
              Icons.bolt,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/timer',
              arguments: title.replaceAll('\n', ' '),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 24.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
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
