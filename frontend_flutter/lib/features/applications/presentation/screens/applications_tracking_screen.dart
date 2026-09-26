import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ApplicationsTrackingScreen extends StatefulWidget {
  const ApplicationsTrackingScreen({super.key});

  @override
  State<ApplicationsTrackingScreen> createState() => _ApplicationsTrackingScreenState();
}

class _ApplicationsTrackingScreenState extends State<ApplicationsTrackingScreen> {
  final Color primaryColor = const Color(0xFF003594);
  final Color backgroundColor = const Color(0xFFF8F9FF);
  final Color onSurface = const Color(0xFF0B1C30);
  final Color onSurfaceVariant = const Color(0xFF434655);

  int _selectedTab = 0; // 0: Action, 1: Pending, 2: History

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            if (_selectedTab == 0) _buildActionRequiredView(),
            if (_selectedTab == 1) _buildPendingView(),
            if (_selectedTab == 2) _buildHistoryView(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor.withOpacity(0.9),
      elevation: 0,
      scrolledUnderElevation: 4,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hub, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CampusAI Portal',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Autonomous Placement',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Badge(child: Icon(Icons.notifications_none)),
          color: onSurfaceVariant,
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: Colors.blue, size: 14),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Applications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)),
                    child: const Text('8 Total', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Track decisions, live rounds & automated status', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE9FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: primaryColor, size: 18),
              const SizedBox(width: 4),
              Text('AI Synced', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE6EEFF), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildTabItem(0, 'Action Req.', '2', true),
          _buildTabItem(1, 'Pending', '3', false),
          _buildTabItem(2, 'History', '3', false),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, String badgeCount, bool isRedBadge) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(
                color: isSelected ? primaryColor : onSurfaceVariant, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12
              )),
              const SizedBox(width: 6),
              Container(
                width: 20, height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isRedBadge && isSelected ? const Color(0xFFBA1A1A) : const Color(0xFFD3E4FE),
                  shape: BoxShape.circle,
                ),
                child: Text(badgeCount, style: TextStyle(
                  color: isRedBadge && isSelected ? Colors.white : onSurface,
                  fontSize: 11, fontWeight: FontWeight.bold
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRequiredView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFDCE9FF), borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.priority_high, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Decisive Responses Needed', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Autonomous placements require confirmed candidate slots within stated institution windows.', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.analytics, color: Color(0xFF003594)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OMNICORE ANALYTICS', style: TextStyle(color: Color(0xFF003594), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text('Data Analyst Fellow', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Business Intelligence & Analytics', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.share, color: onSurfaceVariant, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDCE9FF), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments, color: Color(0xFF003594), size: 14),
                        const SizedBox(width: 4),
                        const Text('Offer: 21.5 LPA • Full-time', style: TextStyle(color: Color(0xFF003594), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDBE1FF), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF003EA8), size: 14),
                        const SizedBox(width: 4),
                        const Text('Offer Extended - Admin Approved', style: TextStyle(color: Color(0xFF003EA8), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFFDAD6).withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Color(0xFF93000A), size: 16),
                        const SizedBox(width: 6),
                        const Text('Decision deadline: 3 days remaining', style: TextStyle(color: Color(0xFF93000A), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Text('Closes Oct 28', style: TextStyle(color: Color(0xFF93000A), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Accept Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPendingView() {
    return Column(
      children: [
        _buildPendingCard(
          icon: Icons.account_balance,
          company: 'FinTrust Global',
          date: 'Applied Oct 14',
          title: 'Backend Developer',
          subtitle: 'Core Payments & Microservices',
          badge: 'Pending: In Screening',
          stage: 'Stage 2 of 5: Technical Resume Parse',
          progress: 0.4,
          checkpointTitle: 'Next checkpoint: AI Rank Verification',
          checkpointValue: 'Est. Oct 26',
        ),
        const SizedBox(height: 16),
        _buildPendingCard(
          icon: Icons.precision_manufacturing,
          company: 'Vanguard Robotics',
          date: 'Applied Oct 12',
          title: 'Frontend Engineer',
          subtitle: 'Autonomous Fleet Cockpit UI',
          badge: 'Pending: AI Assessment Review',
          isQuiz: true,
        ),
        const SizedBox(height: 16),
        _buildPendingCard(
          icon: Icons.hub,
          company: 'Horizon Quantum',
          date: 'Applied Oct 10',
          title: 'Systems Architecture Fellow',
          subtitle: 'R&D Advanced Hardware',
          badge: 'Central Cell Screening',
          isHourglass: true,
        ),
      ],
    );
  }

  Widget _buildPendingCard({
    required IconData icon, required String company, required String date,
    required String title, required String subtitle, required String badge,
    String? stage, double? progress, String? checkpointTitle, String? checkpointValue,
    bool isQuiz = false, bool isHourglass = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF003594)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(company, style: TextStyle(color: onSurfaceVariant, fontSize: 11)),
                        const SizedBox(width: 6),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFC3C6D6), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(date, style: TextStyle(color: onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                    Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFD3E4FE), borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          if (stage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(stage, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('${(progress! * 100).toInt()}% Complete', style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFFE6EEFF), valueColor: AlwaysStoppedAnimation<Color>(primaryColor), borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(checkpointTitle!, style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                Text(checkpointValue!, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            )
          ],
          if (isQuiz)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text('Skill Assessment Submitted', style: TextStyle(color: onSurface, fontSize: 12)),
                    ],
                  ),
                  const Text('Score: 94/100', style: TextStyle(color: Color(0xFF4B41E1), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          if (isHourglass)
            Row(
              children: [
                const Icon(Icons.hourglass_top, color: Color(0xFF004260), size: 18),
                const SizedBox(width: 8),
                Text('Dean of Placements reviewing shortlist batch', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        _buildHistoryCard(
          icon: Icons.psychology,
          company: 'DEEPMIND LABS',
          title: 'ML Research Intern',
          subtitle: 'Completed Sep 2025 • Summer Cohort',
          badgeColor: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF166534),
          badgeIcon: Icons.check,
          badgeText: 'Accepted',
          footer: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Final Evaluation: Exceeded Expectations', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                Text('View Letter', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.9,
          child: _buildHistoryCard(
            icon: Icons.security,
            company: 'SHIELDCORP',
            title: 'Cybersecurity Analyst',
            subtitle: 'Closed Aug 2025 • Candidate opted out',
            badgeColor: const Color(0xFFFEE2E2),
            badgeTextColor: const Color(0xFF991B1B),
            badgeIcon: Icons.close,
            badgeText: 'Declined',
            footer: Text('Candidate accepted another position during institutional clearance period.', style: TextStyle(color: onSurfaceVariant, fontSize: 12))
          ),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.8,
          child: _buildHistoryCard(
            icon: Icons.insights,
            company: 'APEX QUANTITATIVE',
            title: 'Quant Developer Co-op',
            subtitle: 'Closed Jul 2025 • Quota Reached',
            badgeColor: const Color(0xFFD3E4FE),
            badgeTextColor: const Color(0xFF434655),
            badgeText: 'Archived',
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required IconData icon, required String company, required String title, required String subtitle,
    required Color badgeColor, required Color badgeTextColor, IconData? badgeIcon, required String badgeText,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF003594)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company, style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null) ...[Icon(badgeIcon, color: badgeTextColor, size: 14), const SizedBox(width: 4)],
                    Text(badgeText, style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer,
          ]
        ],
      ),
    );
  }
}
