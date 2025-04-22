import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../models/settings_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _serverPortController = TextEditingController();
  final TextEditingController _clientPortController = TextEditingController();
  final TextEditingController _saveLocationController = TextEditingController();
  final TextEditingController _encryptionPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with current settings
    final themeService = Provider.of<ThemeService>(context, listen: false);
    _serverPortController.text = themeService.settings.serverPort.toString();
    _clientPortController.text = themeService.settings.clientPort.toString();
    _saveLocationController.text = themeService.settings.defaultSaveLocation;
    _encryptionPinController.text = themeService.settings.encryptionPin;
  }

  @override
  void dispose() {
    _serverPortController.dispose();
    _clientPortController.dispose();
    _saveLocationController.dispose();
    _encryptionPinController.dispose();
    super.dispose();
  }

  // Build a settings card with a title, icon, and children
  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  // Show theme mode selection dialog
  void _showThemeDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system theme'),
                value: ThemeMode.system,
                groupValue: themeService.settings.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: ThemeMode.light,
                groupValue: themeService.settings.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: ThemeMode.dark,
                groupValue: themeService.settings.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
        );
      },
    );
  }

  // Show theme style selection dialog
  void _showThemeStyleDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme Style'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeStyleType>(
                title: const Text('Default'),
                subtitle: const Text('Standard blue theme'),
                value: ThemeStyleType.defaultStyle,
                groupValue: themeService.settings.themeStyleType,
                onChanged: (ThemeStyleType? value) {
                  if (value != null) {
                    themeService.updateThemeStyleType(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeStyleType>(
                title: const Text('Forest'),
                subtitle: const Text('Green nature theme'),
                value: ThemeStyleType.forest,
                groupValue: themeService.settings.themeStyleType,
                onChanged: (ThemeStyleType? value) {
                  if (value != null) {
                    themeService.updateThemeStyleType(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeStyleType>(
                title: const Text('Sunset'),
                subtitle: const Text('Warm orange theme'),
                value: ThemeStyleType.sunset,
                groupValue: themeService.settings.themeStyleType,
                onChanged: (ThemeStyleType? value) {
                  if (value != null) {
                    themeService.updateThemeStyleType(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeStyleType>(
                title: const Text('Violet'),
                subtitle: const Text('Purple theme'),
                value: ThemeStyleType.violet,
                groupValue: themeService.settings.themeStyleType,
                onChanged: (ThemeStyleType? value) {
                  if (value != null) {
                    themeService.updateThemeStyleType(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
        );
      },
    );
  }

  // Get text representation of theme mode
  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  // Get text representation of theme style type
  String _getThemeStyleText(ThemeStyleType styleType) {
    switch (styleType) {
      case ThemeStyleType.defaultStyle:
        return 'Default';
      case ThemeStyleType.forest:
        return 'Forest';
      case ThemeStyleType.sunset:
        return 'Sunset';
      case ThemeStyleType.violet:
        return 'Violet';
      case ThemeStyleType.custom:
        return 'Custom';
    }
  }

  // Pick a directory for default save location
  Future<void> _pickDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        _saveLocationController.text = selectedDirectory;
        final themeService = Provider.of<ThemeService>(context, listen: false);
        themeService.updateDefaultSaveLocation(selectedDirectory);
      }
    } catch (e) {
      debugPrint('Error picking directory: $e');
    }
  }

  // Get app version dynamically using PackageInfo
  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = '${info.version}+${info.buildNumber}';
      return version;
    } catch (e) {
      return 'Error';
    }
  }

  // Launch URL in browser
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $urlString')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: ${e.toString()}')));
      }
    }
  }

  // Show licenses page
  void _showLicensesPage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Toss',
      applicationVersion: 'v1.2.0+1', // Hard-coded version for now
      applicationIcon: const Icon(Icons.app_shortcut, size: 48),
      applicationLegalese: '© ${DateTime.now().year} Hunter Lee',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              // Appearance section
              _buildSettingsCard(
                context: context,
                title: 'Appearance',
                icon: Icons.palette,
                initiallyExpanded: true,
                children: [
                  ListTile(
                    title: const Text('Theme Mode'),
                    subtitle: Text(_getThemeModeText(themeService.settings.themeMode)),
                    leading: const Icon(Icons.brightness_6),
                    onTap: () => _showThemeDialog(context, themeService),
                  ),
                  ListTile(
                    title: const Text('Theme Style'),
                    subtitle: Text(_getThemeStyleText(themeService.settings.themeStyleType)),
                    leading: const Icon(Icons.color_lens),
                    onTap: () => _showThemeStyleDialog(context, themeService),
                  ),
                ],
              ),

              // Connection section
              _buildSettingsCard(
                context: context,
                title: 'Connection',
                icon: Icons.settings_ethernet,
                children: [
                  ListTile(title: const Text('Server Port'), subtitle: const Text('Port used when receiving files'), leading: const Icon(Icons.download)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: _serverPortController,
                      decoration: const InputDecoration(labelText: 'Server Port', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final port = int.tryParse(value);
                          if (port != null && port > 0 && port < 65536) {
                            themeService.updateServerPort(port);
                          }
                        }
                      },
                    ),
                  ),
                  ListTile(title: const Text('Client Port'), subtitle: const Text('Port used when sending files'), leading: const Icon(Icons.upload)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: _clientPortController,
                      decoration: const InputDecoration(labelText: 'Client Port', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final port = int.tryParse(value);
                          if (port != null && port > 0 && port < 65536) {
                            themeService.updateClientPort(port);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),

              // File Management section
              _buildSettingsCard(
                context: context,
                title: 'File Management',
                icon: Icons.folder,
                children: [
                  ListTile(
                    title: const Text('Default Save Location'),
                    subtitle: Text(themeService.settings.defaultSaveLocation.isEmpty ? 'Not set' : themeService.settings.defaultSaveLocation),
                    leading: const Icon(Icons.save),
                    onTap: _pickDirectory,
                  ),
                ],
              ),

              // Security section
              _buildSettingsCard(
                context: context,
                title: 'Security',
                icon: Icons.security,
                children: [
                  SwitchListTile(
                    title: const Text('Enable Encryption'),
                    subtitle: const Text('Encrypt file transfers with AES-256'),
                    value: themeService.settings.enableEncryption,
                    onChanged: (value) {
                      themeService.updateEnableEncryption(value);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: _encryptionPinController,
                      decoration: const InputDecoration(
                        labelText: 'Encryption PIN/Passphrase',
                        border: OutlineInputBorder(),
                        helperText: 'Used for encrypting and decrypting data. Keep it secure!',
                      ),
                      obscureText: true,
                      enabled: themeService.settings.enableEncryption,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          themeService.updateEncryptionPin(value);
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Behavior section
              _buildSettingsCard(
                context: context,
                title: 'Behavior',
                icon: Icons.settings,
                children: [
                  SwitchListTile(
                    title: const Text('Auto-Start Server'),
                    subtitle: const Text('Start listening for files when app opens'),
                    value: themeService.settings.autoStartServer,
                    onChanged: (value) {
                      themeService.updateAutoStartServer(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Show Notifications'),
                    subtitle: const Text('Display notifications for file transfers'),
                    value: themeService.settings.showNotifications,
                    onChanged: (value) {
                      themeService.updateShowNotifications(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Confirm Before Sending'),
                    subtitle: const Text('Show confirmation dialog before sending files'),
                    value: themeService.settings.confirmBeforeSending,
                    onChanged: (value) {
                      themeService.updateConfirmBeforeSending(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Confirm Before Receiving'),
                    subtitle: const Text('Show confirmation dialog before receiving files'),
                    value: themeService.settings.confirmBeforeReceiving,
                    onChanged: (value) {
                      themeService.updateConfirmBeforeReceiving(value);
                    },
                  ),
                ],
              ),

              // About section
              _buildSettingsCard(
                context: context,
                title: 'About',
                icon: Icons.info_outline,
                children: [
                  const ListTile(title: Text('Toss'), subtitle: Text('A simple app for sharing files and text over LAN'), leading: Icon(Icons.app_shortcut)),
                  FutureBuilder<String>(
                    future: _getAppVersion(),
                    builder: (context, snapshot) {
                      return ListTile(
                        title: const Text('Version'),
                        subtitle: Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : snapshot.hasError
                              ? 'Error loading version'
                              : snapshot.data ?? 'Unknown',
                        ),
                        leading: const Icon(Icons.info_outline),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Developer'),
                    subtitle: const Text('Hunter Lee / Slipstreamm'),
                    leading: const Icon(Icons.person),
                    onTap: () => _launchUrl('https://github.com/Slipstreamm'),
                  ),
                  ListTile(
                    title: const Text('GitHub Repository'),
                    subtitle: const Text('View source code on GitHub'),
                    leading: const Icon(Icons.code),
                    onTap: () => _launchUrl('https://github.com/Slipstreamm/Toss'),
                  ),
                  ListTile(
                    title: const Text('Website'),
                    subtitle: const Text('Visit our website'),
                    leading: const Icon(Icons.language),
                    onTap: () => _launchUrl('https://openotp.lol/toss'),
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('View our privacy policy'),
                    leading: const Icon(Icons.privacy_tip),
                    onTap: () => _launchUrl('https://openotp.lol/toss/privacy'),
                  ),
                  ListTile(
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help with using the app'),
                    leading: const Icon(Icons.help),
                    onTap: () => _launchUrl('https://openotp.lol/toss/support'),
                  ),
                  ListTile(
                    title: const Text('Open Source Licenses'),
                    subtitle: const Text('View licenses for third-party libraries'),
                    leading: const Icon(Icons.source),
                    onTap: () => _showLicensesPage(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
