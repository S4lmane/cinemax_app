// lib/core/widgets/custom_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import 'custom_fallback_poster.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String title;
  final bool isMovie;
  final bool isPoster;

  const CustomImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.title = 'No Title',
    this.isMovie = true,
    this.isPoster = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's an empty URL or contains "null"
    final hasValidImage = imageUrl.isNotEmpty &&
        !imageUrl.contains('null') &&
        !imageUrl.contains('placeholder');

    Widget image;

    if (hasValidImage) {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColors.cardBackground,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    } else {
      image = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildFallback() {
    // Use the custom fallback poster for movie/TV show posters
    if (isPoster) {
      return CustomFallbackPoster(
        title: title,
        isMovie: isMovie,
        width: width,
        height: height,
        borderRadius: 0, // We're already using ClipRRect in the parent
      );
    }

    // Default fallback for other images (like backdrops)
    return Container(
      width: width,
      height: height,
      color: AppColors.cardBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPoster
                  ? (isMovie ? Icons.movie : Icons.tv)
                  : Icons.image_not_supported,
              color: AppColors.textSecondary,
              size: width > 100 ? 48 : 24,
            ),
            if (width > 100) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Image not available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: width > 200 ? 16 : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}