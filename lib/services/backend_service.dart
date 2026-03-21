import 'dart:convert';
import 'dart:typed_data'; // 🚀 Added this so it understands Uint8List!
import 'package:http/http.dart' as http;
import 'package:myapp/config/env.dart';
import 'package:myapp/services/appwrite_service.dart';

class BackendService {
  final String baseUrl = Env.backendApiUrl;
  final AppwriteService _appwriteService = AppwriteService(); 

  // --- Chat & Styling Engine ---
  Future<Map<String, dynamic>> sendChatQuery(
    String query, 
    String userId, 
    List<Map<String, String>> chatHistory, 
    String currentMemory,                  
    {bool isRetry = false, List<Map<String, dynamic>>? fetchedWardrobe}
  ) async {
    try {
      if (!isRetry) {
        print("💬 Sending message to AHVI (No wardrobe attached yet)...");
      }

      // 🚀 STRIP THE FAT: Remove the heavy image URLs before sending to FastAPI!
      final safeWardrobePayload = (fetchedWardrobe ?? []).map((item) {
        final copy = Map<String, dynamic>.from(item);
        copy.remove('image_url'); // Server only needs the text to think!
        return copy;
      }).toList();

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
          'user_profile': {},
          'wardrobe_items': safeWardrobePayload, 
          'wardrobe_attached': isRetry, 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🛑 THE PING-PONG INTERCEPTOR
        if (data['requires_wardrobe'] == true && !isRetry) {
           print("🛑 AHVI requested your wardrobe! Fetching from Appwrite...");
           final items = await _appwriteService.getWardrobeItems();
           
           print("✅ Fetched ${items.length} items. Sending them back to AHVI...");
           return sendChatQuery(query, userId, chatHistory, currentMemory, isRetry: true, fetchedWardrobe: items);
        }

        // 🚀 UI LOGIC PARSING
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
          cleanText = "I've prepared your custom Packing Menu! 🌴✨";
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

  // 🚀 FIXED: Now accepts Uint8List and sends a Multipart Request!
  Future<Map<String, dynamic>?> analyzeImage(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('$baseUrl/garment/analyze/'); 
      var request = http.MultipartRequest('POST', uri);
      
      // Attach the image bytes as a file
      request.files.add(http.MultipartFile.fromBytes(
        'image_file', 
        imageBytes,
        filename: 'upload.png',
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
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
}