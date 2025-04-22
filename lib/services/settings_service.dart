import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Load settings from shared preferences
  Future<SettingsModel> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson == null) {
        return SettingsModel.defaults;
      }

      final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
      return SettingsModel.fromJson(settingsMap);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return SettingsModel.defaults;
    }
  }

  // Save settings to shared preferences
  Future<void> _saveSettings(SettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Update theme mode
  Future<SettingsModel> updateThemeMode(ThemeMode mode) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(themeMode: mode);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update server port
  Future<SettingsModel> updateServerPort(int port) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(serverPort: port);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update client port
  Future<SettingsModel> updateClientPort(int port) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(clientPort: port);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update default save location
  Future<SettingsModel> updateDefaultSaveLocation(String location) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(defaultSaveLocation: location);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update auto start server
  Future<SettingsModel> updateAutoStartServer(bool autoStart) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(autoStartServer: autoStart);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update show notifications
  Future<SettingsModel> updateShowNotifications(bool show) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(showNotifications: show);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update confirm before sending
  Future<SettingsModel> updateConfirmBeforeSending(bool confirm) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(confirmBeforeSending: confirm);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update confirm before receiving
  Future<SettingsModel> updateConfirmBeforeReceiving(bool confirm) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(confirmBeforeReceiving: confirm);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update theme style type
  Future<SettingsModel> updateThemeStyleType(ThemeStyleType styleType) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(themeStyleType: styleType);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update custom light theme
  Future<SettingsModel> updateCustomLightTheme(CustomThemeModel theme) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(lightCustomTheme: theme);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update custom dark theme
  Future<SettingsModel> updateCustomDarkTheme(CustomThemeModel theme) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(darkCustomTheme: theme);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update encryption enabled setting
  Future<SettingsModel> updateEnableEncryption(bool enable) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(enableEncryption: enable);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }

  // Update encryption PIN
  Future<SettingsModel> updateEncryptionPin(String pin) async {
    final settings = await loadSettings();
    final updatedSettings = settings.copyWith(encryptionPin: pin);
    await _saveSettings(updatedSettings);
    return updatedSettings;
  }
}
