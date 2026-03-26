import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Public client-safe config only.
  static String get appwriteEndpoint => dotenv.env['EXPO_PUBLIC_APPWRITE_ENDPOINT'] ?? '';
  static String get appwriteProjectId => dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_ID'] ?? '';
  static String get backendApiUrl => dotenv.env['EXPO_PUBLIC_BACKEND_API_URL'] ?? '';
}
