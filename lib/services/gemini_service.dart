import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Using an environment variable so the key isn't hardcoded in the source code
  // Compile with: flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );

  static Future<String> scanFood(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final prompt = TextPart(
        "Analyze this image of food. Identify the primary food item and provide a highly accurate rough estimate of total calories. Format strictly as 'Food Name: X kcal'. Do not include any formatting, markdown, or extra sentences.",
      );
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      return response.text?.trim() ?? "Could not identify food.";
    } catch (e) {
      return 'Error: $e';
    }
  }
}
