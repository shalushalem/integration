import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Public client-safe config only.
  static String get appwriteEndpoint =>
      dotenv.env['EXPO_PUBLIC_APPWRITE_ENDPOINT'] ?? '';
  static String get appwriteProjectId =>
      dotenv.env['EXPO_PUBLIC_APPWRITE_PROJECT_ID'] ?? '';

  static String get backendApiUrl {
    var value = (dotenv.env['BACKEND_API_URL'] ??
            dotenv.env['EXPO_PUBLIC_BACKEND_API_URL'] ??
            'http://127.0.0.1:8000')
        .trim();

    if (value.isEmpty) value = 'http://127.0.0.1:8000';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}