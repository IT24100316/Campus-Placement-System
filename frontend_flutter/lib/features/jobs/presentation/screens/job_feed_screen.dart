import 'package:flutter/material.dart';
import '../widgets/job_card.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final Color primaryColor = const Color(0xFF003594);
  final Color backgroundColor = const Color(0xFFF8F9FF);
  final Color surfaceColor = Colors.white;
  final Color onSurface = const Color(0xFF0B1C30);
  final Color onSurfaceVariant = const Color(0xFF434655);

  String selectedFilter = 'All Roles';
  final List<String> filterChips = [
    'All Roles',
    'AI & ML',
    'Full Stack',
    'Data Science',
    'Cloud & DevOps'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(child: _buildActiveFilters()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return JobCard(
                    jobTitle: _getJobTitle(index),
                    companyName: _getCompanyName(index),
                    matchScore: 94 - (index * 6),
                    location: 'Remote',
                    stipend: '15+ LPA',
                    tags: _getTags(index),
                    imageUrl: _getImageUrl(index),
                  );
                },
                childCount: 3,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing 1–3 of 18 campus drives',
                    style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: onSurfaceVariant,
                        onPressed: () {}, // TODO: Add logic for previous page
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Page 1 of 6',
                        style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: primaryColor,
                        onPressed: () {}, // TODO: Add logic for next page
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 4,
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
          icon: const Badge(
            child: Icon(Icons.notifications_none),
          ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search roles, skills, or companies...',
                  hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: onSurfaceVariant, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.tune, color: Colors.white, size: 20),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF655DFB),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 1.5),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filterChips.map((chip) {
          final isSelected = selectedFilter == chip;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedFilter = chip;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : const Color(0xFFE6EEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chip == 'All Roles') ...[
                      Icon(Icons.stars, 
                          size: 16, 
                          color: isSelected ? Colors.white : onSurfaceVariant),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      chip,
                      style: TextStyle(
                        color: isSelected ? Colors.white : onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubFilter('Job Type: Full-time', Icons.work, false),
                const SizedBox(width: 8),
                _buildSubFilter('Mode: Remote', Icons.home_work, true),
                const SizedBox(width: 8),
                _buildSubFilter('CTC: 15+ LPA', Icons.payments, false),
                const SizedBox(width: 8),
                _buildSubFilter('Match: ≥ 85%', Icons.speed, true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Active (2):', style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildActiveTag('Remote'),
              const SizedBox(width: 8),
              _buildActiveTag('≥ 85% Match'),
              const Spacer(),
              Text('Clear all', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSubFilter(String text, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDBE1FF) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFC3C6D6).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isActive ? const Color(0xFF00174B) : onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF00174B) : onSurfaceVariant, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 14, color: isActive ? const Color(0xFF00174B) : onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildActiveTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(fontSize: 11, color: onSurface)),
          const SizedBox(width: 4),
          Icon(Icons.close, size: 12, color: onSurface),
        ],
      ),
    );
  }

  String _getJobTitle(int index) {
    if (index == 0) return 'Senior Associate AI Engineer';
    if (index == 1) return 'Autonomous Systems Software Engineer';
    return 'Full Stack Flutter Developer';
  }

  String _getCompanyName(int index) {
    if (index == 0) return 'CloudScale Systems';
    if (index == 1) return 'AeroTech Robotics';
    return 'Starlight Health';
  }

  List<String> _getTags(int index) {
    if (index == 0) return ['Python', 'PyTorch', 'LangChain'];
    if (index == 1) return ['C++20', 'ROS 2', 'CUDA', 'Embedded Linux'];
    return ['Flutter', 'Dart', 'Firebase', 'GraphQL'];
  }
  
  String _getImageUrl(int index) {
    if (index == 0) return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBIbNcaBnnzkmVRWbQyIPDGhIBshvG5VKvITy5CJlwgQCodafOK1KPx03h8uaXLH1G91vy6H9nZNN3koM6LUP8OjwNAnc9crDAVSI84sWKugouNjVT-4AX5sfMgXd99EHex25FCOW6tddvPaILde5EskGU4IJ2hOLlNEbd8YqofIwJrf9PjXX3ctG-v_ClD9fC3VrGxgSxuKMiQWxpbc1cjTnOmLbM0BllPZvWOlbblkptfArJdjiLB';
    if (index == 1) return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAuC0A5lH9kAfgh0FFS0dJH75QJFce7cnfH25ECvJed1se7qUFWKBa7V3MuzvBUndriQYFQ1sP27HbMw8xCPwGTNre1kJlN0IAetmHuvHQh-NdIMJluDoFKEF403EmspJoqdyoBG0pKWWPqcoSDi03H_Hp9sGabNGshv_AZ9Dkx6D_816dUhbYV-2cBMtIt0B5zBn_2Gah7XjTY9OAEwdDPHM9rvGrb1l7VNF_bkOIdZJis2ao0ipcE';
    return 'https://lh3.googleusercontent.com/aida-public/AB6AXuC3s0Varx46LRkMLr_zlHsd0sMZR02ruZH4insrG-cNmld06XiZKpVtY_dJDXoYQJHC1NI2YptVbsCx1onujawCw70AS-aOkAnxEEZUJDIAZbo7jiyX8nkGu2arFiB00zZpS0igIhS6O99e32pTeTPCi8GPegwUCB_LmHcg_7orCPkHKUyJv81NRlKJf-LPIk1ThFg4RMIlXTiJsM-C4Co9HIviUhRl9h7LTWZAPkFeOK4bTuM3zBVq';
  }
}
