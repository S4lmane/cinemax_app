import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';
import '../providers/movie_details_provider.dart';
import '../screens/movie_details_screen.dart';

class SimilarMovies extends StatelessWidget {
  final String title;
  final List<MovieModel> movies;

  const SimilarMovies({
    super.key,
    required this.title,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.headline5,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180, // Adjusted height to match the poster's height since no title/rating section
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == movies.length - 1 ? 0 : 16,
                ),
                child: _SimilarMovieCard(
                  movie: movie,
                  onTap: () => _navigateToDetails(context, movie),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToDetails(BuildContext context, MovieModel movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MovieDetailsProvider(),
          child: MovieDetailsScreen(
            movieId: movie.id,
            isMovie: movie.isMovie,
          ),
        ),
      ),
    );
  }
}

class _SimilarMovieCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;

  const _SimilarMovieCard({
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: movie.getPosterUrl(size: 'w200'),
            width: 120,
            height: 180,
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
              width: 120,
              height: 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.image_not_supported,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No Image',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}