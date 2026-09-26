import 'package:flutter/material.dart';
import '../widgets/job_card.dart';
import '../data/models/job_feed_model.dart';
import '../data/repositories/job_repository.dart';
import 'job_details_screen.dart';

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

  final JobRepository _repository = JobRepository();
  final ScrollController _scrollController = ScrollController();
  List<JobFeedModel> _jobs = [];
  int _currentPage = 1;
  int _totalJobs = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  bool _isEligibleOnly = false;
  bool _isPaidOnly = false;
  String _workArrangement = '';

  String selectedFilter = 'All Roles';
  final List<String> filterChips = [
    'All Roles',
    'AI & ML',
    'Full Stack',
    'Data Science',
    'Cloud & DevOps'
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          _fetchNextPage();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _jobs.clear();
    });
    try {
      final result = await _repository.fetchJobFeed(
        page: _currentPage,
        search: _searchQuery,
        domain: selectedFilter,
        isEligible: _isEligibleOnly,
        isPaidOnly: _isPaidOnly,
        workArrangements: _workArrangement.isNotEmpty ? [_workArrangement] : null,
      );
      setState(() {
        _jobs = result.items;
        _totalJobs = result.totalCount;
        _hasMore = _jobs.length < _totalJobs;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNextPage() async {
    setState(() {
      _isLoading = true;
      _currentPage++;
    });
    try {
      final result = await _repository.fetchJobFeed(
        page: _currentPage,
        search: _searchQuery,
        domain: selectedFilter,
        isEligible: _isEligibleOnly,
        isPaidOnly: _isPaidOnly,
        workArrangements: _workArrangement.isNotEmpty ? [_workArrangement] : null,
      );
      setState(() {
        _jobs.addAll(result.items);
        _hasMore = _jobs.length < _totalJobs;
      });
    } catch (e) {
      setState(() => _currentPage--);
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(child: _buildActiveFilters()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _jobs.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final job = _jobs[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsScreen(jobId: job.jobId),
                        ),
                      );
                    },
                    child: JobCard(
                      jobTitle: job.jobTitle,
                      companyName: job.companyName,
                      matchScore: job.matchScore,
                      location: '${job.locationCity} • ${job.internshipType.isNotEmpty ? job.internshipType.first : 'OnSite'}',
                      stipend: job.stipendOffered ? (job.stipendAmountOrDetails ?? 'Paid') : 'Unpaid',
                      tags: job.tags,
                      imageUrl: 'https://via.placeholder.com/150',
                    ),
                  );
                },
                childCount: _jobs.length + (_hasMore ? 1 : 0),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Showing ${_jobs.length} of $_totalJobs campus drives',
                    style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                  ),
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
                onSubmitted: (value) {
                  _searchQuery = value;
                  _fetchJobs();
                },
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
                _fetchJobs();
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
                GestureDetector(
                  onTap: () {
                    setState(() { _workArrangement = _workArrangement == 'Remote' ? '' : 'Remote'; });
                    _fetchJobs();
                  },
                  child: _buildSubFilter('Work: Remote', Icons.home_work, _workArrangement == 'Remote')
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() { _isPaidOnly = !_isPaidOnly; });
                    _fetchJobs();
                  },
                  child: _buildSubFilter('Paid Only', Icons.payments, _isPaidOnly)
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() { _isEligibleOnly = !_isEligibleOnly; });
                    _fetchJobs();
                  },
                  child: _buildSubFilter('Eligible Jobs', Icons.verified_user, _isEligibleOnly)
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Active:', style: TextStyle(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
              if (_workArrangement.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildActiveTag(_workArrangement),
              ],
              if (_isPaidOnly) ...[
                const SizedBox(width: 8),
                _buildActiveTag('Paid Only'),
              ],
              if (_isEligibleOnly) ...[
                const SizedBox(width: 8),
                _buildActiveTag('Eligible Only'),
              ],
              const Spacer(),
              if (_workArrangement.isNotEmpty || _isPaidOnly || _isEligibleOnly)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _workArrangement = '';
                      _isPaidOnly = false;
                      _isEligibleOnly = false;
                    });
                    _fetchJobs();
                  },
                  child: Text('Clear all', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold))
                ),
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

  // Removed mock data methods

}
