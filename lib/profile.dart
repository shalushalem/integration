// ============================================================================
// PROFILE.DART - FULLY INTEGRATED WITH APPWRITE DB & CLOUDFLARE R2 S3
// ============================================================================

import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ðŸš€ Backend Integrations
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/services/backend_service.dart';

// ðŸŽ¨ Theme
import 'package:myapp/theme/accent_palette.dart';
import 'package:myapp/theme/gradients.dart';
import 'package:myapp/theme/profile_theme.dart';
import 'package:myapp/theme/theme_controller.dart';
import 'package:myapp/theme/theme_tokens.dart';

part 'profile_parts.dart';
part 'profile_screen.dart';

class ProfileController extends ChangeNotifier {
  String name;
  String email;
  String phone;
  String gender;
  String dob;
  Set<String> stylePreferences;
  bool personalizationEnabled;
  bool faceUploaded;
  bool bodyUploaded;
  Uint8List? avatarBytes;

  ProfileController({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.gender = '',
    this.dob = '',
    Set<String>? stylePreferences,
    this.personalizationEnabled = false,
    this.faceUploaded = false,
    this.bodyUploaded = false,
    this.avatarBytes,
  }) : stylePreferences = stylePreferences ?? <String>{};

  void updateBasics({
    required String name,
    required String phone,
    required String gender,
    required String dob,
  }) {
    this.name = name;
    this.phone = phone;
    this.gender = gender;
    this.dob = dob;
    notifyListeners();
  }

  void updateStyles(Set<String> styles) {
    stylePreferences = Set<String>.from(styles);
    notifyListeners();
  }

  void updatePersonalization({
    required bool enabled,
    required bool faceUploaded,
    required bool bodyUploaded,
  }) {
    personalizationEnabled = enabled;
    this.faceUploaded = faceUploaded;
    this.bodyUploaded = bodyUploaded;
    notifyListeners();
  }

  void setAvatarBytes(Uint8List? bytes) {
    avatarBytes = bytes;
    notifyListeners();
  }
}

// â”€â”€ Palette now sourced from theme tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Color _accent4(AppThemeTokens t) =>
    Color.lerp(t.accent.primary, t.accent.secondary, 0.55)!;
Color _accent5(AppThemeTokens t) =>
    Color.lerp(t.accent.secondary, t.accent.tertiary, 0.55)!;

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _FadeSlide â€” Staggered fadeUp entrance widget
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
