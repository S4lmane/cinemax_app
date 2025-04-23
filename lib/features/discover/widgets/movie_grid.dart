import 'package:flutter/material.dart';
import '../../../models/movie_model.dart';
import 'movie_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;

class MovieGrid extends StatelessWidget {
  final List<MovieModel> movies;
  final bool isLoading;
  final String? errorMessage;
  final Function(MovieModel) onMovieTap;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;

  const MovieGrid({
    Key? key,
    required this.movies,
    required this.isLoading,
    this.errorMessage,
    required this.onMovieTap,
    this.onRetry,
    this.onLoadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && movies.isEmpty) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (errorMessage != null && movies.isEmpty) {
      return app_error.ErrorWidget(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (movies.isEmpty) {
      return const Center(
        child: Text('No movies found'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            !isLoading && onLoadMore != null) {
          onLoadMore!();
        }
        return true;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: movies.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            return const Center(
              child: LoadingIndicator(),
            );
          }

          final movie = movies[index];
          return MovieCard(
            movie: movie,
            onTap: () => onMovieTap(movie),
          );
        },
      ),
    );
  }
}