import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final List<Widget?> _cachedScreens = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getScreen(int index) {
    // Cache screens once they're built
    if (_cachedScreens[index] != null) {
      return _cachedScreens[index]!;
    }

    Widget screen;
    switch (index) {
      case 0:
        screen = HomeScreen(
          key: const ValueKey('home'),
          onNavigateToReports: () => switchToTab(1),
          onNavigateToProfile: () => switchToTab(3),
        );
        break;
      case 1:
        screen = const ReportsScreen(key: ValueKey('reports'));
        break;
      case 2:
        screen = const InsightsScreen(key: ValueKey('insights'));
        break;
      case 3:
        screen = const ProfileScreen(key: ValueKey('profile'));
        break;
      default:
        screen = Container();
    }

    _cachedScreens[index] = screen;
    return screen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            print('🔴 MainScreen: Navigating to tab $index');
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
