import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/utils/preferences_helper.dart';
import '../../lists/widgets/list_item.dart';
import '../providers/profile_provider.dart';

class UserWatchlist extends StatelessWidget {
  final List<MovieModel> movies;
  final bool isCurrentUser;
  final bool isLoading;
  final Function(String) onMovieTap;
  final VoidCallback onRefresh;

  const UserWatchlist({
    Key? key,
    required this.movies,
    required this.isCurrentUser,
    required this.isLoading,
    required this.onMovieTap,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && movies.isEmpty) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (movies.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return ListItem(
            movie: movie,
            onTap: () => onMovieTap(movie.id),
            onRemove: isCurrentUser ? () => _removeFromWatchlist(context, movie) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isCurrentUser
                  ? 'Your watchlist is empty'
                  : 'This user has no items in their watchlist',
              style: TextStyles.headline6.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: 8),
              Text(
                'Save movies and TV shows to watch later',
                style: TextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to discover page
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.movie_outlined),
                label: const Text('Discover Movies & TV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _removeFromWatchlist(BuildContext context, MovieModel movie) async {
    // Check if we should skip confirmation
    bool skipConfirm = await PreferencesHelper.getBoolPref(
        PreferencesHelper.skipWatchlistConfirmKey);

    if (skipConfirm) {
      // Remove directly without confirmation
      await Provider.of<ProfileProvider>(context, listen: false)
          .removeFromWatchlist(movie.id);
      onRefresh();
      return;
    }

    // Otherwise show dialog with checkbox
    bool neverAskAgain = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Remove from Watchlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to remove "${movie.title}" from your watchlist?'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: neverAskAgain,
                    onChanged: (value) {
                      setState(() {
                        neverAskAgain = value ?? false;
                      });
                    },
                  ),
                  const Text('Don\'t ask again'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save preference if checked
                if (neverAskAgain) {
                  await PreferencesHelper.saveBoolPref(
                      PreferencesHelper.skipWatchlistConfirmKey, true);
                }

                Navigator.pop(context);
                await Provider.of<ProfileProvider>(context, listen: false)
                    .removeFromWatchlist(movie.id);
                onRefresh();
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}