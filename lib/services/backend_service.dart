import 'dart:convert';
import 'dart:typed_data'; // ðŸš€ Added this so it understands Uint8List!
import 'package:http/http.dart' as http;
import 'package:myapp/config/env.dart';

class BackendService {
  BackendService({this.authToken});

  final String baseUrl = Env.backendApiUrl;
  String? authToken;

  void setAuthToken(String? token) {
    authToken = (token ?? '').trim().isEmpty ? null : token!.trim();
  }

  Map<String, String> _authHeaders() {
    final headers = <String, String>{};
    final token = (authToken ?? '').trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> _jsonHeaders() {
    return <String, String>{
      'Content-Type': 'application/json',
      ..._authHeaders(),
    };
  }

  // --- Chat & Styling Engine ---
  Future<Map<String, dynamic>> sendChatQuery(
    String query,
    String userId,
    List<Map<String, String>> chatHistory,
    String currentMemory, {
    bool isRetry = false,
    List<Map<String, dynamic>>? fetchedWardrobe,
    Map<String, dynamic>? userProfile,
    List<Map<String, dynamic>>? wardrobeItems,
    String? moduleContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/text'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'messages': [
            ...chatHistory,
            {'role': 'user', 'content': query},
          ],
          'language': 'en',
          'current_memory': currentMemory,
          'user_id': userId,
          'user_profile': userProfile ?? const <String, dynamic>{},
          'wardrobe_items':
              wardrobeItems ?? fetchedWardrobe ?? const <Map<String, dynamic>>[],
          if (moduleContext != null && moduleContext.trim().isNotEmpty)
            'module_context': moduleContext.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Unexpected response format from backend');
        }
        final data = decoded;

        final dynamic rawMessage = data['message'];
        String rawText;
        if (rawMessage is Map<String, dynamic>) {
          rawText =
              rawMessage['content']?.toString() ??
              "I'm having trouble thinking right now.";
        } else if (rawMessage is String) {
          rawText = rawMessage;
        } else if (data['content'] is String) {
          rawText = data['content'] as String;
        } else {
          rawText = "I'm having trouble thinking right now.";
        }
        String cleanText = rawText;

        List<dynamic> extractedChips = data['chips'] ?? [];
        String? extractedBoardData =
            (data['board_ids'] != null &&
                data['board_ids'].toString().isNotEmpty)
            ? data['board_ids']
            : null;
        String? extractedPackData;
        String hiddenMenuText = "";

        RegExp chipsRegex = RegExp(r'\[CHIPS:\s*(.*?)\]');
        Match? chipsMatch = chipsRegex.firstMatch(cleanText);
        if (chipsMatch != null) {
          extractedChips = chipsMatch
              .group(1)!
              .split(',')
              .map((e) => e.trim())
              .toList();
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

        data['message'] = {'content': cleanText};
        data['chips'] = extractedChips;
        data['board_ids'] = extractedBoardData;
        data['pack_ids'] = extractedPackData;
        data['full_menu_text'] = hiddenMenuText;
        data['has_actions'] =
            (extractedBoardData != null || extractedPackData != null);

        return data;
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      print('Backend Error: $e');
      return {'error': 'Could not connect to AHVI brain. Error: $e'};
    }
  }
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  WARDROBE: VISION & BACKGROUND REMOVAL
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>?> removeBackgroundDetailed(String base64Image) async {
    try {
      const candidates = <String>[
        '/api/background/remove-bg',
        '/api/remove-bg',
      ];

      for (final path in candidates) {
        final response = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: _jsonHeaders(),
          body: jsonEncode({'image_base64': base64Image}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'image_base64': data['image_base64']?.toString(),
            'bg_removed': data['bg_removed'] == true,
            'fallback_reason': data['fallback_reason']?.toString(),
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> removeBackground(String base64Image) async {
    final info = await removeBackgroundDetailed(base64Image);
    return info?['image_base64']?.toString();
  }

  // ðŸš€ FIXED: Now converts Uint8List to Base64 and sends to the NEW JSON endpoint!
  Future<Map<String, dynamic>?> analyzeImage(Uint8List imageBytes) async {
    final base64String = base64Encode(imageBytes);
    return analyzeImageFromBase64(base64String);
  }

  Future<Map<String, dynamic>?> analyzeImageFromBase64(String base64String) async {
    try {
      const candidates = <String>[
        '/api/analyze-image',
        '/api/vision/analyze-image',
        '/api/vision/analyze',
        '/api/analyze',
      ];

      for (final path in candidates) {
        final response = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: _jsonHeaders(),
          body: jsonEncode({'image_base64': base64String}),
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      }

      print('Analyze API Failed on all known routes.');
      return null;
    } catch (e) {
      print('Garment Analysis Error: $e');
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
        headers: _jsonHeaders(),
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
      final response = await http.get(uri, headers: _authHeaders());
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
        headers: _jsonHeaders(),
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
        headers: _jsonHeaders(),
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

  Future<Map<String, dynamic>?> getTaskStatus(String taskId) async {
    final id = taskId.trim();
    if (id.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/$id'),
        headers: _authHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}




