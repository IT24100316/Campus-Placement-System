import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/job_card.dart';
import '../../data/models/job_feed_model.dart';
import '../../data/repositories/job_repository.dart';
import 'job_details_screen.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final JobRepository _repository = JobRepository();
  final ScrollController _scrollController = ScrollController();
  List<JobFeedModel> _jobs = [];
  int _currentPage = 1;
  int _totalJobs = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';

  RangeValues _gpaRange = const RangeValues(2.0, 4.0);
  List<int> _selectedYears = [];

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
        minGpa: _gpaRange.start,
        maxGpa: _gpaRange.end,
        allowedYears: _selectedYears.isNotEmpty ? _selectedYears : null,
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
        minGpa: _gpaRange.start,
        maxGpa: _gpaRange.end,
        allowedYears: _selectedYears.isNotEmpty ? _selectedYears : null,
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
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          if (_jobs.isEmpty && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline, size: 48, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text('No jobs found', style: TextStyle(fontSize: 15, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _jobs.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                        imageUrl: '',
                      ),
                    );
                  },
                  childCount: _jobs.length + (_hasMore ? 1 : 0),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
              child: Text(
                'Showing ${_jobs.length} of $_totalJobs campus drives',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'CampusAI Portal',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Autonomous Placement',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
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
            backgroundColor: Colors.red,
            child: Icon(Icons.notifications_none),
          ),
          color: AppColors.textSecondaryLight,
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 4),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: AppColors.primary, size: 14),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search roles, skills, companies...',
                  hintStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryLight, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced Filters',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight, letterSpacing: -0.5)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondaryLight),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 20),
                  const Text('GPA Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _gpaRange.start.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimaryLight),
                      ),
                      Expanded(
                        child: RangeSlider(
                          values: _gpaRange,
                          min: 0.0,
                          max: 4.0,
                          divisions: 40,
                          labels: RangeLabels(
                            _gpaRange.start.toStringAsFixed(1),
                            _gpaRange.end.toStringAsFixed(1),
                          ),
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.primary.withValues(alpha: 0.15),
                          onChanged: (RangeValues values) {
                            setModalState(() {
                              _gpaRange = values;
                            });
                          },
                        ),
                      ),
                      Text(
                        _gpaRange.end.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Year of Study', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [1, 2, 3, 4].map((year) {
                      final isSelected = _selectedYears.contains(year);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              _selectedYears.remove(year);
                            } else {
                              _selectedYears.add(year);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            'Year $year',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchJobs();
                      },
                      child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
