import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/movie_model.dart';
import '../../lists/widgets/add_to_list_button.dart';

class MovieActions extends StatefulWidget {
  final bool isInWatchlist;
  final bool isInFavorites;
  final Future<bool> Function() onWatchlistToggle;
  final Future<bool> Function() onFavoriteToggle;
  final MovieModel movie;

  const MovieActions({
    Key? key,
    required this.isInWatchlist,
    required this.isInFavorites,
    required this.onWatchlistToggle,
    required this.onFavoriteToggle,
    required this.movie,
  }) : super(key: key);

  @override
  _MovieActionsState createState() => _MovieActionsState();
}

class _MovieActionsState extends State<MovieActions> {
  bool _watchlistLoading = false;
  bool _favoriteLoading = false;

  Future<void> _toggleWatchlist() async {
    if (_watchlistLoading) return;

    setState(() {
      _watchlistLoading = true;
    });

    try {
      final success = await widget.onWatchlistToggle();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isInWatchlist
                  ? 'Removed from watchlist'
                  : 'Added to watchlist',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update watchlist'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _watchlistLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    setState(() {
      _favoriteLoading = true;
    });

    try {
      final success = await widget.onFavoriteToggle();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isInFavorites
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _favoriteLoading = false;
        });
      }
    }
  }

  void _shareMovie() {
    final String title = widget.movie.title;
    final String year = widget.movie.getYear();
    final String genre = widget.movie.getGenreString();
    final String rating = widget.movie.voteAverage.toStringAsFixed(1);

    final String message = 'Check out "$title" ($year)\n'
        'Genre: $genre\n'
        'Rating: $rating/10\n\n'
        'Shared from Cinemax Movie App';

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Watchlist button
        _buildActionColumn(
          icon: _watchlistLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          )
              : Icon(
            widget.isInWatchlist
                ? Icons.bookmark
                : Icons.bookmark_border,
            color: widget.isInWatchlist
                ? AppColors.primary
                : AppColors.textPrimary,
            size: 24,
          ),
          label: 'Watchlist',
          onTap: _toggleWatchlist,
        ),

        // Favorite button
        _buildActionColumn(
          icon: _favoriteLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          )
              : Icon(
            widget.isInFavorites ? Icons.favorite : Icons.favorite_border,
            color: widget.isInFavorites
                ? Colors.red
                : AppColors.textPrimary,
            size: 24,
          ),
          label: 'Favorite',
          onTap: _toggleFavorite,
        ),

        // Lists button
        _buildActionColumn(
          icon: const Icon(
            Icons.playlist_add,
            color: AppColors.textPrimary,
            size: 24,
          ),
          label: 'Lists',
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              backgroundColor: AppColors.cardBackground,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: AddToListButton(
                  movieId: widget.movie.id,
                  isMovie: widget.movie.isMovie,
                ),
              ),
            );
          },
        ),

        // Share button
        _buildActionColumn(
          icon: const Icon(
            Icons.share,
            color: AppColors.textPrimary,
            size: 24,
          ),
          label: 'Share',
          onTap: _shareMovie,
        ),
      ],
    );
  }

  Widget _buildActionColumn({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}