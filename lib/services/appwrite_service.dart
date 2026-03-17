import 'dart:typed_data'; 
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite/enums.dart';
import 'package:myapp/config/env.dart';

class AppwriteService {
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Avatars avatars;

  AppwriteService() {
    client = Client()
        .setEndpoint(Env.appwriteEndpoint)
        .setProject(Env.appwriteProjectId)
        .setSelfSigned(status: true);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    avatars = Avatars(client);
  }

  // --- Auth Methods ---

  Future<bool> loginWithGoogle() async {
    try {
      await account.createOAuth2Session(provider: OAuthProvider.google);
      return true;
    } catch (e) {
      print("Google Login Error: $e");
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null; // Not logged in
    }
  }

  // --- User Profile Methods ---

  // Generate an avatar image based on the user's name!
  Future<Uint8List?> getUserAvatar(String name) async {
    try {
      // Creates a beautiful avatar with your app's accent color background
      // FIXED: Removed the unsupported 'color' parameter. Appwrite handles it automatically!
      return await avatars.getInitials(
        name: name,
        background: 'A259FF', // AHVI Purple
      );
    } catch (e) {
      print("Error fetching avatar: $e");
      return null;
    }
  }

  // --- Database Methods ---

  Future<DocumentList> getOutfits() async {
    try {
      return await databases.listDocuments(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.outfitsCollection,
      );
    } catch (e) {
      print("Error fetching outfits: $e");
      rethrow;
    }
  }
}