import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import 'settings_service.dart';

class ThemeService extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  // Default light theme
  final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9F9F9), // Background
    cardColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFF0066CC), // Primary
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0066CC), // Primary
      foregroundColor: Color(0xFFFFFFFF), // Text Primary
      elevation: 4.0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF0066CC), // Primary
      foregroundColor: Color(0xFFFFFFFF), // Text Primary
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF000000)), // Text Primary
      bodyMedium: TextStyle(color: Color(0xFF000000)), // Text Primary
      bodySmall: TextStyle(color: Color(0xFF4F4F4F)), // Text Secondary
      titleLarge: TextStyle(color: Color(0xFF000000)), // Text Primary
      titleMedium: TextStyle(color: Color(0xFF000000)), // Text Primary
      titleSmall: TextStyle(color: Color(0xFF4F4F4F)), // Text Secondary
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0066CC), // Primary
      secondary: Color(0xFF0066CC), // FAB (same as primary)
      surface: Color(0xFFFFFFFF),
      surfaceTint: Color(0xFFF9F9F9), // Background
      onPrimary: Color(0xFFFFFFFF), // FAB Icon (white for contrast)
      onSecondary: Color(0xFFFFFFFF), // FAB Icon (white for contrast)
      onSurface: Color(0xFF000000), // Text Primary
      onError: Color(0xFFFFFFFF),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFFFFFFFF),
      titleTextStyle: const TextStyle(color: Color(0xFF000000), fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFF4F4F4F), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFFF9F9F9)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFFFFFFFF), textStyle: const TextStyle(color: Color(0xFF000000))),
  );

  // Default dark theme
  final ThemeData darkTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Background
    cardColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF0066CC), // Primary
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0066CC), // Primary
      foregroundColor: Color(0xFFFFFFFF), // Text Primary
      elevation: 4.0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Color(0xFF0066CC), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFFFFFF)), // Text Primary
      bodyMedium: TextStyle(color: Color(0xFFFFFFFF)), // Text Primary
      bodySmall: TextStyle(color: Color(0xFFB0B0B0)), // Text Secondary
      titleLarge: TextStyle(color: Color(0xFFFFFFFF)), // Text Primary
      titleMedium: TextStyle(color: Color(0xFFFFFFFF)), // Text Primary
      titleSmall: TextStyle(color: Color(0xFFB0B0B0)), // Text Secondary
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0066CC), // Primary
      secondary: Color(0xFF0066CC), // FAB
      surface: Color(0xFF1E1E1E),
      surfaceTint: Color(0xFF121212), // Background
      onPrimary: Color(0xFFFFFFFF), // Text Primary
      onSecondary: Color(0xFFFFFFFF), // Text Primary
      onSurface: Color(0xFFFFFFFF), // Text Primary
      onError: Color(0xFFFFFFFF),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      titleTextStyle: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFF121212)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFF1E1E1E), textStyle: const TextStyle(color: Color(0xFFFFFFFF))),
  );

  // Light Forest Theme
  final ThemeData lightForestTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFE8F5E9), // Light green background
    cardColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFF388E3C), // Green primary
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF388E3C), foregroundColor: Colors.white, elevation: 4.0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF388E3C), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1B5E20)),
      bodyMedium: TextStyle(color: Color(0xFF1B5E20)),
      bodySmall: TextStyle(color: Color(0xFF2E7D32)),
      titleLarge: TextStyle(color: Color(0xFF1B5E20)),
      titleMedium: TextStyle(color: Color(0xFF1B5E20)),
      titleSmall: TextStyle(color: Color(0xFF2E7D32)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF388E3C),
      secondary: Color(0xFF66BB6A),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1B5E20),
      error: Colors.red,
      onError: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFFFFFFFF),
      titleTextStyle: const TextStyle(color: Color(0xFF1B5E20), fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFF2E7D32), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFFE8F5E9)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFFFFFFFF), textStyle: const TextStyle(color: Color(0xFF1B5E20))),
  );

  // Dark Forest Theme
  final ThemeData darkForestTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark background
    cardColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF2E7D32), // Forest green
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2E7D32), foregroundColor: Colors.white, elevation: 4.0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF2E7D32), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFA5D6A7)), // Muted green
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Color(0xFFA5D6A7)),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFF66BB6A),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFF121212)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFF1E1E1E), textStyle: const TextStyle(color: Colors.white)),
  );

  // Light Sunset Theme
  final ThemeData lightSunsetTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF3E0), // Soft warm background
    cardColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFFF57C00), // Warm orange
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF57C00), foregroundColor: Colors.white, elevation: 4.0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFF57C00), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFBF360C)),
      bodyMedium: TextStyle(color: Color(0xFFBF360C)),
      bodySmall: TextStyle(color: Color(0xFFD84315)),
      titleLarge: TextStyle(color: Color(0xFFBF360C)),
      titleMedium: TextStyle(color: Color(0xFFBF360C)),
      titleSmall: TextStyle(color: Color(0xFFD84315)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFF57C00),
      secondary: Color(0xFFFF8A65),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFBF360C),
      error: Colors.red,
      onError: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFFFFFFFF),
      titleTextStyle: const TextStyle(color: Color(0xFFBF360C), fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFFD84315), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFFFFF3E0)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFFFFFFFF), textStyle: const TextStyle(color: Color(0xFFBF360C))),
  );

  // Dark Sunset Theme
  final ThemeData darkSunsetTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark background
    cardColor: const Color(0xFF121212),
    primaryColor: const Color(0xFFD84315), // Rich orange
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFD84315), foregroundColor: Colors.white, elevation: 4.0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFD84315), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFFFAB91)), // Warm tone for secondary text
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Color(0xFFFFAB91)),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD84315),
      secondary: Color(0xFFFF8A65),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFFFFAB91), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFF121212)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFF1E1E1E), textStyle: const TextStyle(color: Colors.white)),
  );

  // Light Violet Theme
  final ThemeData lightVioletTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFEDE7F6), // Light lavender background
    cardColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFF7E57C2), // Violet primary
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF7E57C2), foregroundColor: Colors.white, elevation: 4.0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF7E57C2), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF4A148C)),
      bodyMedium: TextStyle(color: Color(0xFF4A148C)),
      bodySmall: TextStyle(color: Color(0xFF6A1B9A)),
      titleLarge: TextStyle(color: Color(0xFF4A148C)),
      titleMedium: TextStyle(color: Color(0xFF4A148C)),
      titleSmall: TextStyle(color: Color(0xFF6A1B9A)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7E57C2),
      secondary: Color(0xFFBA68C8),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF4A148C),
      error: Colors.red,
      onError: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFFFFFFFF),
      titleTextStyle: const TextStyle(color: Color(0xFF4A148C), fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFF6A1B9A), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFFEDE7F6)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFFFFFFFF), textStyle: const TextStyle(color: Color(0xFF4A148C))),
  );

  // Dark Violet Theme
  final ThemeData darkVioletTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark background
    cardColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF6A1B9A), // Deep violet
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF6A1B9A), foregroundColor: Colors.white, elevation: 4.0),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF6A1B9A), foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFCE93D8)), // Light purple
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Color(0xFFCE93D8)),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6A1B9A),
      secondary: Color(0xFFBA68C8),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      contentTextStyle: const TextStyle(color: Color(0xFFCE93D8), fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: const Color(0xFF121212)),
    popupMenuTheme: PopupMenuThemeData(color: const Color(0xFF1E1E1E), textStyle: const TextStyle(color: Colors.white)),
  );

  late SettingsModel _settings;
  bool _isInitialized = false;

  ThemeMode get themeMode => _settings.themeMode;
  SettingsModel get settings => _settings;
  bool get isInitialized => _isInitialized;

  // Initialize the theme service
  Future<void> initialize() async {
    try {
      _settings = await _settingsService.loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme service: $e');
      _settings = SettingsModel.defaults;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Update theme mode
  Future<void> updateThemeMode(ThemeMode mode) async {
    try {
      _settings = await _settingsService.updateThemeMode(mode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating theme mode: $e');
    }
  }

  // Update server port
  Future<void> updateServerPort(int port) async {
    try {
      _settings = await _settingsService.updateServerPort(port);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating server port: $e');
    }
  }

  // Update client port
  Future<void> updateClientPort(int port) async {
    try {
      _settings = await _settingsService.updateClientPort(port);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating client port: $e');
    }
  }

  // Update default save location
  Future<void> updateDefaultSaveLocation(String location) async {
    try {
      _settings = await _settingsService.updateDefaultSaveLocation(location);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating default save location: $e');
    }
  }

  // Update auto start server
  Future<void> updateAutoStartServer(bool autoStart) async {
    try {
      _settings = await _settingsService.updateAutoStartServer(autoStart);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating auto start server: $e');
    }
  }

  // Update show notifications
  Future<void> updateShowNotifications(bool show) async {
    try {
      _settings = await _settingsService.updateShowNotifications(show);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating show notifications: $e');
    }
  }

  // Update confirm before sending
  Future<void> updateConfirmBeforeSending(bool confirm) async {
    try {
      _settings = await _settingsService.updateConfirmBeforeSending(confirm);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating confirm before sending: $e');
    }
  }

  // Update confirm before receiving
  Future<void> updateConfirmBeforeReceiving(bool confirm) async {
    try {
      _settings = await _settingsService.updateConfirmBeforeReceiving(confirm);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating confirm before receiving: $e');
    }
  }

  // Update theme style type
  Future<void> updateThemeStyleType(ThemeStyleType styleType) async {
    try {
      _settings = await _settingsService.updateThemeStyleType(styleType);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating theme style type: $e');
    }
  }

  // Update custom light theme
  Future<void> updateCustomLightTheme(CustomThemeModel theme) async {
    try {
      _settings = await _settingsService.updateCustomLightTheme(theme);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating custom light theme: $e');
    }
  }

  // Update custom dark theme
  Future<void> updateCustomDarkTheme(CustomThemeModel theme) async {
    try {
      _settings = await _settingsService.updateCustomDarkTheme(theme);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating custom dark theme: $e');
    }
  }

  // Update encryption enabled setting
  Future<void> updateEnableEncryption(bool enable) async {
    try {
      _settings = await _settingsService.updateEnableEncryption(enable);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating encryption enabled: $e');
    }
  }

  // Update encryption PIN
  Future<void> updateEncryptionPin(String pin) async {
    try {
      _settings = await _settingsService.updateEncryptionPin(pin);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating encryption PIN: $e');
    }
  }

  // Get light theme data based on theme style
  ThemeData getLightTheme() {
    switch (_settings.themeStyleType) {
      case ThemeStyleType.forest:
        return lightForestTheme;
      case ThemeStyleType.sunset:
        return lightSunsetTheme;
      case ThemeStyleType.violet:
        return lightVioletTheme;
      case ThemeStyleType.custom:
        if (_settings.lightCustomTheme != null) {
          return _createThemeFromCustom(_settings.lightCustomTheme!, Brightness.light);
        }
        return lightTheme; // Fallback to default if custom theme is null
      case ThemeStyleType.defaultStyle:
        return lightTheme;
    }
  }

  // Get dark theme data based on theme style
  ThemeData getDarkTheme() {
    switch (_settings.themeStyleType) {
      case ThemeStyleType.forest:
        return darkForestTheme;
      case ThemeStyleType.sunset:
        return darkSunsetTheme;
      case ThemeStyleType.violet:
        return darkVioletTheme;
      case ThemeStyleType.custom:
        if (_settings.darkCustomTheme != null) {
          return _createThemeFromCustom(_settings.darkCustomTheme!, Brightness.dark);
        }
        return darkTheme; // Fallback to default if custom theme is null
      case ThemeStyleType.defaultStyle:
        return darkTheme;
    }
  }

  // Create a ThemeData object from a CustomThemeModel
  ThemeData _createThemeFromCustom(CustomThemeModel customTheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      scaffoldBackgroundColor: customTheme.scaffoldBackgroundColor,
      cardColor: customTheme.cardColor,
      primaryColor: customTheme.primaryColor,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: customTheme.appBarBackgroundColor,
        foregroundColor: customTheme.appBarForegroundColor,
        elevation: customTheme.appBarElevation,
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: customTheme.fabBackgroundColor,
        foregroundColor: customTheme.fabForegroundColor,
      ),

      // Text theme
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: customTheme.textPrimaryColor),
        bodyMedium: TextStyle(color: customTheme.textPrimaryColor),
        bodySmall: TextStyle(color: customTheme.textSecondaryColor),
        titleLarge: TextStyle(color: customTheme.textPrimaryColor),
        titleMedium: TextStyle(color: customTheme.textPrimaryColor),
        titleSmall: TextStyle(color: customTheme.textSecondaryColor),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: customTheme.dialogBackgroundColor,
        titleTextStyle: TextStyle(color: customTheme.dialogTitleColor, fontSize: 20),
        contentTextStyle: TextStyle(color: customTheme.dialogContentColor, fontSize: 16),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: customTheme.bottomSheetBackgroundColor),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(color: customTheme.popupMenuBackgroundColor, textStyle: TextStyle(color: customTheme.popupMenuTextColor)),

      // Card theme
      cardTheme: CardTheme(color: customTheme.cardColor, elevation: customTheme.cardElevation),

      // Divider theme
      dividerTheme: DividerThemeData(color: customTheme.dividerColor, thickness: customTheme.dividerThickness),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: customTheme.inputLabelColor),
        hintStyle: TextStyle(color: customTheme.inputHintColor),
        border: OutlineInputBorder(borderSide: BorderSide(color: customTheme.inputBorderColor)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: customTheme.inputFocusedBorderColor, width: 2.0)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: customTheme.inputBorderColor)),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: customTheme.elevatedButtonBackgroundColor, foregroundColor: customTheme.elevatedButtonForegroundColor),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: customTheme.textButtonColor)),

      // Color scheme
      colorScheme:
          brightness == Brightness.light
              ? ColorScheme.light(
                primary: customTheme.primaryColor,
                secondary: customTheme.fabBackgroundColor,
                surface: customTheme.surfaceColor,
                surfaceTint: customTheme.scaffoldBackgroundColor,
                onPrimary: customTheme.appBarForegroundColor,
                onSecondary: customTheme.fabForegroundColor,
                onSurface: customTheme.textPrimaryColor,
                onError: Colors.white,
                error: customTheme.errorColor,
              )
              : ColorScheme.dark(
                primary: customTheme.primaryColor,
                secondary: customTheme.fabBackgroundColor,
                surface: customTheme.surfaceColor,
                surfaceTint: customTheme.scaffoldBackgroundColor,
                onPrimary: customTheme.appBarForegroundColor,
                onSecondary: customTheme.fabForegroundColor,
                onSurface: customTheme.textPrimaryColor,
                onError: Colors.white,
                error: customTheme.errorColor,
              ),
    );
  }

  // Get the current theme based on theme mode
  ThemeData getTheme(BuildContext context) {
    switch (_settings.themeMode) {
      case ThemeMode.light:
        return getLightTheme();
      case ThemeMode.dark:
        return getDarkTheme();
      case ThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.dark ? getDarkTheme() : getLightTheme();
    }
  }

  // Static method to get the theme service from the provider
  static ThemeService of(BuildContext context) {
    return Provider.of<ThemeService>(context, listen: false);
  }
}
