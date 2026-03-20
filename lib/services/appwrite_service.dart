import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/enums.dart'; // Needed for OAuthProvider enum
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

  /// Gets the currently logged-in user
  Future<User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      debugPrint("No active session or error: $e");
      return null;
    }
  }
  
  /// Logs the user in with Email/Password
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

  /// Logs the user in with Google OAuth
  Future<bool> loginWithGoogle() async {
    try {
      // Use the enum OAuthProvider.google instead of the string 'google'
      await account.createOAuth2Session(provider: OAuthProvider.google);
      notifyListeners();
      return true; // Returns true on success for signin.dart
    } catch (e) {
      debugPrint("Google login error: $e");
      return false; // Returns false on failure
    }
  }

  /// Registers a new user
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

  /// Logs the user out
  Future<void> logout() async {
     try {
       await account.deleteSession(sessionId: 'current');
       notifyListeners();
     } catch(e) {
       debugPrint("Logout error: $e");
     }
  }

  /// Gets the user's avatar (initials based on their name)
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

  /// Creates a new outfit plan for the calendar
  Future<Document> createPlan(Map<String, dynamic> data) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      // Automatically attach the logged-in user's ID for security
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

  /// Gets all plans for the currently logged-in user
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

  /// Deletes a specific plan from the calendar
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

  /// Updates the reminder status (bell icon) for a plan
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

  /// Fetches saved style boards filtered by occasion (e.g., 'Party', 'Office')
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
          Query.orderDesc('\$createdAt'), // Shows newest boards first
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching $occasion boards: $e");
      return []; 
    }
  }

  /// Fetches ALL saved style boards (Used for the "Everything Else" screen)
  Future<List<Document>> getAllSavedBoards() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      final result = await databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _savedBoardsCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.orderDesc('\$createdAt'), // Shows newest boards first
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching all boards: $e");
      return []; 
    }
  }

  /// Deletes a specific saved board
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
}