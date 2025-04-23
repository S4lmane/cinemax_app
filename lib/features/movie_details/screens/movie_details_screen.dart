import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../providers/movie_details_provider.dart';
import '../widgets/movie_header.dart';
import '../widgets/movie_info.dart';
import '../widgets/movie_actions.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailsScreen({
    Key? key,
    required this.movieId,
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
          .getMovieDetails(widget.movieId);
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
        .getMovieDetails(widget.movieId);
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
              title: const Text('Movie Details'),
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
              title: const Text('Movie Details'),
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
              title: const Text('Movie Details'),
              centerTitle: true,
            ),
            body: const app_error.ErrorWidget(
              message: 'Movie not found',
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
                MovieHeader(movie: movie),

                // Movie info section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Movie actions (watchlist, favorite, share)
                        MovieActions(
                          isInWatchlist: movieDetailsProvider.isInWatchlist,
                          isInFavorites: movieDetailsProvider.isInFavorites,
                          onWatchlistToggle: movieDetailsProvider.toggleWatchlist,
                          onFavoriteToggle: movieDetailsProvider.toggleFavorites,
                          movie: movie,
                        ),

                        const SizedBox(height: 24),

                        // Movie info
                        MovieInfo(movie: movie),
                      ],
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