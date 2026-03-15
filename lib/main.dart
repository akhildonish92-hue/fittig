import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/training_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/profile_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error initializing cameras: $e');
  }
  runApp(const FittigApp());
}

class FittigApp extends StatelessWidget {
  const FittigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FITTIG',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF000000,
        ), // Pitch black background
        primaryColor: const Color(0xFFEFFF00), // Bright Yellow
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEFFF00),
          secondary: Color(0xFFFDE047),
          surface: Color(0xFF141414), // Dark Grey for cards
        ),
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/training': (context) => const TrainingScreen(),
        '/timer': (context) => const TimerScreen(),
        '/streak': (context) => const StreakScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
