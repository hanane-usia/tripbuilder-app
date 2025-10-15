import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  // ألوان الوضع المظلم
  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkCardColor = Color(0xFF2D2D2D);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkSubTextColor = Color(0xFF9FA5C0);
  static const Color darkDividerColor = Color(0xFF404040);

  // ألوان الوضع الفاتح
  static const Color lightBackgroundColor = Color(0xFFF0EFF4);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightTextColor = Color(0xFF2D3142);
  static const Color lightSubTextColor = Color(0xFF9FA5C0);
  static const Color lightDividerColor = Color(0xFFF0EFF4);

  // الحصول على الألوان حسب الوضع
  Color get backgroundColor =>
      _isDarkMode ? darkBackgroundColor : lightBackgroundColor;
  Color get cardColor => _isDarkMode ? darkCardColor : lightCardColor;
  Color get textColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get subTextColor => _isDarkMode ? darkSubTextColor : lightSubTextColor;
  Color get dividerColor => _isDarkMode ? darkDividerColor : lightDividerColor;
}
