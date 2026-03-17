import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Appwrite Config
  static String get appwriteEndpoint => dotenv.env['EXPO_PUBLIC_APPWRITE_ENDPOINT'] ?? '';
  static String get appwriteProjectId => dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_ID'] ?? '';
  static String get appwriteDatabaseId => dotenv.env['EXPO_PUBLIC_APPWRITE_DATABASE_ID'] ?? '';
  
  // Collections
  static String get outfitsCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_OUTFITS'] ?? '';
  static String get usersCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_USERS'] ?? '';
  static String get memoriesCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_MEMORIES'] ?? '';
  static String get savedBoardsCollection => dotenv.env['EXPO_PUBLIC_APPWRITE_COLLECTION_SAVED_BOARDS'] ?? '';

  // Cloudflare R2 Config
  static String get r2AccountId => dotenv.env['EXPO_PUBLIC_R2_ACCOUNT_ID'] ?? '';
  static String get r2S3ApiUrl => dotenv.env['EXPO_PUBLIC_R2_S3_API_URL'] ?? '';
  static String get r2AccessKeyId => dotenv.env['EXPO_PUBLIC_R2_ACCESS_KEY_ID'] ?? '';
  static String get r2SecretAccessKey => dotenv.env['EXPO_PUBLIC_R2_SECRET_ACCESS_KEY'] ?? '';
  // Add this inside the Env class
  static String get backendApiUrl => dotenv.env['EXPO_PUBLIC_BACKEND_API_URL'] ?? 'http://10.0.2.2:8000';
}