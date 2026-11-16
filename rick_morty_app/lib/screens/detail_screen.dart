import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart';
import '../services/favorite_service.dart';
import '../widgets/safe_character_image.dart';

class DetailScreen extends StatefulWidget {
  final Character character;

  const DetailScreen({super.key, required this.character});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _favoriteService = FavoriteService();
  bool _isFavorite = false;
  bool _favoritesChanged = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final ids = await _favoriteService.getFavoriteIds();
    if (mounted) {
      setState(() => _isFavorite = ids.contains(widget.character.id));
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _favoriteService.removeFavorite(widget.character.id);
      if (mounted) {
        setState(() {
          _isFavorite = false;
          _favoritesChanged = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.character.name} removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _favoriteService.addFavorite(widget.character);
      if (mounted) {
        setState(() {
          _isFavorite = true;
          _favoritesChanged = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.character.name} added to favorites!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onBack() {
    Navigator.of(context).pop(_favoritesChanged);
  }

  Color get _statusColor => AppTheme.getStatusColor(widget.character.status);

  @override
  Widget build(BuildContext context) {
    final character = widget.character;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(character),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(character),
                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 24),
                    _buildOverviewSection(character),
                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 24),
                    _buildLocationSection(character),
                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 24),
                    _buildEpisodeSection(character),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(character),
      ),
    );
  }

  Widget _buildSliverAppBar(Character character) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryBackground,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: _onBack,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryText, size: 20),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? AppTheme.deadStatus : AppTheme.primaryText,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'character_${character.id}',
              child: SafeCharacterImage(
                imageUrl: character.image,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(Character character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    character.status,
                    style: GoogleFonts.plusJakartaSans(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '#${character.id.toString().padLeft(3, '0')}',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          character.name,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryText,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(Character character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                label: 'Species',
                value: character.species,
                icon: Icons.fingerprint_rounded,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                label: 'Gender',
                value: character.gender,
                icon: Icons.wc_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(Character character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location & Origin',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _buildLocationTile(
          title: 'Origin',
          value: character.originName,
          icon: Icons.public_rounded,
        ),
        const SizedBox(height: 12),
        _buildLocationTile(
          title: 'Last Known Location',
          value: character.locationName,
          icon: Icons.place_outlined,
        ),
      ],
    );
  }

  Widget _buildEpisodeSection(Character character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adventures',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Appeared in ${character.episode.length} episodes throughout the Rick & Morty universe.',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.secondaryText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, color: AppTheme.primaryAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.softAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Unknown',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Character character) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _toggleFavorite,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFavorite ? AppTheme.cardBackground : AppTheme.primaryAccent,
              foregroundColor: _isFavorite ? AppTheme.deadStatus : Colors.white,
              elevation: 0,
              side: _isFavorite
                  ? const BorderSide(color: AppTheme.deadStatus, width: 1.5)
                  : BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
            ),
            label: Text(
              _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
