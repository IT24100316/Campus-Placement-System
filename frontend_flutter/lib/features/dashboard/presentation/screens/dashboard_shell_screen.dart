import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../../features/jobs/presentation/screens/job_feed_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../../../features/applications/presentation/screens/applications_tracking_screen.dart';

class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Re-initialize screens here so they reflect hot-reloads properly when developing
    final List<Widget> screens = const [
      JobFeedScreen(),
      ProfileScreen(),
      ApplicationsTrackingScreen(),
      ProfileSettingsScreen(), // Now using the actual Profile Settings Screen
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
