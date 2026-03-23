import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/config/env.dart';
import 'package:myapp/services/local_data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProxyDocument {
  final String $id;
  final Map<String, dynamic> data;
  final Map<String, dynamic> raw;

  ProxyDocument({
    required this.$id,
    required this.data,
    required this.raw,
  });

  factory ProxyDocument.fromApi(Map<String, dynamic> rawMap) {
    final mapped = Map<String, dynamic>.from(rawMap);
    final id = (mapped[r'$id'] ?? mapped['id'] ?? '').toString();
    final data = <String, dynamic>{};

    mapped.forEach((key, value) {
      if (!key.startsWith(r'$')) {
        data[key] = value;
      }
    });

    return ProxyDocument(
      $id: id,
      data: data,
      raw: mapped,
    );
  }
}

class AppwriteService extends ChangeNotifier {
  static const _lastUserIdKey = 'last_user_id';
  late Client client;
  late Account account;
  late Avatars avatars;
  late String _baseUrl;
  final LocalDataStore _localStore = LocalDataStore();
  bool _localReady = false;

  AppwriteService() {
    client = Client()
      ..setEndpoint(Env.appwriteEndpoint)
      ..setProject(Env.appwriteProjectId);

    account = Account(client);
    avatars = Avatars(client);
    _baseUrl = '${Env.backendApiUrl}/api/data';
  }

  Future<void> _ensureLocalReady() async {
    if (_localReady) return;
    await _localStore.init();
    _localReady = true;
  }

  bool _isLocalId(String id) => id.startsWith('local_');

  Future<void> _persistLastUserId(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, userId);
  }

  Future<String?> _lastKnownUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastUserIdKey)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> _clearLastUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);
  }

  Future<void> _syncPendingLocalChanges(String userId) async {
    await _ensureLocalReady();
    final pending = await _localStore.pendingOps(userId);
    for (final op in pending) {
      try {
        if (op.entity == 'wardrobe' && op.op == 'create') {
          final data = Map<String, dynamic>.from(op.payload['data'] ?? const {});
          await _createDoc('outfits', data, userId: userId);
          await _localStore.deleteWardrobeItem(userId, op.refId);
          await _localStore.deletePendingOp(op.id);
          continue;
        }

        if (op.entity == 'wardrobe' && op.op == 'update') {
          if (_isLocalId(op.refId)) {
            await _localStore.deletePendingOp(op.id);
            continue;
          }
          final data = Map<String, dynamic>.from(op.payload['data'] ?? const {});
          await _updateDoc('outfits', op.refId, data);
          await _localStore.deleteWardrobeItem(userId, op.refId);
          await _localStore.deletePendingOp(op.id);
          continue;
        }

        if (op.entity == 'wardrobe' && op.op == 'delete') {
          if (_isLocalId(op.refId)) {
            await _localStore.deletePendingOp(op.id);
            continue;
          }
          await _deleteDoc('outfits', op.refId);
          await _localStore.deleteWardrobeItem(userId, op.refId);
          await _localStore.deletePendingOp(op.id);
          continue;
        }

        if (op.entity == 'saved_board' && op.op == 'delete') {
          await _deleteDoc('saved_boards', op.refId);
          await _localStore.deletePendingOp(op.id);
          continue;
        }

        if (op.entity == 'saved_board' && op.op == 'create') {
          final data = Map<String, dynamic>.from(op.payload['data'] ?? const {});
          await _createDoc('saved_boards', data, userId: userId);
          await _localStore.deleteBoard(userId, op.refId);
          await _localStore.deletePendingOp(op.id);
          continue;
        }
      } catch (_) {
        break;
      }
    }

    final remaining = await _localStore.pendingOps(userId);
    if (remaining.isEmpty) {
      await _localStore.clearUserBackupData(userId);
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final user = await account.get();
      await _persistLastUserId(user.$id);
      return user;
    } catch (e) {
      debugPrint("No active session or error: $e");
      return null;
    }
  }

  Future<Session?> loginEmailPassword(String email, String password) async {
    try {
      final session = await account.createEmailPasswordSession(email: email, password: password);
      final user = await getCurrentUser();
      if (user != null) {
        await _persistLastUserId(user.$id);
      }
      notifyListeners();
      return session;
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      await account.createOAuth2Session(provider: OAuthProvider.google);
      final user = await getCurrentUser();
      if (user != null) {
        await _persistLastUserId(user.$id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Google login error: $e");
      return false;
    }
  }

  Future<User> registerEmailPassword(String email, String password, String name) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      await _persistLastUserId(user.$id);
      return user;
    } catch (e) {
      debugPrint("Register error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      await _clearLastUserId();
      notifyListeners();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  Future<Uint8List?> getUserAvatar(String name) async {
    try {
      return await avatars.getInitials(name: name);
    } catch (e) {
      debugPrint("Avatar error: $e");
      return null;
    }
  }

  Future<String> _requireUserId() async {
    final user = await getCurrentUser();
    if (user != null) {
      return user.$id;
    }
    final fallbackUserId = await _lastKnownUserId();
    if (fallbackUserId != null) {
      return fallbackUserId;
    }
    throw Exception("User not authenticated");
  }

  Uri _resourceUri(String resource, {Map<String, String>? query}) {
    final uri = Uri.parse('$_baseUrl/$resource');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<List<ProxyDocument>> _listDocs(
    String resource, {
    String? userId,
    String? occasion,
    int limit = 100,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (userId != null && userId.isNotEmpty) query['user_id'] = userId;
    if (occasion != null && occasion.isNotEmpty) query['occasion'] = occasion;

    final response = await http.get(_resourceUri(resource, query: query));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch $resource: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = List<Map<String, dynamic>>.from(body['documents'] ?? const []);
    return docs.map(ProxyDocument.fromApi).toList();
  }

  Future<ProxyDocument> _createDoc(
    String resource,
    Map<String, dynamic> data, {
    String? userId,
    String? documentId,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'resource': resource,
        'data': data,
        if (userId != null) 'user_id': userId,
        if (documentId != null) 'document_id': documentId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create $resource: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ProxyDocument.fromApi(Map<String, dynamic>.from(body['document']));
  }

  Future<ProxyDocument> _updateDoc(
    String resource,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$documentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'resource': resource,
        'data': data,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update $resource: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ProxyDocument.fromApi(Map<String, dynamic>.from(body['document']));
  }

  Future<void> _deleteDoc(String resource, String documentId) async {
    final request = http.Request('DELETE', Uri.parse(_baseUrl))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'resource': resource, 'document_id': documentId});
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete $resource: ${response.body}');
    }
  }

  Future<ProxyDocument> getUserProfile() async {
    final userId = await _requireUserId();
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ProxyDocument.fromApi(Map<String, dynamic>.from(body['document']));
  }

  Future<ProxyDocument> upsertUserProfile(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save profile: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ProxyDocument.fromApi(Map<String, dynamic>.from(body['document']));
  }

  Future<List<Map<String, dynamic>>> getWardrobeItems() async {
    await _ensureLocalReady();
    String? userId;
    try {
      userId = await _requireUserId();
      await _syncPendingLocalChanges(userId);
    } catch (_) {}

    try {
      userId ??= await _requireUserId();
      final docs = await _listDocs('outfits', userId: userId, limit: 200);
      final mapped = docs
          .map((doc) => {
                "id": doc.$id,
                "name": doc.data['name'],
                "category": doc.data['category'],
                "sub_category": doc.data['sub_category'],
                "color_code": doc.data['color_code'],
                "pattern": doc.data['pattern'],
                "occasions": doc.data['occasions'],
                "image_url": doc.data['image_url'],
                "masked_url": doc.data['masked_url'],
                "notes": doc.data['notes'],
                "worn": doc.data['worn'] ?? 0,
                "liked": doc.data['liked'] ?? false,
              })
          .toList();
      return mapped;
    } catch (e) {
      debugPrint("Error fetching wardrobe items: $e");
      if (userId != null) {
        final cached = await _localStore.loadWardrobeItems(userId);
        if (cached.isNotEmpty) return cached;
      }
      return [];
    }
  }

  Future<ProxyDocument> createWardrobeItem(Map<String, dynamic> data) async {
    await _ensureLocalReady();
    final userId = await _requireUserId();
    await _syncPendingLocalChanges(userId);

    try {
      return await _createDoc('outfits', data, userId: userId);
    } catch (_) {
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final localMap = Map<String, dynamic>.from(data)..['id'] = localId;
      await _localStore.upsertWardrobeItem(userId, localMap);
      await _localStore.addPendingOp(
        userId: userId,
        entity: 'wardrobe',
        op: 'create',
        refId: localId,
        payload: {'data': data},
      );
      return ProxyDocument(
        $id: localId,
        data: Map<String, dynamic>.from(data),
        raw: {
          r'$id': localId,
          ...Map<String, dynamic>.from(data),
          '_local_only': true,
        },
      );
    }
  }

  Future<ProxyDocument> updateWardrobeItem(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _ensureLocalReady();
    final userId = await _requireUserId();

    if (_isLocalId(documentId)) {
      final cached = await _localStore.loadWardrobeItems(userId);
      final existing = cached
          .where((i) => (i['id'] ?? '').toString() == documentId)
          .cast<Map<String, dynamic>>()
          .toList();
      final merged = existing.isNotEmpty
          ? (Map<String, dynamic>.from(existing.first)..addAll(data))
          : (Map<String, dynamic>.from(data)..['id'] = documentId);
      await _localStore.upsertWardrobeItem(userId, merged);

      final pending = await _localStore.pendingOps(userId);
      final createOp = pending.where((op) =>
          op.entity == 'wardrobe' &&
          op.op == 'create' &&
          op.refId == documentId);
      if (createOp.isNotEmpty) {
        final op = createOp.first;
        final payload = Map<String, dynamic>.from(op.payload);
        final payloadData = Map<String, dynamic>.from(payload['data'] ?? const {});
        payloadData.addAll(data);
        payload['data'] = payloadData;
        await _localStore.updatePendingOpPayload(op.id, payload);
      }
      return ProxyDocument(
        $id: documentId,
        data: merged,
        raw: {
          r'$id': documentId,
          ...merged,
          '_local_only': true,
        },
      );
    }

    try {
      final updated = await _updateDoc('outfits', documentId, data);
      await _localStore.deleteWardrobeItem(userId, documentId);
      return updated;
    } catch (_) {
      final cached = await _localStore.loadWardrobeItems(userId);
      final existing = cached
          .where((i) => (i['id'] ?? '').toString() == documentId)
          .cast<Map<String, dynamic>>()
          .toList();
      final merged = existing.isNotEmpty
          ? (Map<String, dynamic>.from(existing.first)..addAll(data))
          : (Map<String, dynamic>.from(data)..['id'] = documentId);
      await _localStore.upsertWardrobeItem(userId, merged);
      await _localStore.addPendingOp(
        userId: userId,
        entity: 'wardrobe',
        op: 'update',
        refId: documentId,
        payload: {'data': data},
      );
      return ProxyDocument(
        $id: documentId,
        data: merged,
        raw: {
          r'$id': documentId,
          ...merged,
          '_local_only': true,
        },
      );
    }
  }

  Future<void> deleteWardrobeItem(String documentId) async {
    await _ensureLocalReady();
    final userId = await _requireUserId();
    await _localStore.deleteWardrobeItem(userId, documentId);

    if (_isLocalId(documentId)) {
      await _localStore.deletePendingOpsByRef(
        userId: userId,
        entity: 'wardrobe',
        refId: documentId,
        op: 'create',
      );
      return;
    }

    try {
      await _deleteDoc('outfits', documentId);
      await _syncPendingLocalChanges(userId);
    } catch (_) {
      await _localStore.addPendingOp(
        userId: userId,
        entity: 'wardrobe',
        op: 'delete',
        refId: documentId,
        payload: const <String, dynamic>{},
      );
    }
  }

  Future<ProxyDocument> createPlan(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('plans', data, userId: userId);
  }

  Future<List<ProxyDocument>> getUserPlans() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('plans', userId: userId);
    } catch (e) {
      debugPrint("Error fetching plans: $e");
      return [];
    }
  }

  Future<void> deletePlan(String documentId) async {
    await _deleteDoc('plans', documentId);
  }

  Future<void> updatePlanReminder(String documentId, bool reminder) async {
    await _updateDoc('plans', documentId, {'reminder': reminder});
  }

  Future<List<ProxyDocument>> getSavedBoardsByOccasion(String occasion) async {
    await _ensureLocalReady();
    String? userId;
    try {
      userId = await _requireUserId();
      await _syncPendingLocalChanges(userId);
    } catch (_) {}

    try {
      userId ??= await _requireUserId();
      return await _listDocs('saved_boards', userId: userId, occasion: occasion);
    } catch (e) {
      debugPrint("Error fetching $occasion boards: $e");
      if (userId != null) {
        final cached = await _localStore.loadBoards(userId, occasion: occasion);
        if (cached.isNotEmpty) {
          return cached
              .map(
                (row) => ProxyDocument(
                  $id: (row['id'] ?? '').toString(),
                  data: Map<String, dynamic>.from(row['data'] ?? const {}),
                  raw: Map<String, dynamic>.from(
                    row['raw'] ??
                        {
                          r'$id': (row['id'] ?? '').toString(),
                          ...Map<String, dynamic>.from(row['data'] ?? const {}),
                        },
                  ),
                ),
              )
              .toList();
        }
      }
      return [];
    }
  }

  Future<List<ProxyDocument>> getAllSavedBoards() async {
    await _ensureLocalReady();
    String? userId;
    try {
      userId = await _requireUserId();
      await _syncPendingLocalChanges(userId);
    } catch (_) {}

    try {
      userId ??= await _requireUserId();
      return await _listDocs('saved_boards', userId: userId);
    } catch (e) {
      debugPrint("Error fetching all boards: $e");
      if (userId != null) {
        final cached = await _localStore.loadBoards(userId);
        if (cached.isNotEmpty) {
          return cached
              .map(
                (row) => ProxyDocument(
                  $id: (row['id'] ?? '').toString(),
                  data: Map<String, dynamic>.from(row['data'] ?? const {}),
                  raw: Map<String, dynamic>.from(
                    row['raw'] ??
                        {
                          r'$id': (row['id'] ?? '').toString(),
                          ...Map<String, dynamic>.from(row['data'] ?? const {}),
                        },
                  ),
                ),
              )
              .toList();
        }
      }
      return [];
    }
  }

  Future<ProxyDocument> createSavedBoard(Map<String, dynamic> data) async {
    await _ensureLocalReady();
    final userId = await _requireUserId();
    await _syncPendingLocalChanges(userId);

    try {
      return await _createDoc('saved_boards', data, userId: userId);
    } catch (_) {
      final localId = 'local_board_${DateTime.now().millisecondsSinceEpoch}';
      await _localStore.cacheBoards(
        userId,
        [
          {
            'id': localId,
            'data': Map<String, dynamic>.from(data),
            'raw': {
              r'$id': localId,
              ...Map<String, dynamic>.from(data),
              '_local_only': true,
            },
          }
        ],
      );
      await _localStore.addPendingOp(
        userId: userId,
        entity: 'saved_board',
        op: 'create',
        refId: localId,
        payload: {'data': data},
      );
      return ProxyDocument(
        $id: localId,
        data: Map<String, dynamic>.from(data),
        raw: {
          r'$id': localId,
          ...Map<String, dynamic>.from(data),
          '_local_only': true,
        },
      );
    }
  }

  Future<void> deleteSavedBoard(String documentId) async {
    await _ensureLocalReady();
    final userId = await _requireUserId();
    await _localStore.deleteBoard(userId, documentId);
    try {
      await _deleteDoc('saved_boards', documentId);
      await _syncPendingLocalChanges(userId);
    } catch (_) {
      await _localStore.addPendingOp(
        userId: userId,
        entity: 'saved_board',
        op: 'delete',
        refId: documentId,
        payload: const <String, dynamic>{},
      );
    }
  }

  Future<ProxyDocument?> getSkincareProfile() async {
    try {
      final userId = await _requireUserId();
      final docs = await _listDocs('skincare', userId: userId, limit: 1);
      if (docs.isNotEmpty) return docs.first;

      return _createDoc('skincare', {
        'skinType': '',
        'concerns': [],
        'daySteps': [],
        'nightSteps': [],
        'lastUpdated': DateTime.now().toIso8601String(),
      }, userId: userId);
    } catch (e) {
      debugPrint("Error fetching skincare profile: $e");
      return null;
    }
  }

  Future<void> updateSkincareProfile({
    required String documentId,
    String? skinType,
    List<String>? concerns,
    List<int>? daySteps,
    List<int>? nightSteps,
  }) async {
    final updateData = <String, dynamic>{};
    if (skinType != null) updateData['skinType'] = skinType;
    if (concerns != null) updateData['concerns'] = concerns;
    if (daySteps != null) updateData['daySteps'] = daySteps;
    if (nightSteps != null) updateData['nightSteps'] = nightSteps;
    updateData['lastUpdated'] = DateTime.now().toIso8601String();
    await _updateDoc('skincare', documentId, updateData);
  }

  Future<List<ProxyDocument>> getWorkoutOutfits() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('workout_outfits', userId: userId);
    } catch (e) {
      debugPrint("Error fetching workout outfits: $e");
      return [];
    }
  }

  Future<ProxyDocument> createWorkoutOutfit(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('workout_outfits', data, userId: userId);
  }

  Future<void> deleteWorkoutOutfit(String documentId) async {
    await _deleteDoc('workout_outfits', documentId);
  }

  Future<List<ProxyDocument>> getBills() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('bills', userId: userId);
    } catch (e) {
      debugPrint("Error fetching bills: $e");
      return [];
    }
  }

  Future<ProxyDocument> createBill(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('bills', data, userId: userId);
  }

  Future<void> deleteBill(String documentId) async {
    await _deleteDoc('bills', documentId);
  }

  Future<List<ProxyDocument>> getCoupons() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('coupons', userId: userId);
    } catch (e) {
      debugPrint("Error fetching coupons: $e");
      return [];
    }
  }

  Future<ProxyDocument> createCoupon(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('coupons', data, userId: userId);
  }

  Future<void> deleteCoupon(String documentId) async {
    await _deleteDoc('coupons', documentId);
  }

  Future<List<ProxyDocument>> getMeds() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('meds', userId: userId);
    } catch (e) {
      debugPrint("Error fetching meds: $e");
      return [];
    }
  }

  Future<ProxyDocument> createMed(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('meds', data, userId: userId);
  }

  Future<void> updateMed(String documentId, Map<String, dynamic> data) async {
    await _updateDoc('meds', documentId, data);
  }

  Future<void> deleteMed(String documentId) async {
    await _deleteDoc('meds', documentId);
  }

  Future<List<ProxyDocument>> getMedLogs() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('med_logs', userId: userId);
    } catch (e) {
      debugPrint("Error fetching med logs: $e");
      return [];
    }
  }

  Future<ProxyDocument> createMedLog(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('med_logs', data, userId: userId);
  }

  Future<List<ProxyDocument>> getMealPlans() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('meal_plans', userId: userId);
    } catch (e) {
      debugPrint("Error fetching meal plans: $e");
      return [];
    }
  }

  Future<ProxyDocument> createMealPlan(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('meal_plans', data, userId: userId);
  }

  Future<void> deleteMealPlan(String documentId) async {
    await _deleteDoc('meal_plans', documentId);
  }

  Future<List<ProxyDocument>> getLifeGoals() async {
    try {
      final userId = await _requireUserId();
      return await _listDocs('life_goals', userId: userId);
    } catch (e) {
      debugPrint("Error fetching life goals: $e");
      return [];
    }
  }

  Future<ProxyDocument> createLifeGoal(Map<String, dynamic> data) async {
    final userId = await _requireUserId();
    return _createDoc('life_goals', data, userId: userId);
  }

  Future<void> updateLifeGoalProgress(String documentId, int progress) async {
    await _updateDoc('life_goals', documentId, {'progress': progress});
  }

  Future<void> deleteLifeGoal(String documentId) async {
    await _deleteDoc('life_goals', documentId);
  }
}
