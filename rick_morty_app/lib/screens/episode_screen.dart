import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/episode_model.dart';
import '../services/api_service.dart';

class EpisodeScreen extends StatefulWidget {
  const EpisodeScreen({super.key});

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen>
    with AutomaticKeepAliveClientMixin {
  final _apiService = ApiService();
  final _scrollController = ScrollController();

  List<Episode> _episodes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasNextPage = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEpisodes(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      if (!_isLoadingMore && _hasNextPage && !_isLoading) {
        _loadMoreEpisodes();
      }
    }
  }

  Future<void> _loadEpisodes({bool reset = false}) async {
    if (_isLoading && !reset) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _episodes = [];
        _currentPage = 1;
        _hasNextPage = true;
      }
    });
    try {
      final result = await _apiService.getEpisodes(page: _currentPage);
      if (mounted) {
        setState(() {
          _episodes = result.results;
          _hasNextPage = result.info.next != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreEpisodes() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _apiService.getEpisodes(page: _currentPage + 1);
      if (mounted) {
        setState(() {
          _currentPage += 1;
          _episodes.addAll(result.results);
          _hasNextPage = result.info.next != null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Episodes',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discover every adventure',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (_episodes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.softAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_episodes.length} episodes',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmerList();
    if (_error != null) return _buildErrorState();
    return RefreshIndicator(
      color: AppTheme.primaryAccent,
      backgroundColor: AppTheme.cardBackground,
      onRefresh: () => _loadEpisodes(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _episodes.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _episodes.length) {
            return _buildLoadingMoreIndicator();
          }
          return _buildEpisodeCard(_episodes[index]);
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 6,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: const Color(0xFFEBECE8),
        highlightColor: const Color(0xFFF7F8F6),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.softAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppTheme.primaryAccent, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load episodes',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadEpisodes(reset: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEBECE8),
      highlightColor: const Color(0xFFF7F8F6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildEpisodeCard(Episode episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Episode Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.softAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              episode.episode,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.secondaryText),
                    const SizedBox(width: 5),
                    Text(
                      episode.airDate,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: AppTheme.border, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(
                      '${episode.characters.length} characters',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
