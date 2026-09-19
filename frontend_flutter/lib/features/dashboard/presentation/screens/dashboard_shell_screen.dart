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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    JobFeedScreen(),
    ApplicationsTrackingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
