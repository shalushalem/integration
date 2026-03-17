import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/config/env.dart';

class BackendService {
  final String baseUrl = Env.backendApiUrl;

  // --- Chat & Styling Engine ---
  Future<Map<String, dynamic>> sendChatQuery(String query, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/text'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': query}
          ],
          'language': 'en',
          'current_memory': '', 
          'user_profile': {},
          'wardrobe_items': [], 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      print('Backend Error: $e');
      return {'error': 'Could not connect to AHVI brain. Error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  WARDROBE: VISION & BACKGROUND REMOVAL
  // ─────────────────────────────────────────────────────────────────────────────

  /// 1. Removes the background of the garment using RMBG-2.0
  Future<String?> removeBackground(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/remove-bg'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['image_base64']; // Returns the new transparent image as Base64
      } else {
        print('BG Removal failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BG Removal Exception: $e');
      return null;
    }
  }

  /// 2. Analyzes the transparent garment using Llama 3.2 Vision & OpenCV
  Future<Map<String, dynamic>?> analyzeImage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
        // Returns: {name, category, sub_category, occasions, color_code, pattern}
      } else {
        print('Vision Analysis failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Vision Analysis Exception: $e');
      return null;
    }
  }
}