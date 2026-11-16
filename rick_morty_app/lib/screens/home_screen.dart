import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../widgets/safe_character_image.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  List<Character> _characters = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasNextPage = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  Set<int> _favoriteIds = {};
  String _userName = 'Explorer';

  final _apiService = ApiService();
  final _favoriteService = FavoriteService();
  final _authService = AuthService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  StreamSubscription? _favSubscription;

  @override
  bool get wantKeepAlive => true;

  static const _filters = ['all', 'alive', 'dead', 'unknown'];
  static const _filterLabels = {
    'all': 'All',
    'alive': 'Alive',
    'dead': 'Dead',
    'unknown': 'Unknown',
  };

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadFavorites();
    _loadCharacters(reset: true);
    _scrollController.addListener(_onScroll);
    _favSubscription = _favoriteService.onFavoritesChanged.listen((_) {
      if (mounted) _loadFavorites();
    });
  }

  Future<void> _loadUserInfo() async {
    final name = await _authService.getUserName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _userName = name);
    }
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasNextPage && !_isLoading) {
        _loadMoreCharacters();
      }
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await _favoriteService.getFavoriteIds();
    if (mounted) {
      setState(() => _favoriteIds = ids.toSet());
    }
  }

  Future<void> _loadCharacters({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _characters = [];
        _currentPage = 1;
        _hasNextPage = true;
      }
    });
    try {
      final status = _selectedFilter == 'all' ? '' : _selectedFilter;
      final result = await _apiService.getCharacters(
        page: _currentPage,
        status: status,
        name: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _characters = result.results;
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

  Future<void> _loadMoreCharacters() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final status = _selectedFilter == 'all' ? '' : _selectedFilter;
      final result = await _apiService.getCharacters(
        page: _currentPage + 1,
        status: status,
        name: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _currentPage += 1;
          _characters.addAll(result.results);
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

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
        _loadCharacters(reset: true);
      }
    });
  }

  void _onFilterSelected(String filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    _loadCharacters(reset: true);
  }

  Future<void> _toggleFavorite(Character character) async {
    final isFav = _favoriteIds.contains(character.id);
    if (isFav) {
      await _favoriteService.removeFavorite(character.id);
      if (mounted) {
        setState(() => _favoriteIds.remove(character.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${character.name} removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _favoriteService.addFavorite(character);
      if (mounted) {
        setState(() => _favoriteIds.add(character.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${character.name} added to favorites!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _navigateToDetail(Character character) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DetailScreen(character: character),
      ),
    );
    if (result == true) {
      await _loadFavorites();
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
            _buildTopHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HELLO, ${_userName.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore Characters',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Discover the multiverse of Rick & Morty',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showProfileSheet,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border, width: 1.5),
                color: AppTheme.cardBackground,
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.softAccent,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileSheet() async {
    final name = await _authService.getUserName() ?? 'Explorer';
    final email = await _authService.getUserEmail() ?? '';
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.softAccent,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  color: AppTheme.primaryAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deadStatus,
                  side: const BorderSide(color: AppTheme.deadStatus, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Log Out',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                onPressed: () async {
                  await _authService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryText, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search characters by name...',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFADB3AB), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondaryText, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.secondaryText, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onFilterSelected(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryText : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryText : AppTheme.border,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _filterLabels[filter]!,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : AppTheme.secondaryText,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerGrid();
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_characters.isEmpty) {
      return _buildEmptyState();
    }
    return _buildCharacterGrid();
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: const Color(0xFFEBECE8),
        highlightColor: const Color(0xFFF7F8F6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.softAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.primaryAccent,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load characters',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.secondaryText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadCharacters(reset: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppTheme.secondaryText,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No characters found',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different keyword or filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.secondaryText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterGrid() {
    return RefreshIndicator(
      color: AppTheme.primaryAccent,
      backgroundColor: AppTheme.cardBackground,
      onRefresh: () => _loadCharacters(reset: true),
      child: GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.69,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _characters.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= _characters.length) {
            return Shimmer.fromColors(
              baseColor: const Color(0xFFEBECE8),
              highlightColor: const Color(0xFFF7F8F6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }
          final character = _characters[index];
          return _buildCharacterCard(character);
        },
      ),
    );
  }

  Widget _buildCharacterCard(Character character) {
    final isFav = _favoriteIds.contains(character.id);
    final statusColor = AppTheme.getStatusColor(character.status);

    return InkWell(
      onTap: () => _navigateToDetail(character),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character Image with Favorite Icon
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'character_${character.id}',
                    child: SafeCharacterImage(
                      imageUrl: character.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Favorite Button in corner
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(character),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppTheme.deadStatus : AppTheme.primaryText,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Content
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          character.status,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: AppTheme.border, fontSize: 10)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            character.species,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
