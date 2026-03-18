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

  // --- Getters for UI Integration ---
  String get databaseId => Env.appwriteDatabaseId;
  String get outfitCollectionId => Env.outfitsCollection;


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


  // --- Storage / R2 Methods ---

  /// Uploads raw bytes to Appwrite Storage and returns the file URL
  Future<String> uploadFile(Uint8List bytes, String bucket) async {
    try {
      final uniqueId = ID.unique();
      
      // Convert raw bytes into an Appwrite InputFile
      final file = InputFile.fromBytes(
        bytes: bytes, 
        filename: 'img_$uniqueId.png'
      );
      
      await storage.createFile(
        bucketId: bucket,
        fileId: uniqueId,
        file: file,
      );
      
      // Return the public URL formatted for Appwrite
      return '${Env.appwriteEndpoint}/storage/buckets/$bucket/files/$uniqueId/view?project=${Env.appwriteProjectId}';
    } catch (e) {
      print("Upload error: $e");
      rethrow;
    }
  }

  /// Deletes a file from Storage by extracting its ID from the URL
  Future<void> deleteFileFromR2(String url, String bucket) async {
    try {
      // Extract fileId from the Appwrite URL
      // Example: https://[ENDPOINT]/v1/storage/buckets/[BUCKET]/files/[FILE_ID]/view
      Uri uri = Uri.parse(url);
      int filesIndex = uri.pathSegments.indexOf('files');
      
      if (filesIndex != -1 && uri.pathSegments.length > filesIndex + 1) {
        String fileId = uri.pathSegments[filesIndex + 1];
        await storage.deleteFile(bucketId: bucket, fileId: fileId);
      } else {
        print("Could not extract fileId from url: $url");
      }
    } catch (e) {
      print("Delete error: $e");
    }
  }
}