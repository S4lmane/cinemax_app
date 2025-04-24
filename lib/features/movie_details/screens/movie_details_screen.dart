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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MovieDetailsProvider>(context, listen: false)
            .getMovieDetails(widget.movieId, isMovie: widget.isMovie);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MovieDetailsProvider>(context, listen: false).clearMovie();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieDetailsProvider>(
      builder: (context, movieDetailsProvider, _) {
        final movie = movieDetailsProvider.movie;
        final isLoading = movieDetailsProvider.isLoading;
        final error = movieDetailsProvider.error;

        // Debug logging
        if (movie != null) {
          print('Movie: ${movie.title}');
          print('Cast: ${movie.cast}');
          print('Videos: ${movie.videos}');
          print('Similar: ${movie.similar}');
          print('Recommendations: ${movie.recommendations}');
          print('Status: ${movie.status}');
        }

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
                  expandedHeight: 300,
                  pinned: true,
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
                          bottom: 20,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: TextStyles.headline4.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _openFullscreenPoster(movie.getPosterUrl()),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View Poster',
                                      style: TextStyles.bodyText2.copyWith(
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
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
                        const SizedBox(width: 10),
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
                      ],
                    ),
                  ),
                ),
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