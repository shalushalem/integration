import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // ðŸš€ Added this so it understands Uint8List!
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/config/env.dart';

typedef TokenRefresher = Future<String?> Function();

class BackendUploadException implements Exception {
  const BackendUploadException({
    required this.message,
    this.statusCode,
    this.detail,
    this.rawBody,
  });

  final String message;
  final int? statusCode;
  final dynamic detail;
  final String? rawBody;

  @override
  String toString() =>
      'BackendUploadException(status=$statusCode, message=$message)';
}

class BackendAnalyzeException implements Exception {
  const BackendAnalyzeException({
    required this.message,
    this.statusCode,
    this.rawBody,
  });

  final String message;
  final int? statusCode;
  final String? rawBody;

  @override
  String toString() =>
      'BackendAnalyzeException(status=$statusCode, message=$message)';
}

Map<String, dynamic> _encodeWardrobeUploadPayload(Map<String, dynamic> params) {
  final fileId = (params['file_id'] ?? '').toString();
  final raw = params['raw'] as Uint8List? ?? Uint8List(0);
  final masked = params['masked'] as Uint8List? ?? Uint8List(0);
  return <String, dynamic>{
    'file_id': fileId,
    'raw_image_base64': base64Encode(raw),
    'masked_image_base64': base64Encode(masked),
  };
}

class BackendService {
  BackendService({this.authToken, this.refreshAuthToken});

  final String baseUrl = Env.backendApiUrl;
  final String _dataBasePath = '/api/data';
  static const int _maxUploadImageBytes = 8 * 1024 * 1024;
  static const int _maxAnalyzeImageBytes = 4 * 1024 * 1024;
  String? authToken;
  final TokenRefresher? refreshAuthToken;

  static int get maxImageBytes => _maxUploadImageBytes;
  static int get maxAnalyzeImageBytes => _maxAnalyzeImageBytes;

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

  Future<http.Response> _postJsonWithAuthRetry(
    String path,
    Map<String, dynamic> body,
    {Duration timeout = const Duration(seconds: 30)}
  ) async {
    Future<http.Response> doPost(Map<String, String> headers) {
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(timeout);
    }

    var response = await doPost(_jsonHeaders());
    if (response.statusCode == 401 && refreshAuthToken != null) {
      final refreshed = (await refreshAuthToken!())?.trim() ?? '';
      if (refreshed.isNotEmpty) {
        setAuthToken(refreshed);
        response = await doPost(_jsonHeaders());
      }
    }
    return response;
  }

  Future<http.Response> _getWithAuthRetry(String path) async {
    Future<http.Response> doGet(Map<String, String> headers) {
      return http.get(Uri.parse('$baseUrl$path'), headers: headers);
    }

    var response = await doGet(_authHeaders());
    if (response.statusCode == 401 && refreshAuthToken != null) {
      final refreshed = (await refreshAuthToken!())?.trim() ?? '';
      if (refreshed.isNotEmpty) {
        setAuthToken(refreshed);
        response = await doGet(_authHeaders());
      }
    }
    return response;
  }

  Future<http.Response> _patchJsonWithAuthRetry(
    String path,
    Map<String, dynamic> body,
  ) async {
    Future<http.Response> doPatch(Map<String, String> headers) {
      return http.patch(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    var response = await doPatch(_jsonHeaders());
    if (response.statusCode == 401 && refreshAuthToken != null) {
      final refreshed = (await refreshAuthToken!())?.trim() ?? '';
      if (refreshed.isNotEmpty) {
        setAuthToken(refreshed);
        response = await doPatch(_jsonHeaders());
      }
    }
    return response;
  }

  Future<http.Response> _deleteJsonWithAuthRetry(
    String path,
    Map<String, dynamic> body,
  ) async {
    Future<http.Response> doDelete(Map<String, String> headers) async {
      final req = http.Request('DELETE', Uri.parse('$baseUrl$path'))
        ..headers.addAll(headers)
        ..body = jsonEncode(body);
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    var response = await doDelete(_jsonHeaders());
    if (response.statusCode == 401 && refreshAuthToken != null) {
      final refreshed = (await refreshAuthToken!())?.trim() ?? '';
      if (refreshed.isNotEmpty) {
        setAuthToken(refreshed);
        response = await doDelete(_jsonHeaders());
      }
    }
    return response;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const <String>[];
      if (text.contains(',')) {
        return text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[text];
    }
    return const <String>[];
  }

  List<Map<String, String>> _normalizeChatHistory(
    List<Map<String, String>> chatHistory,
  ) {
    final normalized = <Map<String, String>>[];
    for (final item in chatHistory) {
      final role = (item['role'] ?? '').trim().toLowerCase();
      final content = (item['content'] ?? '').trim();
      if (content.isEmpty) continue;
      if (role != 'user' && role != 'assistant' && role != 'system') continue;
      normalized.add({'role': role, 'content': content});
    }
    return normalized;
  }

  Map<String, dynamic> _buildCurrentMemoryPayload({
    required String currentMemory,
    required List<Map<String, String>> history,
  }) {
    final rawMemory = currentMemory.trim();
    final payload = <String, dynamic>{};

    if (rawMemory.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMemory);
        if (decoded is Map<String, dynamic>) {
          payload.addAll(decoded);
        } else if (decoded is Map) {
          payload.addAll(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        } else {
          payload['summary'] = rawMemory;
        }
      } catch (_) {
        payload['summary'] = rawMemory;
      }
    }

    payload['history'] = history;
    return payload;
  }

  String? _asOptionalActionString(dynamic value) {
    if (value is String) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }
    if (value is List) {
      final joined = value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .join(',');
      return joined.isEmpty ? null : joined;
    }
    return null;
  }

  bool _shouldTryNextCandidate(int statusCode) {
    // Probe route aliases for not-found and transient upstream failures.
    return statusCode == 404 ||
        statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  bool _isUploadPayloadSafe(Uint8List bytes) {
    return bytes.lengthInBytes <= _maxUploadImageBytes;
  }

  bool _isAnalyzePayloadSafe(Uint8List bytes) {
    return bytes.lengthInBytes <= _maxAnalyzeImageBytes;
  }

  Map<String, dynamic> _tryDecodeJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  BackendUploadException _wardrobeUploadHttpError(http.Response response) {
    final body = _tryDecodeJsonMap(response.body);
    final detail = body['detail'];
    String message = 'Wardrobe upload failed (${response.statusCode}).';
    if (detail is String && detail.trim().isNotEmpty) {
      message = detail.trim();
    } else if (detail is Map) {
      final mapped = detail.map((k, v) => MapEntry(k.toString(), v));
      final nestedMessage = (mapped['message'] ?? '').toString().trim();
      if (nestedMessage.isNotEmpty) {
        message = nestedMessage;
      }
    }
    return BackendUploadException(
      statusCode: response.statusCode,
      message: message,
      detail: detail,
      rawBody: response.body,
    );
  }

  Future<void> _ensureToken() async {
    if ((authToken ?? '').trim().isNotEmpty) return;
    if (refreshAuthToken == null) return;
    final refreshed = (await refreshAuthToken!())?.trim() ?? '';
    if (refreshed.isNotEmpty) {
      setAuthToken(refreshed);
    }
  }

  Map<String, dynamic> _flattenDoc(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((k, v) {
      if (!k.startsWith(r'$')) out[k] = v;
    });
    if (raw.containsKey(r'$id')) out[r'$id'] = raw[r'$id'];
    if (raw.containsKey('id')) out['id'] = raw['id'];
    return out;
  }

  Future<List<Map<String, dynamic>>> _dataList(
    String resource, {
    String? userId,
    String? occasion,
    int limit = 200,
  }) async {
    await _ensureToken();
    final query = <String, String>{'limit': '$limit'};
    if ((userId ?? '').trim().isNotEmpty) query['user_id'] = userId!.trim();
    if ((occasion ?? '').trim().isNotEmpty) query['occasion'] = occasion!.trim();
    final uri = Uri(
      path: '$_dataBasePath/$resource',
      queryParameters: query,
    ).toString();
    final response = await _getWithAuthRetry(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch $resource: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return const <Map<String, dynamic>>[];
    final docs = body['documents'];
    if (docs is! List) return const <Map<String, dynamic>>[];
    return docs
        .whereType<Map>()
        .map((e) => _flattenDoc(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> _dataCreate(
    String resource,
    Map<String, dynamic> data, {
    String? userId,
  }) async {
    await _ensureToken();
    final response = await _postJsonWithAuthRetry(_dataBasePath, {
      'resource': resource,
      'data': data,
      if ((userId ?? '').trim().isNotEmpty) 'user_id': userId!.trim(),
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to create $resource: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return const <String, dynamic>{};
    final doc = body['document'];
    if (doc is! Map<String, dynamic>) return const <String, dynamic>{};
    return _flattenDoc(doc);
  }

  Future<Map<String, dynamic>> _dataUpdate(
    String resource,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _ensureToken();
    final id = documentId.trim();
    if (id.isEmpty) throw Exception('documentId is required');
    final response = await _patchJsonWithAuthRetry('$_dataBasePath/$id', {
      'resource': resource,
      'data': data,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to update $resource: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return const <String, dynamic>{};
    final doc = body['document'];
    if (doc is! Map<String, dynamic>) return const <String, dynamic>{};
    return _flattenDoc(doc);
  }

  Future<void> _dataDelete(String resource, String documentId) async {
    await _ensureToken();
    final id = documentId.trim();
    if (id.isEmpty) return;
    final response = await _deleteJsonWithAuthRetry(_dataBasePath, {
      'resource': resource,
      'document_id': id,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to delete $resource: ${response.statusCode}');
    }
  }

  Future<String> resolveUserId([String fallback = 'demo_user']) async {
    await _ensureToken();
    final token = (authToken ?? '').trim();
    if (token.isEmpty) return fallback;
    final parts = token.split('.');
    if (parts.length < 2) return fallback;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is Map<String, dynamic>) {
        final sub = (payload['sub'] ?? '').toString().trim();
        if (sub.isNotEmpty) return sub;
      }
    } catch (_) {}
    return fallback;
  }

  Future<List<Map<String, dynamic>>> getSavedBoards({
    required String userId,
    String? occasion,
  }) async {
    return _dataList('saved_boards', userId: userId, occasion: occasion);
  }

  Future<List<Map<String, dynamic>>> getLifeBoards({
    required String userId,
  }) async {
    final docs = await _dataList('saved_boards', userId: userId);
    return docs.where((doc) {
      final boardType = (doc['boardType'] ?? doc['board_type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return boardType.isNotEmpty;
    }).toList();
  }

  Future<void> deleteSavedBoard(String id) async {
    await _dataDelete('saved_boards', id);
  }

  Future<List<Map<String, dynamic>>> getBills({required String userId}) async {
    return _dataList('bills', userId: userId);
  }

  Future<List<Map<String, dynamic>>> getCoupons({required String userId}) async {
    return _dataList('coupons', userId: userId);
  }

  Future<Map<String, dynamic>> createBill(
    Map<String, dynamic> data, {
    required String userId,
  }) async {
    return _dataCreate('bills', data, userId: userId);
  }

  Future<Map<String, dynamic>> createCoupon(
    Map<String, dynamic> data, {
    required String userId,
  }) async {
    return _dataCreate('coupons', data, userId: userId);
  }

  Future<void> deleteBill(String id) async {
    await _dataDelete('bills', id);
  }

  Future<void> deleteCoupon(String id) async {
    await _dataDelete('coupons', id);
  }

  Future<List<Map<String, dynamic>>> getMeds({required String userId}) async {
    return _dataList('meds', userId: userId);
  }

  Future<List<Map<String, dynamic>>> getMedLogs({required String userId}) async {
    return _dataList('med_logs', userId: userId);
  }

  Future<Map<String, dynamic>> createMed(
    Map<String, dynamic> data, {
    required String userId,
  }) async {
    return _dataCreate('meds', data, userId: userId);
  }

  Future<Map<String, dynamic>> updateMed(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _dataUpdate('meds', id, data);
  }

  Future<void> deleteMed(String id) async {
    await _dataDelete('meds', id);
  }

  Future<Map<String, dynamic>> createMedLog(
    Map<String, dynamic> data, {
    required String userId,
  }) async {
    return _dataCreate('med_logs', data, userId: userId);
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
    String? threadId,
  }) async {
    try {
      final trimmedQuery = query.trim();
      final normalizedHistory = _normalizeChatHistory(chatHistory);
      final hasLatestUserTurn = normalizedHistory.isNotEmpty &&
          normalizedHistory.last['role'] == 'user' &&
          normalizedHistory.last['content'] == trimmedQuery;
      final messagesPayload = hasLatestUserTurn
          ? normalizedHistory
          : <Map<String, String>>[
              ...normalizedHistory,
              {'role': 'user', 'content': trimmedQuery},
            ];
      final contextHistory = messagesPayload.length > 1
          ? messagesPayload.sublist(0, messagesPayload.length - 1)
          : <Map<String, String>>[];
      final currentMemoryPayload = _buildCurrentMemoryPayload(
        currentMemory: currentMemory,
        history: contextHistory,
      );

      final response = await _postJsonWithAuthRetry('/api/text', {
        'messages': messagesPayload,
        'language': 'en',
        'current_memory': currentMemoryPayload,
        'user_id': userId,
        'user_profile': userProfile ?? const <String, dynamic>{},
        'wardrobe_items':
            wardrobeItems ?? fetchedWardrobe ?? const <Map<String, dynamic>>[],
        if (moduleContext != null && moduleContext.trim().isNotEmpty)
          'module_context': moduleContext.trim(),
        if (threadId != null && threadId.trim().isNotEmpty)
          'thread_id': threadId.trim(),
      });

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

        List<String> extractedChips = _toStringList(data['chips']);
        String? extractedBoardData = _asOptionalActionString(data['board_ids']);
        String? extractedPackData;
        String hiddenMenuText = "";

        RegExp chipsRegex = RegExp(r'\[CHIPS:\s*(.*?)\]');
        Match? chipsMatch = chipsRegex.firstMatch(cleanText);
        if (chipsMatch != null) {
          extractedChips = chipsMatch
              .group(1)!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          cleanText = cleanText.replaceAll(chipsRegex, '').trim();
        }

        RegExp boardRegex = RegExp(r'\[STYLE_BOARD:\s*(.*?)\]');
        Match? boardMatch = boardRegex.firstMatch(cleanText);
        if (boardMatch != null) {
          extractedBoardData = _asOptionalActionString(boardMatch.group(1));
          cleanText = cleanText.replaceAll(boardRegex, '').trim();
        }

        RegExp packRegex = RegExp(r'\[PACK_LIST:\s*(.*?)\]');
        Match? packMatch = packRegex.firstMatch(cleanText);
        if (packMatch != null) {
          extractedPackData = _asOptionalActionString(packMatch.group(1));
          cleanText = cleanText.replaceAll(packRegex, '').trim();
          hiddenMenuText = cleanText;
        }

        data['message'] = {'content': cleanText};
        data['chips'] = List<String>.from(extractedChips);
        data['board_ids'] = extractedBoardData;
        data['pack_ids'] = extractedPackData;
        data['full_menu_text'] = hiddenMenuText;
        data['has_actions'] =
            (extractedBoardData != null || extractedPackData != null);
        data['updated_memory'] = data['updated_memory'] ??
            currentMemoryPayload['summary']?.toString() ??
            currentMemory;
        data['thread_id'] = data['thread_id']?.toString() ??
            (threadId != null && threadId.trim().isNotEmpty ? threadId.trim() : null);

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
        final response = await _postJsonWithAuthRetry(path, {
          'image_base64': base64Image,
        });
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'image_base64': data['image_base64']?.toString(),
            'bg_removed': data['bg_removed'] == true,
            'fallback_reason': data['fallback_reason']?.toString(),
          };
        }
        if (!_shouldTryNextCandidate(response.statusCode)) {
          break;
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
  Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
    if (!_isAnalyzePayloadSafe(imageBytes)) {
      return {
        'success': false,
        'error': 'Image is too large. Please compress it below 4MB.',
      };
    }
    final base64String = base64Encode(imageBytes);
    return analyzeImageFromBase64(base64String);
  }

  Future<Map<String, dynamic>> analyzeImageFromBase64(String base64String) async {
    int? lastStatusCode;
    String? lastError;
    try {
      const candidates = <String>[
        '/api/analyze-image',
        '/api/vision/analyze-image',
        '/api/vision/analyze',
        '/api/analyze',
      ];

      for (final path in candidates) {
        final response = await _postJsonWithAuthRetry(path, {
          'image_base64': base64String,
        }, timeout: const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (!decoded.containsKey('success')) {
              return {'success': true, ...decoded};
            }
            return decoded;
          }
          return {'success': false, 'error': 'Invalid server response.'};
        }
        lastStatusCode = response.statusCode;
        final body = _tryDecodeJsonMap(response.body);

        if (response.statusCode == 422) {
          final detail = body['detail'];
          final message = (detail is String && detail.trim().isNotEmpty)
              ? detail.trim()
              : 'Invalid image.';
          return {'success': false, 'error': message, 'status_code': 422};
        }

        if (response.statusCode == 413) {
          final detail = body['detail'];
          final message = (detail is String && detail.trim().isNotEmpty)
              ? detail.trim()
              : 'Image is too large.';
          return {'success': false, 'error': message, 'status_code': 413};
        }

        lastError = 'Server error: ${response.statusCode}';
        print('Analyze API failed on $path: ${response.statusCode}');
        if (!_shouldTryNextCandidate(response.statusCode)) {
          break;
        }
      }

      return {
        'success': false,
        'error': lastError ??
            (lastStatusCode == null
                ? 'Analyze API failed on all known routes.'
                : 'Server error: $lastStatusCode'),
      };
    } on TimeoutException catch (e) {
      return {'success': false, 'error': 'Network timeout or error: $e'};
    } catch (e) {
      return {'success': false, 'error': 'Network timeout or error: $e'};
    }
  }

  Future<Map<String, dynamic>?> sendAnthropicMessages({
    required List<Map<String, dynamic>> messages,
    String? system,
    String model = 'claude-sonnet-4-20250514',
    int maxTokens = 380,
  }) async {
    try {
      final response = await _postJsonWithAuthRetry('/api/anthropic', {
        'model': model,
        'max_tokens': maxTokens,
        if (system != null && system.isNotEmpty) 'system': system,
        'messages': messages,
      });

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
      final response = await _getWithAuthRetry(
        '/api/weather?latitude=$latitude&longitude=$longitude',
      );
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
      if (!_isUploadPayloadSafe(imageBytes)) {
        print(
          'Avatar upload skipped: payload too large (${imageBytes.lengthInBytes} bytes).',
        );
        return null;
      }
      final response = await _postJsonWithAuthRetry('/api/uploads/avatar', {
        'user_id': userId,
        'image_base64': base64Encode(imageBytes),
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['avatar_url']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> uploadWardrobeImages({
    required String fileId,
    required Uint8List rawImageBytes,
    required Uint8List maskedImageBytes,
  }) async {
    try {
      if (!_isUploadPayloadSafe(rawImageBytes) ||
          !_isUploadPayloadSafe(maskedImageBytes)) {
        throw BackendUploadException(
          statusCode: 413,
          message:
              'Selected image is too large to upload. Please try a smaller photo.',
          detail: <String, dynamic>{
            'raw_bytes': rawImageBytes.lengthInBytes,
            'masked_bytes': maskedImageBytes.lengthInBytes,
            'max_bytes_per_image': _maxUploadImageBytes,
          },
        );
      }
      final payload = await compute(_encodeWardrobeUploadPayload, <String, dynamic>{
        'file_id': fileId,
        'raw': rawImageBytes,
        'masked': maskedImageBytes,
      });
      final response = await _postJsonWithAuthRetry('/api/uploads/wardrobe', payload);
      if (response.statusCode != 200) {
        throw _wardrobeUploadHttpError(response);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'raw_file_name': data['raw_file_name']?.toString() ?? '',
        'masked_file_name': data['masked_file_name']?.toString() ?? '',
        'raw_image_url': data['raw_image_url']?.toString() ?? '',
        'masked_image_url': data['masked_image_url']?.toString() ?? '',
      };
    } on BackendUploadException {
      rethrow;
    } catch (e) {
      throw BackendUploadException(
        message: 'Wardrobe upload failed due to an unexpected error.',
        rawBody: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> getTaskStatus(String taskId) async {
    final id = taskId.trim();
    if (id.isEmpty) return null;
    try {
      final response = await _getWithAuthRetry('/api/tasks/$id');
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




