import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/notification_service.dart';
import '../../../models/movie_model.dart';
import '../../profile/providers/profile_provider.dart';

class MovieActions extends StatefulWidget {
  final bool isInWatchlist;
  final bool isInFavorites;
  final Future<bool> Function() onWatchlistToggle;
  final Future<bool> Function() onFavoriteToggle;
  final MovieModel movie;

  const MovieActions({
    super.key,
    required this.isInWatchlist,
    required this.isInFavorites,
    required this.onWatchlistToggle,
    required this.onFavoriteToggle,
    required this.movie,
  });

  @override
  _MovieActionsState createState() => _MovieActionsState();
}

class _MovieActionsState extends State<MovieActions> {
  bool _watchlistLoading = false;
  bool _favoriteLoading = false;
  bool _listsLoading = false;

  Future<void> _toggleWatchlist() async {
    if (_watchlistLoading) return;

    setState(() {
      _watchlistLoading = true;
    });

    try {
      final success = await widget.onWatchlistToggle();

      if (success && mounted) {
        NotificationService.showSuccess(
          context,
          widget.isInWatchlist
              ? 'Removed from watchlist'
              : 'Added to watchlist',
        );
      } else if (mounted) {
        NotificationService.showError(
          context,
          'Failed to update watchlist',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Error: $e',
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
        NotificationService.showSuccess(
          context,
          widget.isInFavorites
              ? 'Removed from favorites'
              : 'Added to favorites',
        );
      } else if (mounted) {
        NotificationService.showError(
          context,
          'Failed to update favorites',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Error: $e',
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

  Future<void> _showAddToListModal() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.userLists.isEmpty) {
      setState(() {
        _listsLoading = true;
      });
      try {
        final user = profileProvider.currentUser;
        if (user == null) {
          throw Exception('No authenticated user found');
        }
        await profileProvider.getUserLists(user.uid);
      } catch (e) {
        if (mounted) {
          NotificationService.showError(
            context,
            'Failed to load lists: $e',
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() {
            _listsLoading = false;
          });
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      backgroundColor: AppColors.cardBackground,
      builder: (context) {
        final lists = profileProvider.userLists;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (lists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No lists available. Create a list first.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return ListTile(
                      title: Text(
                        list.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        list.isPublic ? 'Public' : 'Private',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);

                        setState(() {
                          _listsLoading = true;
                        });
                        try {
                          final success = await profileProvider.addItemToList(
                            list.id,
                            widget.movie.id.toString(),
                          );
                          if (success && mounted) {
                            NotificationService.showSuccess(
                              context,
                              'Added to "${list.name}"',
                            );
                          } else if (mounted) {
                            NotificationService.showError(
                              context,
                              profileProvider.error ?? 'Failed to add to list',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            NotificationService.showError(
                              context,
                              'Error: $e',
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _listsLoading = false;
                            });
                          }
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
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
    NotificationService.showToast(
      context,
      'Sharing "${widget.movie.title}"',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildActionColumn(
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
          ),
          Expanded(
            child: _buildActionColumn(
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
                widget.isInFavorites
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.isInFavorites
                    ? Colors.red
                    : AppColors.textPrimary,
                size: 24,
              ),
              label: 'Favorite',
              onTap: _toggleFavorite,
            ),
          ),
          Expanded(
            child: _buildActionColumn(
              icon: _listsLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
                  : const Icon(
                Icons.playlist_add,
                color: AppColors.textPrimary,
                size: 24,
              ),
              label: 'Lists',
              onTap: _showAddToListModal,
            ),
          ),
          Expanded(
            child: _buildActionColumn(
              icon: const Icon(
                Icons.share,
                color: AppColors.textPrimary,
                size: 24,
              ),
              label: 'Share',
              onTap: _shareMovie,
            ),
          ),
        ],
      ),
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