import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  // Hardcoded key to allow Shorebird patches to update the key dynamically (since Shorebird does not push asset changes)
  static const String _apiKey = 'AQ.Ab8RN6Iz9u3DzNwRDD2CHmF9xZeUiXhO-Ibtkj0s0_HGKE0OZg';
  static String? _lastScanError;
  static String? get lastScanError => _lastScanError;
  static const String dailyLimitMessage =
      'Daily limit reached. Upgrade to Premium for unlimited scans.';
  static const bool _isPremium = false;
  static const int _freeDailyScanLimit = 5;
  static const String _dailyScanCountKey = 'dailyScanCount';
  static const String _dailyScanDateKey = 'dailyScanDate';
  static const String _apiVersion = 'v1beta';
  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta';
  static const List<String> _modelFallbackOrder = [
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  static GenerativeModel _buildModel(String modelName) => GenerativeModel(
    model: modelName,
    apiKey: _apiKey,
    requestOptions: const RequestOptions(apiVersion: _apiVersion),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
  );

  static bool _isModelNotFoundError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('404') ||
        message.contains('not found') ||
        message.contains('not_found');
  }

  static bool _isUnrestrictedKeyError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unrestricted key') ||
        message.contains('service disruptions');
  }

  static Future<GenerateContentResponse> _generateContentWithModelFallback(
    List<Content> content,
  ) async {
    Object? lastError;

    for (var i = 0; i < _modelFallbackOrder.length; i++) {
      final modelName = _modelFallbackOrder[i];
      try {
        final model = _buildModel(modelName);
        print('Using Model: $modelName');
        return await model.generateContent(content);
      } catch (e) {
        lastError = e;
        if (_isUnrestrictedKeyError(e)) {
          rethrow;
        }
        final hasNextModel = i < _modelFallbackOrder.length - 1;
        if (_isModelNotFoundError(e) && hasNextModel) {
          continue;
        }
        rethrow;
      }
    }

    throw lastError ?? Exception('No available Gemini model.');
  }

  static bool isDailyLimitError(String? message) => message == dailyLimitMessage;

  static Future<bool> _canUseFreeScan() async {
    if (_isPremium) return true;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final savedDate = prefs.getString(_dailyScanDateKey);

    if (savedDate != today) {
      await prefs.setString(_dailyScanDateKey, today);
      await prefs.setInt(_dailyScanCountKey, 0);
    }

    final scanCount = prefs.getInt(_dailyScanCountKey) ?? 0;
    return scanCount < _freeDailyScanLimit;
  }

  static Future<void> _incrementScanCount() async {
    if (_isPremium) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final savedDate = prefs.getString(_dailyScanDateKey);
    var scanCount = prefs.getInt(_dailyScanCountKey) ?? 0;

    if (savedDate != today) {
      scanCount = 0;
    }

    await prefs.setString(_dailyScanDateKey, today);
    await prefs.setInt(_dailyScanCountKey, scanCount + 1);
  }

  static Future<Uint8List> _resizeImageTo720p(XFile imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return originalBytes;

    const int maxEdge = 1280;
    final int longestSide = max(decoded.width, decoded.height);
    if (longestSide <= maxEdge) return originalBytes;

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxEdge : null,
      height: decoded.height > decoded.width ? maxEdge : null,
      interpolation: img.Interpolation.average,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  static Future<Map<String, dynamic>?> scanFood(XFile imageFile, [String? optionalDetails]) async {
    _lastScanError = null;
    try {
      if (_apiKey.trim().isEmpty) {
        _lastScanError = 'Missing Gemini API key. Set GEMINI_API_KEY in assets/env.';
        return null;
      }

      if (!await _canUseFreeScan()) {
        _lastScanError = dailyLimitMessage;
        return null;
      }
      await _incrementScanCount();

      final bytes = await _resizeImageTo720p(imageFile);

      String promptString = 'Analyze this food image and estimate a standard serving nutrition. ';
      if (optionalDetails != null && optionalDetails.trim().isNotEmpty) {
        promptString = 'Analyze this food image along with these details: "$optionalDetails". Estimate a standard serving nutrition. ';
      }

      final prompt = TextPart(
        promptString +
        'Return JSON only with this exact schema: '
        '{"food":"Food name","calories":150,"protein":5.5,"fat":3.0,"carbs":25.0}. '
        'No markdown, no extra keys, numeric values only for calories/protein/fat/carbs.',
      );
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await _generateContentWithModelFallback([
        Content.multi([prompt, imagePart]),
      ]);

      final rawText = response.text?.trim() ?? '';
      final parsed = _extractAndNormalizeNutrition(rawText);
      if (parsed == null) {
        _lastScanError = 'AI response could not be parsed. Please try again.';
      }
      return parsed;
    } catch (e) {
      if (_isUnrestrictedKeyError(e)) {
        _lastScanError = 'Your Gemini API key is unrestricted and blocked by Google. '
            'Please restrict your key in the Google Cloud Console (APIs & Services > Credentials) '
            'to "Generative Language API", or create a restricted key in Google AI Studio.';
      } else {
        _lastScanError = 'Scan failed: $e';
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyzeFoodText(String foodDescription) async {
    _lastScanError = null;
    try {
      if (_apiKey.trim().isEmpty) {
        _lastScanError = 'Missing Gemini API key. Set GEMINI_API_KEY in assets/env.';
        return null;
      }

      if (!await _canUseFreeScan()) {
        _lastScanError = dailyLimitMessage;
        return null;
      }
      await _incrementScanCount();

      final promptText =
          'Estimate nutrition for this food: "$foodDescription". '
          'Assume one realistic standard serving unless quantity is mentioned. '
          'Return JSON only with this exact schema: '
          '{"food":"Food name","calories":150,"protein":5.5,"fat":3.0,"carbs":25.0}. '
          'No markdown, no extra keys, numeric values only for calories/protein/fat/carbs.';

      final response = await _generateContentWithModelFallback([
        Content.text(promptText),
      ]);

      final rawText = response.text?.trim() ?? '';
      final parsed = _extractAndNormalizeNutrition(rawText);
      if (parsed == null) {
        _lastScanError = 'AI response could not be parsed. Please try again.';
      }
      return parsed;
    } catch (e) {
      if (_isUnrestrictedKeyError(e)) {
        _lastScanError = 'Your Gemini API key is unrestricted and blocked by Google. '
            'Please restrict your key in the Google Cloud Console (APIs & Services > Credentials) '
            'to "Generative Language API", or create a restricted key in Google AI Studio.';
      } else {
        _lastScanError = 'Food analysis failed: $e';
      }
      return null;
    }
  }

  static Map<String, dynamic>? _extractAndNormalizeNutrition(String text) {
    if (text.isEmpty) return null;

    final cleanText =
        text.replaceAll('```json', '').replaceAll('```', '').trim();
    final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanText);
    final jsonText = objectMatch?.group(0) ?? cleanText;

    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) return null;

    final food = (decoded['food'] ?? '').toString().trim();
    if (food.isEmpty) return null;

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      final numeric = RegExp(r'-?\d+(\.\d+)?').firstMatch(value.toString());
      return double.tryParse(numeric?.group(0) ?? '') ?? 0.0;
    }

    return {
      'food': food,
      'calories': toDouble(decoded['calories']),
      'protein': toDouble(decoded['protein']),
      'fat': toDouble(decoded['fat']),
      'carbs': toDouble(decoded['carbs']),
    };
  }

  static Future<List<Map<String, dynamic>>?> generateMealPlan(double bmi, String dietaryPreferences) async {
    try {
      final promptText = 
        "You are an expert nutritionist. Generate a 1-day meal plan (Breakfast, Lunch, Dinner) for a person with a BMI of ${bmi.toStringAsFixed(1)}. Dietary preferences: ${dietaryPreferences.isEmpty ? 'None' : dietaryPreferences}. Ensure the meals have sufficient nutrients. \nReturn JSON only with this exact schema:\n[\n  {\"type\": \"Breakfast\", \"name\": \"Meal Name\", \"details\": \"400 kcal | 20g Protein\"},\n  {\"type\": \"Lunch\", \"name\": \"...\", \"details\": \"...\"},\n  {\"type\": \"Dinner\", \"name\": \"...\", \"details\": \"...\"}\n]\nNo markdown, no extra keys.";

      final response = await _generateContentWithModelFallback([
        Content.text(promptText),
      ]);

      final cleanText = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
      final listMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleanText);
      if (listMatch != null) {
        final decoded = jsonDecode(listMatch.group(0)!);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded.map((e) => Map<String, dynamic>.from(e)));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRecipeForMeal(String mealName) async {
    try {
      final promptText = "You are an expert chef. Provide a simple, healthy recipe for '$mealName'. Include a short list of ingredients and concise step-by-step instructions. \nReturn JSON only with this exact schema:\n{\n  \"title\": \"Recipe Name\",\n  \"ingredients\": [\"1 cup oats\", \"1/2 cup milk\"],\n  \"instructions\": [\"Boil milk\", \"Add oats\"]\n}\nNo markdown, no extra keys.";

      final response = await _generateContentWithModelFallback([
        Content.text(promptText),
      ]);

      final cleanText = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanText);
      if (objectMatch != null) {
        final decoded = jsonDecode(objectMatch.group(0)!);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generateDailyGoals(
      double weight, double height, double bmi, String goal, String activityLevel, String diet) async {
    try {
      final promptText =
          "You are an expert nutritionist. A user has provided their details: "
          "Weight: $weight kg, Height: $height cm, BMI: ${bmi.toStringAsFixed(1)}. "
          "Their main fitness goal is: '$goal'. "
          "Their activity level is: '$activityLevel'. "
          "Dietary preferences: '${diet.isEmpty ? 'None' : diet}'. "
          "Calculate their optimal daily calorie limit, and daily protein, fat, and carbs limits (in grams). "
          "\nReturn JSON only with this exact schema:\n"
          "{\n"
          "  \"calories\": 2200.0,\n"
          "  \"protein\": 160.0,\n"
          "  \"fat\": 70.0,\n"
          "  \"carbs\": 220.0\n"
          "}\n"
          "No markdown, no extra keys.";

      final response = await _generateContentWithModelFallback([
        Content.text(promptText),
      ]);

      final cleanText = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanText);
      if (objectMatch != null) {
        final decoded = jsonDecode(objectMatch.group(0)!);
        if (decoded is Map) {
          double toDouble(dynamic value) {
            if (value is num) return value.toDouble();
            final numeric = RegExp(r'-?\d+(\.\d+)?').firstMatch(value.toString());
            return double.tryParse(numeric?.group(0) ?? '') ?? 0.0;
          }
          return {
            'calories': toDouble(decoded['calories']),
            'protein': toDouble(decoded['protein']),
            'fat': toDouble(decoded['fat']),
            'carbs': toDouble(decoded['carbs']),
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
