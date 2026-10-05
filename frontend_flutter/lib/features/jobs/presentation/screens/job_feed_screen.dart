import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/global_app_header.dart';
import '../../data/models/job_feed_model.dart';
import '../../data/repositories/job_repository.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';

enum _JobSort { newest, closingSoon, companyAZ }

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  static const _workLabels = {
    'onsite': 'On-site',
    'hybrid': 'Hybrid',
    'remote': 'Remote',
  };
  static const _workApiValues = {
    'onsite': 'OnSite',
    'hybrid': 'Hybrid',
    'remote': 'Remote',
  };

  final _repository = JobRepository();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final Set<String> _supportedWorkTypes = {};
  List<JobFeedModel> _jobs = [];
  int _currentPage = 1;
  int _totalJobs = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _searchQuery = '';
  RangeValues _gpaRange = const RangeValues(2, 4);
  final List<int> _selectedYears = [];
  final Set<String> _selectedWorkTypes = {};
  _JobSort _sort = _JobSort.newest;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _scrollController.addListener(() {
      final nearEnd =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200;
      if (nearEnd && !_isLoading && _hasMore) _fetchNextPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _jobs = [];
    });
    try {
      final result = await _fetchPage(_currentPage);
      if (!mounted) return;
      setState(() {
        _jobs = result.items;
        _totalJobs = result.totalCount;
        _hasMore = _jobs.length < _totalJobs;
        _recordWorkTypes(result.items, reset: _selectedWorkTypes.isEmpty);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load jobs. Please try again.';
        _isLoading = false;
      });
      debugPrint('Unable to load jobs: $error');
    }
  }

  Future<void> _fetchNextPage() async {
    setState(() => _isLoading = true);
    final nextPage = _currentPage + 1;
    try {
      final result = await _fetchPage(nextPage);
      if (!mounted) return;
      setState(() {
        _currentPage = nextPage;
        _jobs.addAll(result.items);
        _hasMore = _jobs.length < _totalJobs;
        _recordWorkTypes(result.items);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load more jobs. Please try again.';
        _isLoading = false;
      });
      debugPrint('Unable to load more jobs: $error');
    }
  }

  Future<PaginatedJobFeed> _fetchPage(int page) {
    return _repository.fetchJobFeed(
      page: page,
      search: _searchQuery,
      minGpa: _gpaRange.start,
      maxGpa: _gpaRange.end,
      allowedYears: _selectedYears.isEmpty ? null : _selectedYears,
      workArrangements: _selectedWorkTypes
          .map((type) => _workApiValues[type]!)
          .toList(),
      sortBy: _sortByApiValue,
    );
  }

  void _recordWorkTypes(Iterable<JobFeedModel> jobs, {bool reset = false}) {
    if (reset) _supportedWorkTypes.clear();
    for (final job in jobs) {
      for (final type in job.internshipType) {
        final normalized = _normalizeWorkType(type);
        if (_workLabels.containsKey(normalized)) {
          _supportedWorkTypes.add(normalized);
        }
      }
    }
  }

  List<JobFeedModel> get _visibleJobs {
    if (_selectedWorkTypes.isEmpty) return _jobs;
    return _jobs.where((job) {
      return job.internshipType
          .map(_normalizeWorkType)
          .any(_selectedWorkTypes.contains);
    }).toList();
  }

  String get _sortByApiValue {
    switch (_sort) {
      case _JobSort.newest:
        return 'recent';
      case _JobSort.closingSoon:
        return 'deadline';
      case _JobSort.companyAZ:
        return 'company';
    }
  }

  String _sortLabel(_JobSort value) {
    switch (value) {
      case _JobSort.newest:
        return 'Newest';
      case _JobSort.closingSoon:
        return 'Closing soon';
      case _JobSort.companyAZ:
        return 'Company A-Z';
    }
  }

  static String _normalizeWorkType(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
  }

  bool get _hasNewFilters {
    return _selectedWorkTypes.isNotEmpty || _sort != _JobSort.newest;
  }

  void _clearNewFilters() {
    setState(() {
      _selectedWorkTypes.clear();
      _sort = _JobSort.newest;
    });
    _fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _visibleJobs;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const GlobalAppHeader(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildPageIntro()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          if (_hasNewFilters) SliverToBoxAdapter(child: _buildFilterState()),
          _buildJobsSliver(jobs),
          if (_jobs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 24,
                ),
                child: Text(
                  'Showing ${jobs.length} of $_totalJobs campus drives',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIntro() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jobs',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Explore internship opportunities',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSliver(List<JobFeedModel> jobs) {
    if (_isLoading && _jobs.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_errorMessage != null && _jobs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _JobFeedError(onRetry: _fetchJobs),
      );
    }
    if (jobs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 48,
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No jobs match these filters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Try changing or clearing your filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (_hasNewFilters) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _clearNewFilters,
                    child: const Text('Clear all'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == jobs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final job = jobs[index];
          return JobCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobDetailsScreen(jobId: job.jobId),
                ),
              );
            },
            jobTitle: job.jobTitle,
            companyName: job.companyName,
            locationCity: job.locationCity,
            internshipTypes: job.internshipType,
            targetDomain: job.targetDomain,
            tags: job.tags,
            applicationDeadline: job.applicationDeadline,
          );
        }, childCount: jobs.length + (_hasMore ? 1 : 0)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  setState(() => _searchQuery = value.trim());
                  _fetchJobs();
                },
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search roles, skills, companies...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _showFilterBottomSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune, color: Colors.white, size: 20),
                  if (_hasNewFilters)
                    const Positioned(
                      top: -3,
                      right: -3,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.statusPending,
                        child: Icon(Icons.check, color: Colors.white, size: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final type in _selectedWorkTypes)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_workLabels[type]!),
                  ),
                if (_sort != _JobSort.newest)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_sortLabel(_sort)),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearNewFilters,
            child: const Text('Clear all'),
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
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filters and sort',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _clearNewFilters();
                            },
                            child: const Text('Clear all'),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderLight),
                      const SizedBox(height: 18),
                      const Text('Sort by', style: _filterHeadingStyle),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final sort in _JobSort.values)
                            ChoiceChip(
                              label: Text(_sortLabel(sort)),
                              selected: _sort == sort,
                              onSelected: (_) =>
                                  setModalState(() => _sort = sort),
                            ),
                        ],
                      ),
                      if (_supportedWorkTypes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Work type', style: _filterHeadingStyle),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final type in _workLabels.keys)
                              if (_supportedWorkTypes.contains(type))
                                FilterChip(
                                  label: Text(_workLabels[type]!),
                                  selected: _selectedWorkTypes.contains(type),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedWorkTypes.add(type);
                                      } else {
                                        _selectedWorkTypes.remove(type);
                                      }
                                    });
                                  },
                                ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('GPA range', style: _filterHeadingStyle),
                      Row(
                        children: [
                          Text(_gpaRange.start.toStringAsFixed(1)),
                          Expanded(
                            child: RangeSlider(
                              values: _gpaRange,
                              min: 0,
                              max: 4,
                              divisions: 40,
                              activeColor: AppColors.primary,
                              onChanged: (value) =>
                                  setModalState(() => _gpaRange = value),
                            ),
                          ),
                          Text(_gpaRange.end.toStringAsFixed(1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Year of study', style: _filterHeadingStyle),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final year in [1, 2, 3, 4])
                            FilterChip(
                              label: Text('Year $year'),
                              selected: _selectedYears.contains(year),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    _selectedYears.add(year);
                                  } else {
                                    _selectedYears.remove(year);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _fetchJobs();
                          },
                          child: const Text('Apply filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

const _filterHeadingStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimaryLight,
);

class _JobFeedError extends StatelessWidget {
  const _JobFeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load jobs',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
