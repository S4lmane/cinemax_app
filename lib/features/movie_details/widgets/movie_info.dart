import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';

class MovieInfo extends StatelessWidget {
  final MovieModel movie;

  const MovieInfo({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview section
        const Text(
          'Overview',
          style: TextStyles.headline5,
        ),
        const SizedBox(height: 8),
        Text(
          movie.overview.isNotEmpty
              ? movie.overview
              : 'No overview available for this ${movie.isMovie ? 'movie' : 'TV show'}.',
          style: TextStyles.bodyText1.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // Genres section
        const Text(
          'Genres',
          style: TextStyles.headline5,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: movie.genres.isNotEmpty
              ? movie.genres.map((genre) => _buildGenreChip(genre)).toList()
              : [
            _buildGenreChip(
              movie.isMovie ? 'Movie' : 'TV Show',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Additional info section
        if (!movie.isMovie && (movie.numberOfSeasons != null || movie.numberOfEpisodes != null))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TV Show Info',
                style: TextStyles.headline5,
              ),
              const SizedBox(height: 12),
              if (movie.numberOfSeasons != null)
                _buildInfoRow(
                  'Seasons',
                  '${movie.numberOfSeasons}',
                  Icons.subscriptions_outlined,
                ),
              if (movie.numberOfEpisodes != null)
                _buildInfoRow(
                  'Episodes',
                  '${movie.numberOfEpisodes}',
                  Icons.video_library_outlined,
                ),
              const SizedBox(height: 24),
            ],
          ),

        // Recommendations, trailer, and cast would go here
        // These sections would be implemented in separate methods or widgets
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        genre,
        style: TextStyles.bodyText2.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyles.bodyText1,
          ),
          Text(
            value,
            style: TextStyles.bodyText1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}