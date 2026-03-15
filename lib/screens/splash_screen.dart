import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasUser = prefs.getString('userName') != null;

    if (mounted) {
      if (hasUser) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // F Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor, width: 8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 20,
                            left: 20,
                            right: 20,
                            child: Container(height: 15, color: primaryColor),
                          ),
                          Positioned(
                            top: 45,
                            left: 20,
                            right: 35,
                            child: Container(height: 15, color: primaryColor),
                          ),
                          Positioned(
                            top: 20,
                            left: 20,
                            bottom: 20,
                            child: Container(width: 15, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // FITTIG Title
                    Text(
                      'FITTIG',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    const Text(
                      'LEVEL UP YOUR LIFE',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        letterSpacing: 4.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: const [
                  Text(
                    'DEVELOPED BY',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Akhil Donish',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
