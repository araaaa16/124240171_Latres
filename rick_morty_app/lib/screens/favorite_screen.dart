import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart';
import '../services/favorite_service.dart';
import '../widgets/safe_character_image.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with AutomaticKeepAliveClientMixin {
  final _favoriteService = FavoriteService();
  StreamSubscription? _favSubscription;
  List<Character> _favorites = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _favSubscription = _favoriteService.onFavoritesChanged.listen((_) {
      if (mounted) _loadFavorites(silent: true);
    });
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final favs = await _favoriteService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToDetail(Character character) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(character: character)),
    );
    await _loadFavorites(silent: true);
  }

  Future<void> _removeFavorite(Character character) async {
    final removed = character;
    await _favoriteService.removeFavorite(character.id);
    setState(() => _favorites.removeWhere((c) => c.id == character.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removed.name} removed from favorites'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppTheme.primaryAccent,
            onPressed: () async {
              await _favoriteService.addFavorite(removed);
              _loadFavorites(silent: true);
            },
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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
            Container(
              color: AppTheme.primaryBackground,
              width: double.infinity,
              child: _buildHeader(),
            ),
            Expanded(
              child: ClipRect(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                      )
                    : _favorites.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppTheme.primaryAccent,
                            backgroundColor: AppTheme.cardBackground,
                            onRefresh: () => _loadFavorites(silent: true),
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              clipBehavior: Clip.hardEdge,
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _favorites.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final character = _favorites[index];
                                return _buildDismissibleCard(character);
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Favorites',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primaryText,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your favorite characters across the multiverse',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (_favorites.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.softAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_favorites.length}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primaryAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(Character character) {
    return Dismissible(
      key: Key('fav_${character.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.deadStatus.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.deadStatus,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: AppTheme.deadStatus, size: 24),
          ],
        ),
      ),
      onDismissed: (_) => _removeFavorite(character),
      child: _buildHorizontalCharacterCard(character),
    );
  }

  Widget _buildHorizontalCharacterCard(Character character) {
    final statusColor = AppTheme.getStatusColor(character.status);

    return InkWell(
      onTap: () => _navigateToDetail(character),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Row(
          children: [
            // Character Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: kIsWeb
                    ? SafeCharacterImage(
                        imageUrl: character.image,
                        fit: BoxFit.cover,
                      )
                    : Hero(
                        tag: 'fav_char_${character.id}',
                        child: SafeCharacterImage(
                          imageUrl: character.image,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info Column
            Expanded(
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
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        character.status,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          character.species,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (character.locationName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppTheme.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            character.locationName,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Favorite Red Button
            GestureDetector(
              onTap: () => _removeFavorite(character),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.deadStatus.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.deadStatus,
                  size: 18,
                ),
              ),
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: AppTheme.secondaryText,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No favorites yet',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore characters from the home tab and tap the heart icon to save them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
