// lib/features/discover/widgets/movie_grid.dart
import 'package:flutter/material.dart';
import '../../../models/movie_model.dart';
import 'movie_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../../../core/theme/text_styles.dart';

class MovieGrid extends StatelessWidget {
  final List<MovieModel> movies;
  final bool isLoading;
  final String? errorMessage;
  final Function(MovieModel) onMovieTap;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final String emptyMessage;

  const MovieGrid({
    Key? key,
    required this.movies,
    required this.isLoading,
    this.errorMessage,
    required this.onMovieTap,
    this.onRetry,
    this.onLoadMore,
    this.emptyMessage = 'No content found',
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
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyles.headline6.copyWith(
            color: Colors.grey,
          ),
        ),
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
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // Add bottom padding to prevent overflow with navigation bar
          bottom: 80,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58, // to fix the overflow reduced the aspec ratio from 0.6 to 0.55
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