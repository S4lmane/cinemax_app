import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';
import '../screens/season_details_screen.dart';

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
        /*
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                movie.title,
                style: TextStyles.headline4,
              ),
            ),
            const SizedBox(width: 8),
            if (movie.getYear().isNotEmpty)
              Text(
                movie.getYear(),
                style: TextStyles.headline5.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        */
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRatingColor(movie.voteAverage),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
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
            const SizedBox(width: 16),
            if (movie.isMovie && movie.director != null && movie.director!.isNotEmpty) ...[
              _buildInfoRow('Director', movie.director!),
              const SizedBox(height: 16),
            ] else if (!movie.isMovie && movie.creator != null && movie.creator!.isNotEmpty) ...[
              _buildInfoRow('Creator', movie.creator!),
              const SizedBox(height: 16),
            ],
            Text(
              '${movie.voteCount} votes',
              style: TextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (movie.runtime > 0) ...[
              const SizedBox(width: 16),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    movie.getFormattedRuntime(),
                    style: TextStyles.bodyText2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (!movie.isMovie && (movie.numberOfSeasons != null || movie.numberOfEpisodes != null)) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (movie.numberOfSeasons != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.video_library,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.numberOfSeasons} ${movie.numberOfSeasons == 1 ? 'Season' : 'Seasons'}',
                        style: TextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (movie.numberOfEpisodes != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.video_collection,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.numberOfEpisodes} ${movie.numberOfEpisodes == 1 ? 'Episode' : 'Episodes'}',
                        style: TextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (!movie.isMovie && movie.numberOfSeasons != null && movie.numberOfSeasons! > 0) ...[
          Text(
            'Seasons',
            style: TextStyles.headline5,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: movie.numberOfSeasons,
              itemBuilder: (context, index) {
                // Season numbers usually start at 1
                final seasonNumber = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildSeasonCard(context, seasonNumber),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
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
        const SizedBox(height: 16),
        if (movie.isMovie && movie.director != null) ...[
          _buildInfoRow('Director', movie.director!),
          const SizedBox(height: 16),
        ] else if (!movie.isMovie && movie.creator != null) ...[
          _buildInfoRow('Creator', movie.creator!),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: movie.genres.map((genre) {
            return Chip(
              label: Text(
                genre,
                style: TextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.textSecondary.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSeasonCard(BuildContext context, int seasonNumber) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeasonDetailsScreen(
              tvShowId: movie.id,
              seasonNumber: seasonNumber,
              tvShowName: movie.title,
            ),
          ),
        );
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Season poster (use show poster as fallback)
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: movie.getPosterUrl(size: 'w200'),
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
                      Icons.tv,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Season $seasonNumber',
                    style: TextStyles.bodyText2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (seasonNumber == 1) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'First Season',
                        style: TextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ] else if (seasonNumber == movie.numberOfSeasons) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Latest',
                        style: TextStyles.caption.copyWith(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyles.bodyText1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.bodyText1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green;
    if (rating >= 6.0) return Colors.orange;
    if (rating >= 4.0) return Colors.amber;
    return Colors.red;
  }
}