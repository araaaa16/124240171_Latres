import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class SafeCharacterImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafeCharacterImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Shimmer.fromColors(
            baseColor: const Color(0xFFEBECE8),
            highlightColor: const Color(0xFFF7F8F6),
            child: Container(
              color: const Color(0xFFF0F2EE),
              width: width,
              height: height,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFECEEEA),
          width: width,
          height: height,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: AppTheme.secondaryText,
              size: 30,
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: const Color(0xFFEBECE8),
        highlightColor: const Color(0xFFF7F8F6),
        child: Container(
          color: const Color(0xFFF0F2EE),
          width: width,
          height: height,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFECEEEA),
        width: width,
        height: height,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: AppTheme.secondaryText,
            size: 30,
          ),
        ),
      ),
    );
  }
}
