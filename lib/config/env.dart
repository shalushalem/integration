import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Public client-safe config only.
  static String get appwriteEndpoint =>
      dotenv.env['EXPO_PUBLIC_APPWRITE_ENDPOINT'] ?? '';
  static String get appwriteProjectId =>
      dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_ID'] ?? '';
  static String get appwriteDatabaseId =>
      dotenv.env['EXPO_PUBLIC_APPWRITE_DATABASE_ID'] ??
      dotenv.env['APPWRITE_DATABASE_ID'] ??
      '';
  static String get outfitsCollection =>
      dotenv.env['EXPO_PUBLIC_APPWRITE_OUTFITS_COLLECTION_ID'] ??
      dotenv.env['APPWRITE_OUTFITS_COLLECTION_ID'] ??
      dotenv.env['OUTFITS_COLLECTION_ID'] ??
      '';

  static String get backendApiUrl {
    var value = (dotenv.env['BACKEND_API_URL'] ??
            dotenv.env['EXPO_PUBLIC_BACKEND_API_URL'] ??
            'https://cloudbackend-production-63ba.up.railway.app')
        .trim();

    if (value.isEmpty) value = 'https://cloudbackend-production-63ba.up.railway.app';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
