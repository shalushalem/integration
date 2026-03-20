import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart'; // Added for OAuthProvider
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import '../config/env.dart';

class AppwriteService extends ChangeNotifier {
  Client client = Client();
  late Account account;
  late Databases databases;
  late Avatars avatars; // ⬅️ Added for getUserAvatar

  AppwriteService() {
    client
        .setEndpoint(Env.appwriteEndpoint)
        .setProject(Env.appwriteProjectId);
    account = Account(client);
    databases = Databases(client);
    avatars = Avatars(client); // ⬅️ Initialized
  }

  // =========================================================================
  // AUTHENTICATION METHODS
  // =========================================================================

  Future<User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  /// ⬅️ ADDED: Google Login Method for signin.dart
  Future<bool> loginWithGoogle() async {
    try {
      // Initiates the Google OAuth2 flow
      await account.createOAuth2Session(
        provider: OAuthProvider.google, 
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint("Google login error: $e");
      return false;
    }
  }

  // =========================================================================
  // AVATAR METHODS
  // =========================================================================

  /// ⬅️ ADDED: Generates a fallback Avatar with initials for home.dart
  Future<Uint8List?> getUserAvatar(String name) async {
    try {
      // Returns a Uint8List containing the image bytes for initials
      return await avatars.getInitials(name: name);
    } catch (e) {
      debugPrint("Avatar generation error: $e");
      return null;
    }
  }

  // =========================================================================
  // USER PROFILE DB METHODS
  // =========================================================================

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      final document = await databases.getDocument(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.usersCollection,
        documentId: user.$id,
      );
      return document.data;
    } on AppwriteException catch (e) {
      if (e.code == 404) return null; 
      debugPrint("Error fetching profile from DB: $e");
      rethrow;
    }
  }

  Future<void> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");
      
      try {
        await databases.updateDocument(
          databaseId: Env.appwriteDatabaseId,
          collectionId: Env.usersCollection,
          documentId: user.$id,
          data: profileData,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await databases.createDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.usersCollection,
            documentId: user.$id,
            data: profileData,
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint("Error saving profile to DB: $e");
      rethrow;
    }
  }

  // =========================================================================
  // CALENDAR PLANS DB METHODS
  // =========================================================================

  Future<List<Document>> getUserPlans() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");

      final result = await databases.listDocuments(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.plansCollection,
        queries: [
          Query.equal('userId', user.$id),
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Error fetching plans from DB: $e");
      return []; 
    }
  }

  Future<Document> createPlan(Map<String, dynamic> planData) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception("User not authenticated");
      
      planData['userId'] = user.$id;

      return await databases.createDocument(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.plansCollection,
        documentId: ID.unique(),
        data: planData,
      );
    } catch (e) {
      debugPrint("Error creating plan in DB: $e");
      rethrow;
    }
  }

  Future<void> deletePlan(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.plansCollection,
        documentId: documentId,
      );
    } catch (e) {
      debugPrint("Error deleting plan from DB: $e");
      rethrow;
    }
  }

  Future<void> updatePlanReminder(String documentId, bool reminderState) async {
    try {
      await databases.updateDocument(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.plansCollection,
        documentId: documentId,
        data: {'reminder': reminderState},
      );
    } catch (e) {
      debugPrint("Error updating plan reminder in DB: $e");
      rethrow;
    }
  }
}