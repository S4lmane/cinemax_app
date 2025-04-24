import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../providers/movie_details_provider.dart';
import '../widgets/movie_header.dart';
import '../widgets/movie_info.dart';
import '../widgets/movie_actions.dart';
import '../widgets/cast_list.dart';
import '../widgets/similar_movies.dart';
import '../widgets/video_section.dart';
import 'fullscreen_poster_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String movieId;
  final bool isMovie;

  const MovieDetailsScreen({
    Key? key,
    required this.movieId,
    this.isMovie = true,
  }) : super(key: key);

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load movie details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovieDetailsProvider>(context, listen: false)
          .getMovieDetails(widget.movieId, isMovie: widget.isMovie);
    });
  }

  @override
  void dispose() {
    // Clear movie data when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Provider.of<MovieDetailsProvider>(context, listen: false).clearMovie();
      }
    });
    super.dispose();
  }

  Future<void> _refreshMovieDetails() async {
    await Provider.of<MovieDetailsProvider>(context, listen: false)
        .getMovieDetails(widget.movieId, isMovie: widget.isMovie);
  }

  void _openFullscreenPoster(String posterUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenPosterScreen(posterUrl: posterUrl),
      ),
    );
  }

  void _shareMovie(String title, String posterUrl, String overview) {
    final String message = 'Check out "$title"\n\n$overview\n\nShared from Cinemax App';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieDetailsProvider>(
      builder: (context, movieDetailsProvider, _) {
        final movie = movieDetailsProvider.movie;
        final isLoading = movieDetailsProvider.isLoading;
        final error = movieDetailsProvider.error;

        if (isLoading && movie == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details'),
              centerTitle: true,
            ),
            body: const Center(
              child: LoadingIndicator(),
            ),
          );
        }

        if (error != null && movie == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details'),
              centerTitle: true,
            ),
            body: app_error.ErrorWidget(
              message: error,
              onRetry: _refreshMovieDetails,
            ),
          );
        }

        if (movie == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details'),
              centerTitle: true,
            ),
            body: const app_error.ErrorWidget(
              message: 'Item not found',
              icon: Icons.movie_filter,
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshMovieDetails,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Movie header with backdrop and poster
                MovieHeader(
                  movie: movie,
                  onPosterTap: () => _openFullscreenPoster(movie.getPosterUrl()),
                ),

                // Status badge
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: movie.isMovie ? Colors.blue : Colors.purple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            movie.isMovie ? 'Movie' : 'TV Show',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ////// type
                        const SizedBox(width: 10),
                        // const Spacer(), // similar to justify-flex: space-between;
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(movie.getStatusBadge()),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            movie.getStatusBadge(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Item Rating
                        // blocked the rating // changed were made
                        /*
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.voteAverage.toStringAsFixed(1),
                                    style: TextStyles.bodyText2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                            ),
                            /*
                            const SizedBox(width: 8),
                            Text(
                              '(${movie.voteCount})',
                              style: TextStyles.bodyText2.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            */
                          ],
                        ),
                        */
                        ////// type
                        // Share button
                        /*
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareMovie(
                            movie.title,
                            movie.getPosterUrl(),
                            movie.overview,
                          ),
                          tooltip: 'Share',
                        ), */
                      ],
                    ),
                  ),
                ),

                // Movie actions (watchlist, favorite, share)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MovieActions(
                      isInWatchlist: movieDetailsProvider.isInWatchlist,
                      isInFavorites: movieDetailsProvider.isInFavorites,
                      onWatchlistToggle: movieDetailsProvider.toggleWatchlist,
                      onFavoriteToggle: movieDetailsProvider.toggleFavorites,
                      movie: movie,
                    ),
                  ),
                ),

                // Movie info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MovieInfo(movie: movie),
                  ),
                ),

                // Cast section
                if (movie.cast.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: CastList(cast: movie.cast),
                    ),
                  ),

                // Videos section (trailers, etc)
                if (movie.videos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: VideoSection(videos: movie.videos),
                    ),
                  ),

                // Similar movies
                if (movie.similar.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SimilarMovies(
                        title: 'Similar ${movie.isMovie ? 'Movies' : 'Shows'}',
                        movies: movie.similar,
                      ),
                    ),
                  ),

                // Recommendations
                if (movie.recommendations.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                      child: SimilarMovies(
                        title: 'You Might Also Like',
                        movies: movie.recommendations,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'released':
      case 'ongoing':
        return Colors.green;
      case 'in production':
      case 'coming soon':
        return Colors.orange;
      case 'planned':
        return Colors.blue;
      case 'ended':
        return Colors.purple;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}