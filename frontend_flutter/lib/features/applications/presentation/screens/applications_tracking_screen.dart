import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/jobs/presentation/screens/job_details_screen.dart';
import '../../../../core/widgets/global_app_header.dart';

class ApplicationsTrackingScreen extends StatefulWidget {
  const ApplicationsTrackingScreen({super.key});

  @override
  State<ApplicationsTrackingScreen> createState() => _ApplicationsTrackingScreenState();
}

class _ApplicationsTrackingScreenState extends State<ApplicationsTrackingScreen> {

  final Color backgroundColor = AppColors.backgroundLight;
  final Color onSurface = AppColors.textPrimaryLight;
  final Color onSurfaceVariant = AppColors.textSecondaryLight;

  int _selectedTab = 0; // 0: Action, 1: Pending, 2: History
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiService().getApplications();
      if (mounted) {
        setState(() {
          _applications = data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _refresh() async {
    // RefreshIndicator shows its own spinner, so we don't set _isLoading = true.
    try {
      final data = await ApiService().getApplications();
      if (mounted) {
        setState(() {
          _applications = data;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: const GlobalAppHeader(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _applications.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: const GlobalAppHeader(),
        body: Center(
          child: Text('Could not load applications.\n$_errorMessage', textAlign: TextAlign.center),
        ),
      );
    }

    // Categorize applications
    final actionRequired = _applications.where((app) => app['status'] == 'Admin_Approved' || app['status'] == 'Company_Scheduled').toList();
    final pending = _applications.where((app) => app['status'] == 'Pending' || app['status'] == 'Agent_Evaluated').toList();
    final history = _applications.where((app) => app['status'] == 'Student_Accepted' || app['status'] == 'Rejected' || app['status'] == 'Archived').toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const GlobalAppHeader(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(_applications.length),
              const SizedBox(height: 16),
              _buildTabs(actionRequired.length, pending.length, history.length),
              const SizedBox(height: 16),
              
              if (_selectedTab == 0) _buildActionRequiredView(actionRequired),
              if (_selectedTab == 1) _buildPendingView(pending),
              if (_selectedTab == 2) _buildHistoryView(history),
              
              // Add empty state padding if no items in current tab
              if (_selectedTab == 0 && actionRequired.isEmpty ||
                  _selectedTab == 1 && pending.isEmpty ||
                  _selectedTab == 2 && history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text("No applications in this category.", style: TextStyle(color: Colors.grey))),
                )
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHeader(int totalCount) {
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
                    child: Text('$totalCount Total', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              Text('AI Synced', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTabs(int actionCount, int pendingCount, int historyCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildTabItem(0, 'Action Req.', actionCount.toString(), true),
          _buildTabItem(1, 'Pending', pendingCount.toString(), false),
          _buildTabItem(2, 'History', historyCount.toString(), false),
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
                color: isSelected ? AppColors.primary : onSurfaceVariant, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12
              )),
              const SizedBox(width: 6),
              Container(
                width: 20, height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isRedBadge && isSelected && badgeCount != "0" ? const Color(0xFFBA1A1A) : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(badgeCount, style: TextStyle(
                  color: isRedBadge && isSelected && badgeCount != "0" ? Colors.white : onSurface,
                  fontSize: 11, fontWeight: FontWeight.bold
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRequiredView(List<Map<String, dynamic>> items) {
    return Column(
      children: [
        if (items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.priority_high, color: AppColors.primary, size: 20),
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
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildActionCard(item),
        )).toList(),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> item) {
    String company = item['companyName']?.toString() ?? 'Unknown Company';
    String title = item['jobTitle']?.toString() ?? 'Role';
    String? jobId = item['jobId']?.toString();
    
    String? deadlineStr = item['decisionDeadline']?.toString();
    DateTime? deadline = deadlineStr != null ? DateTime.tryParse(deadlineStr)?.toLocal() : null;
    
    String deadlineText = '';
    String closesText = '';
    
    if (deadline != null) {
      final days = deadline.difference(DateTime.now()).inDays;
      if (days > 0) {
        deadlineText = 'Decision deadline: $days days remaining';
      } else if (days == 0) {
        deadlineText = 'Decision deadline: Today';
      } else {
        deadlineText = 'Deadline passed';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      closesText = 'Closes ${months[deadline.month - 1]} ${deadline.day}';
    } else {
      deadlineText = 'Decision deadline: N/A';
      closesText = '';
    }
    
    return GestureDetector(
      onTap: jobId != null ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailsScreen(jobId: jobId)),
        );
      } : null,
      child: Container(
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
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
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
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    const Text('Offer: 21.5 LPA • Full-time', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: AppColors.primaryDark, size: 14),
                    const SizedBox(width: 4),
                    const Text('Offer Extended - Admin Approved', style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Color(0xFF93000A), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(deadlineText, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF93000A), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(closesText, style: const TextStyle(color: Color(0xFF93000A), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (item['status'] == 'Admin_Approved') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                                ),
                                const SizedBox(width: 12),
                                const Text('Confirm Offer', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            content: const Text('Are you sure you want to accept this offer? This will finalize your placement.', style: TextStyle(color: Color(0xFF434655))),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF434655), fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Accept Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (confirm != true) return;

                      try {
                        // Optimistic UI Update
                        setState(() {
                          item['status'] = 'Student_Accepted';
                        });
                        await ApiService().acceptOffer(item['applicationId']?.toString() ?? '');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Accepted!')));
                        }
                        _refresh();
                      } catch (e) {
                        setState(() {
                          item['status'] = 'Admin_Approved';
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
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
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                                ),
                                const SizedBox(width: 12),
                                const Text('Decline Offer', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            content: const Text('Are you sure you want to decline this offer? This action cannot be undone.', style: TextStyle(color: Color(0xFF434655))),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF434655), fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Decline Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm != true) return;

                      try {
                        // Optimistic UI Update
                        setState(() {
                          item['status'] = 'Rejected';
                        });
                        await ApiService().declineOffer(item['applicationId']?.toString() ?? '');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Declined!')));
                        }
                        _refresh();
                      } catch (e) {
                        setState(() {
                          item['status'] = 'Admin_Approved';
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (item['status'] == 'Company_Scheduled') ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        const Text('Interview Confirmed (Check Email)', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          )
        ],
      ),
    ),
  );
}

  Widget _buildPendingView(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) {
        String company = item['companyName']?.toString() ?? 'Unknown Company';
        String title = item['jobTitle']?.toString() ?? 'Role';
        String status = item['status']?.toString() ?? 'Pending';
        String? jobId = item['jobId']?.toString();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: jobId != null ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobDetailsScreen(jobId: jobId)),
              );
            } : null,
            child: _buildPendingCard(
              icon: Icons.account_balance,
              company: company,
              date: 'Applied Recently',
              title: title,
              subtitle: 'Software Engineering',
              badge: 'Pending: $status',
              statusDescription: status == 'Agent_Evaluated' 
                  ? 'Your profile has been evaluated by AI. Awaiting HR review.' 
                  : 'Currently being reviewed by the AI matching system.',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingCard({
    required IconData icon, required String company, required String date,
    required String title, required String subtitle, required String badge,
    String? statusDescription,
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
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(company, style: TextStyle(color: onSurfaceVariant, fontSize: 11), overflow: TextOverflow.ellipsis)),
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
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          if (statusDescription != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(statusDescription, style: TextStyle(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500))),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryView(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) {
        String company = item['companyName']?.toString() ?? 'Unknown Company';
        String title = item['jobTitle']?.toString() ?? 'Role';
        String status = item['status']?.toString() ?? 'Archived';
        String? jobId = item['jobId']?.toString();
        
        bool isAccepted = status == 'Student_Accepted';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: jobId != null ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobDetailsScreen(jobId: jobId)),
              );
            } : null,
            child: _buildHistoryCard(
              icon: isAccepted ? Icons.psychology : Icons.security,
              company: company,
              title: title,
              subtitle: 'Completed Cohort',
              badgeColor: isAccepted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              badgeTextColor: isAccepted ? const Color(0xFF166534) : const Color(0xFF991B1B),
              badgeIcon: isAccepted ? Icons.check : Icons.close,
              badgeText: isAccepted ? 'Accepted' : 'Declined',
            ),
          ),
        );
      }).toList(),
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
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.toUpperCase(), style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
