import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteService extends ChangeNotifier {
  late Client client;
  late Account account;
  late Databases databases;
  late Avatars avatars;

  // ── Environment Variables ──
  String get _endpoint => dotenv.env['EXPO_PUBLIC_APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1';
  String get _projectId => dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_ID'] ?? '';
  String get _databaseId => dotenv.env['EXPO_PUBLIC_APPWRITE_DATABASE_ID'] ?? '';
  String get _plansCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_PLANS'] ?? 'plans';
  String get _savedBoardsCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_SAVED_BOARDS'] ?? 'saved_boards';
  String get _skincareCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_SKINCARE'] ?? 'skincare';
  
  // New distinct collection for the workout screen
  String get _workoutOutfitsCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_WORKOUT_OUTFITS'] ?? 'workout_outfits';

  AppwriteService() {
    client = Client()
      ..setEndpoint(_endpoint)
      ..setProject(_projectId);

    account = Account(client);
    databases = Databases(client);
    avatars = Avatars(client);
  }

  // =========================================================================
  // AUTHENTICATION METHODS
  // =========================================================================

  Future<User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      debugPrint("No active session or error: $e");
      return null;
    }
  }
  
  Future<Session?> loginEmailPassword(String email, String password) async {
     try {
       final session = await account.createEmailPasswordSession(email: email, password: password);
       notifyListeners();
       return session;
     } catch(e) {
       debugPrint("Login error: $e");
       rethrow;
     }
  }

  Future<bool> loginWithGoogle() async {
    try {
      await account.createOAuth2Session(provider: OAuthProvider.google);
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
         name: name
       );
       return user;
     } catch(e) {
       debugPrint("Register error: $e");
       rethrow;
     }
  }

  Future<void> logout() async {
     try {
       await account.deleteSession(sessionId: 'current');
       notifyListeners();
     } catch(e) {
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

  // =========================================================================
  // CALENDAR PLANS DB METHODS
  // =========================================================================

  Future<Document> createPlan(Map<String, dynamic> data) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      data['userId'] = user.$id; 

      return await databases.createDocument(
        databaseId: _databaseId,
        collectionId: _plansCollection,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      debugPrint("Error creating plan: $e");
      rethrow;
    }
  }

  Future<List<Document>> getUserPlans() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      final result = await databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _plansCollection,
        queries: [
          Query.equal('userId', user.$id),
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching plans: $e");
      return [];
    }
  }

  Future<void> deletePlan(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _plansCollection,
        documentId: documentId,
      );
    } catch (e) {
      debugPrint("Error deleting plan: $e");
      rethrow;
    }
  }

  Future<void> updatePlanReminder(String documentId, bool reminder) async {
    try {
      await databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _plansCollection,
        documentId: documentId,
        data: {'reminder': reminder},
      );
    } catch (e) {
      debugPrint("Error updating plan reminder: $e");
      rethrow;
    }
  }

  // =========================================================================
  // SAVED BOARDS DB METHODS
  // =========================================================================

  Future<List<Document>> getSavedBoardsByOccasion(String occasion) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      final result = await databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _savedBoardsCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('occasion', occasion),
          Query.orderDesc('\$createdAt'), 
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching $occasion boards: $e");
      return []; 
    }
  }

  Future<List<Document>> getAllSavedBoards() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      final result = await databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _savedBoardsCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.orderDesc('\$createdAt'), 
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching all boards: $e");
      return []; 
    }
  }

  Future<void> deleteSavedBoard(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _savedBoardsCollection,
        documentId: documentId,
      );
    } catch (e) {
      debugPrint("Error deleting board: $e");
      throw Exception("Failed to delete board");
    }
  }

  // =========================================================================
  // SKINCARE DB METHODS
  // =========================================================================

  Future<Document?> getSkincareProfile() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      final result = await databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _skincareCollection,
        queries: [Query.equal('userId', user.$id)],
      );

      if (result.documents.isEmpty) {
        return await databases.createDocument(
          databaseId: _databaseId,
          collectionId: _skincareCollection,
          documentId: ID.unique(),
          data: {
            'userId': user.$id,
            'skinType': '',
            'concerns': [],
            'daySteps': [],
            'nightSteps': [],
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        );
      }
      return result.documents.first;
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
    try {
      Map<String, dynamic> updateData = {};
      if (skinType != null) updateData['skinType'] = skinType;
      if (concerns != null) updateData['concerns'] = concerns;
      if (daySteps != null) updateData['daySteps'] = daySteps;
      if (nightSteps != null) updateData['nightSteps'] = nightSteps;
      updateData['lastUpdated'] = DateTime.now().toIso8601String();

      await databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _skincareCollection,
        documentId: documentId,
        data: updateData,
      );
    } catch (e) {
      debugPrint("Error updating skincare profile: $e");
    }
  }

  // =========================================================================
  // WORKOUT OUTFITS DB METHODS
  // =========================================================================

  Future<List<Document>> getWorkoutOutfits() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      final result = await databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _workoutOutfitsCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching workout outfits: $e");
      return [];
    }
  }

  Future<Document> createWorkoutOutfit(Map<String, dynamic> data) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      data['userId'] = user.$id;

      return await databases.createDocument(
        databaseId: _databaseId,
        collectionId: _workoutOutfitsCollection,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      debugPrint("Error creating workout outfit: $e");
      rethrow;
    }
  }

  Future<void> deleteWorkoutOutfit(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _workoutOutfitsCollection,
        documentId: documentId,
      );
    } catch (e) {
      debugPrint("Error deleting workout outfit: $e");
      rethrow;
    }
  }
}