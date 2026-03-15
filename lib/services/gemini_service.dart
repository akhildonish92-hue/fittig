import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Using dotenv to load the API key from the .env file instead of hardcoding
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
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
