import 'dart:convert';
import 'dart:typed_data'; // 🚀 Added this so it understands Uint8List!
import 'package:http/http.dart' as http;
import 'package:myapp/config/env.dart';

class BackendService {
  final String baseUrl = Env.backendApiUrl;

  // --- Chat & Styling Engine ---
  Future<Map<String, dynamic>> sendChatQuery(
    String query,
    String userId,
    List<Map<String, String>> chatHistory,
    String currentMemory,
    {bool isRetry = false, List<Map<String, dynamic>>? fetchedWardrobe}
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            ...chatHistory,
            {'role': 'user', 'content': query}
          ],
          'language': 'en',
          'current_memory': currentMemory,
          'user_id': userId,
          'user_profile': {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String rawText = data['message']?['content'] ?? "I'm having trouble thinking right now.";
        String cleanText = rawText;

        List<dynamic> extractedChips = data['chips'] ?? [];
        String? extractedBoardData = (data['board_ids'] != null && data['board_ids'].toString().isNotEmpty)
            ? data['board_ids']
            : null;
        String? extractedPackData;
        String hiddenMenuText = "";

        RegExp chipsRegex = RegExp(r'\[CHIPS:\s*(.*?)\]');
        Match? chipsMatch = chipsRegex.firstMatch(cleanText);
        if (chipsMatch != null) {
          extractedChips = chipsMatch.group(1)!.split(',').map((e) => e.trim()).toList();
          cleanText = cleanText.replaceAll(chipsMatch.group(0)!, '').trim();
        }

        RegExp boardRegex = RegExp(r'\[STYLE_BOARD:\s*(.*?)\]');
        Match? boardMatch = boardRegex.firstMatch(cleanText);
        if (boardMatch != null) {
          extractedBoardData = boardMatch.group(1);
          cleanText = cleanText.replaceAll(boardMatch.group(0)!, '').trim();
        }

        RegExp packRegex = RegExp(r'\[PACK_LIST:\s*(.*?)\]');
        Match? packMatch = packRegex.firstMatch(cleanText);
        if (packMatch != null) {
          extractedPackData = packMatch.group(1);
          hiddenMenuText = cleanText.replaceAll(packMatch.group(0)!, '').trim();
          cleanText = "I've prepared your custom Packing Menu!";
        }

        data['message']['content'] = cleanText;
        data['chips'] = extractedChips;
        data['board_ids'] = extractedBoardData;
        data['pack_ids'] = extractedPackData;
        data['full_menu_text'] = hiddenMenuText;
        data['has_actions'] = (extractedBoardData != null || extractedPackData != null);

        return data;
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

  Future<String?> removeBackground(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/remove-bg'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['image_base64'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 🚀 FIXED: Now converts Uint8List to Base64 and sends to the NEW JSON endpoint!
  Future<Map<String, dynamic>?> analyzeImage(Uint8List imageBytes) async {
    try {
      // 1. Convert the image bytes to a Base64 string
      String base64String = base64Encode(imageBytes);

      // 2. Point to the NEW endpoint from your vision.py router
      final uri = Uri.parse('$baseUrl/api/analyze-image'); 
      
      // 3. Send a standard JSON POST request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': base64String
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        print("❌ Analyze API Failed: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print('❌ Garment Analysis Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendAnthropicMessages({
    required List<Map<String, dynamic>> messages,
    String? system,
    String model = 'claude-sonnet-4-20250514',
    int maxTokens = 380,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/anthropic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'max_tokens': maxTokens,
          if (system != null && system.isNotEmpty) 'system': system,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/weather?latitude=$latitude&longitude=$longitude',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/uploads/avatar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'image_base64': base64Encode(imageBytes),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['avatar_url']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> uploadWardrobeImages({
    required String fileId,
    required Uint8List rawImageBytes,
    required Uint8List maskedImageBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/uploads/wardrobe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_id': fileId,
          'raw_image_base64': base64Encode(rawImageBytes),
          'masked_image_base64': base64Encode(maskedImageBytes),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'raw_file_name': data['raw_file_name']?.toString() ?? '',
          'masked_file_name': data['masked_file_name']?.toString() ?? '',
          'raw_image_url': data['raw_image_url']?.toString() ?? '',
          'masked_image_url': data['masked_image_url']?.toString() ?? '',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}



