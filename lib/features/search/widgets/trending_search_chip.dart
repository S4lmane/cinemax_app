import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/trending_search.dart';

class TrendingSearchChip extends StatelessWidget {
  final TrendingSearch trending;
  final VoidCallback onTap;

  const TrendingSearchChip({
    Key? key,
    required this.trending,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                trending.query,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (trending.category.toLowerCase()) {
      case 'genre':
        return Icons.category;
      case 'tv':
        return Icons.tv;
      case 'movies':
        return Icons.movie;
      case 'awards':
        return Icons.emoji_events;
      case 'rating':
        return Icons.star;
      case 'category':
        return Icons.folder;
      default:
        return Icons.search;
    }
  }
}