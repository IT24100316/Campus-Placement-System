import 'package:flutter/material.dart';
import '../../../../features/jobs/presentation/screens/job_feed_screen.dart';
import '../../../../features/applications/presentation/screens/applications_tracking_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  int _currentIndex = 1; // Default to My Resume tab for development

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = const [
      JobFeedScreen(),
      ProfileScreen(), // This is actually the "My Resume" screen we built
      ApplicationsTrackingScreen(),
      Scaffold(body: Center(child: Text("Profile Settings Screen"))), // Placeholder for actual Profile
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
