import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../../../models/cast_model.dart';
import '../../../models/movie_model.dart';
import '../../../models/video_model.dart';
import '../providers/movie_details_provider.dart';
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
    super.key,
    required this.movieId,
    this.isMovie = true,
  });

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch movie details after the first frame to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MovieDetailsProvider>(context, listen: false)
            .getMovieDetails(widget.movieId, isMovie: widget.isMovie);
      }
    });
  }

  @override
  void dispose() {
    // Clear movie data directly without scheduling
    Provider.of<MovieDetailsProvider>(context, listen: false).clearMovie();
    super.dispose();
  }

  Future<void> _refreshMovieDetails() async {
    await Provider.of<MovieDetailsProvider>(context, listen: false)
        .getMovieDetails(widget.movieId, isMovie: widget.isMovie);
  }

  void _openFullscreenPoster(String? posterUrl) {
    if (posterUrl != null && posterUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullscreenPosterScreen(posterUrl: posterUrl),
        ),
      );
    }
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'released':
      case 'ongoing':
        return Icons.check_circle;
      case 'in production':
        return Icons.build;
      case 'coming soon':
        return Icons.schedule;
      case 'planned':
        return Icons.event;
      case 'ended':
        return Icons.stop_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green;
    if (rating >= 6.0) return Colors.orange;
    if (rating >= 4.0) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieDetailsProvider>(
      builder: (context, movieDetailsProvider, _) {
        final movie = movieDetailsProvider.movie;
        final isLoading = movieDetailsProvider.isLoading;
        final error = movieDetailsProvider.error;

        // Show loading screen if data is being fetched and no movie data is available
        if (isLoading && movie == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details'),
              centerTitle: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  tooltip: 'Home',
                ),
              ],
            ),
            body: const Center(
              child: LoadingIndicator(),
            ),
          );
        }

        // Show error screen if there's an error and no movie data
        if (error != null && movie == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details'),
              centerTitle: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  tooltip: 'Home',
                ),
              ],
            ),
            body: app_error.ErrorWidget(
              message: error,
              onRetry: _refreshMovieDetails,
            ),
          );
        }

        // Fallback for null movie
        if (movie == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details'),
              centerTitle: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  tooltip: 'Home',
                ),
              ],
            ),
            body: const app_error.ErrorWidget(
              message: 'Item not found',
              icon: Icons.movie_filter,
            ),
          );
        }

        // Debug prints for movie data
        print('Movie: ${movie.title}');
        print('Cast: ${movie.cast}');
        print('Videos: ${movie.videos}');
        print('Similar: ${movie.similar}');
        print('Recommendations: ${movie.recommendations}');
        print('Status: ${movie.status}');
      
        final contentTypeColor = movie.isMovie ? Colors.blue : Colors.purple;
        final statusColor = _getStatusColor(movie.getStatusBadge());
        final List<CastModel> cast = movie.cast ?? [];
        final List<VideoModel> videos = movie.videos ?? [];
        final List<MovieModel> similar = movie.similar ?? [];
        final List<MovieModel> recommendations = movie.recommendations ?? [];

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshMovieDetails,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 350,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.home),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      tooltip: 'Home',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: movie.getBackdropUrl(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.cardBackground,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.cardBackground,
                            child: const Icon(
                              Icons.movie,
                              color: AppColors.textSecondary,
                              size: 50,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => _openFullscreenPoster(movie.getPosterUrl()),
                                child: Hero(
                                  tag: 'poster_${movie.id}',
                                  child: Container(
                                    width: 100,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: movie.getPosterUrl(size: 'w200'),
                                            fit: BoxFit.cover,
                                            height: 200,
                                            width: 150,
                                            placeholder: (context, url) => Container(
                                              color: AppColors.cardBackground,
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: AppColors.cardBackground,
                                              child: const Icon(
                                                Icons.movie,
                                                color: AppColors.textSecondary,
                                                size: 50,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            bottom: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      movie.title,
                                      style: TextStyles.headline4.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          movie.getYear(),
                                          style: TextStyles.bodyText2.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        if (movie.runtime > 0) ...[
                                          const SizedBox(width: 8),
                                          const Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            movie.getFormattedRuntime(),
                                            style: TextStyles.bodyText2.copyWith(
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: contentTypeColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: contentTypeColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                movie.isMovie ? Icons.movie : Icons.tv,
                                color: contentTypeColor,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.isMovie ? 'Movie' : 'TV Show',
                                style: TextStyle(
                                  color: contentTypeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(movie.getStatusBadge()),
                                color: statusColor,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.getStatusBadge(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRatingColor(movie.voteAverage).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRatingColor(movie.voteAverage),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: _getRatingColor(movie.voteAverage),
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: TextStyles.bodyText2.copyWith(
                                  color: _getRatingColor(movie.voteAverage),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: MovieActions(
                      isInWatchlist: movieDetailsProvider.isInWatchlist,
                      isInFavorites: movieDetailsProvider.isInFavorites,
                      onWatchlistToggle: movieDetailsProvider.toggleWatchlist,
                      onFavoriteToggle: movieDetailsProvider.toggleFavorites,
                      movie: movie,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MovieInfo(movie: movie),
                  ),
                ),
                if (cast.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: CastList(cast: cast),
                    ),
                  ),
                if (videos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: VideoSection(videos: videos),
                    ),
                  ),
                if (similar.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SimilarMovies(
                        title: 'Similar ${movie.isMovie ? 'Movies' : 'Shows'}',
                        movies: similar,
                      ),
                    ),
                  ),
                if (recommendations.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                      child: SimilarMovies(
                        title: 'You Might Also Like',
                        movies: recommendations,
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
}