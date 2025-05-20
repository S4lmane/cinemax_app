import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class UserStats extends StatelessWidget {
  final int listsCount;
  final int watchlistCount;
  final int favoritesCount;

  const UserStats({
    super.key,
    required this.listsCount,
    required this.watchlistCount,
    required this.favoritesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn('Lists', listsCount, Icons.playlist_play),
          _buildDivider(),
          _buildStatColumn('Watchlist', watchlistCount, Icons.bookmark),
          _buildDivider(),
          _buildStatColumn('Favorites', favoritesCount, Icons.favorite),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyles.headline5,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyles.bodyText2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textSecondary.withOpacity(0.2),
    );
  }
}