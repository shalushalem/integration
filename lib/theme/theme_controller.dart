import 'package:flutter/foundation.dart';

import 'profile_theme.dart';
import 'theme_storage.dart';

class ThemeController extends ChangeNotifier {
  bool isDarkMode = true;
  ProfileTheme currentTheme = ProfileTheme.coolBlue;

  Future<void> loadTheme() async {
    currentTheme = await ThemeStorage.loadTheme();
    isDarkMode = await ThemeStorage.loadMode();
    notifyListeners();
  }

  Future<void> toggleBrightness() async {
    isDarkMode = !isDarkMode;
    await ThemeStorage.saveMode(isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(ProfileTheme theme) async {
    if (currentTheme == theme) return;
    currentTheme = theme;
    await ThemeStorage.saveTheme(theme);
    notifyListeners();
  }
}
