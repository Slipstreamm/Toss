import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/theme_service.dart';
import 'screens/settings_screen.dart';
import 'screens/send_screen.dart';
import 'screens/receive_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(MultiProvider(providers: [ChangeNotifierProvider<ThemeService>.value(value: themeService)], child: const FileSharingApp()));
}

class FileSharingApp extends StatelessWidget {
  const FileSharingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'LAN File Share',
      theme: themeService.getLightTheme(),
      darkTheme: themeService.getDarkTheme(),
      themeMode: themeService.themeMode,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // This function is still needed for the SendScreen and ReceiveScreen
  // but we won't display the status in the UI
  void _updateStatus(String status) {
    // We're keeping this function for the screens to call,
    // but not updating any state since we don't display it
    // You could log it for debugging if needed
    // debugPrint('Status update: $status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [SendScreen(onStatusUpdate: _updateStatus), ReceiveScreen(onStatusUpdate: _updateStatus), const SettingsScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Send'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Receive'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
