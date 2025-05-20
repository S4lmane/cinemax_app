import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';
import '../screens/season_details_screen.dart';

class MovieInfo extends StatelessWidget {
  final MovieModel movie;

  const MovieInfo({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status section for TV shows or movies
        if (!movie.isMovie && movie.status == 'Returning Series') ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currently Airing',
                        style: TextStyles.bodyText1.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New episodes are being released',
                        style: TextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (movie.status == 'In Production' ||
            movie.status == 'Post Production' ||
            movie.getStatusBadge() == 'Coming Soon') ...[
          if (movie.releaseDate.isNotEmpty) ...[
            Builder(
              builder: (context) {
                DateTime? releaseDate = DateTime.tryParse(movie.releaseDate);
                if (releaseDate != null && releaseDate.isAfter(DateTime.now())) {
                  // Calculate countdown
                  final now = DateTime.now();
                  final difference = releaseDate.difference(now);
                  String countdownText;
                  if (difference.inDays >= 31) {
                    final months = (difference.inDays / 30).floor();
                    final days = difference.inDays % 30;
                    final hours = (difference.inMinutes % (24 * 60)) ~/ 60;
                    final minutes = difference.inMinutes % 60;
                    countdownText = '$months months, $days days, $hours hours, $minutes minutes';
                  } else {
                    final days = difference.inDays;
                    final hours = (difference.inMinutes % (24 * 60)) ~/ 60;
                    final minutes = difference.inMinutes % 60;
                    countdownText = '$days days, $hours hours, $minutes minutes';
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Will be released on the ${releaseDate.toString().split(' ')[0]}',
                                style: TextStyles.bodyText1.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                countdownText,
                                style: TextStyles.bodyText2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        // Director/Creator with Rating
        if (movie.isMovie && movie.director != null && movie.director!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildInfoRow('Director', movie.director!)),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 16),
        ] else if (!movie.isMovie && movie.creator != null && movie.creator!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildInfoRow('Creator', movie.creator!)),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Vote count and runtime
        Row(
          children: [
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
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: TextStyles.bodyText2.copyWith(
                      color: _getRatingColor(movie.voteAverage),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.navigate_next_outlined,
              color: _getRatingColor(movie.voteAverage),
              size: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0),
                borderRadius: BorderRadius.circular(8),
                //border: Border.all(
                //  color: Colors.grey,
                //  width: 1,
                //),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.how_to_vote,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${movie.voteCount} votes',
                    style: TextStyles.bodyText2.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
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
        const SizedBox(height: 16),
        // Genres
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
        // Seasons and episodes for TV shows
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
        // Seasons list for TV shows
        if (!movie.isMovie && movie.numberOfSeasons != null && movie.numberOfSeasons! > 0) ...[
          const SizedBox(height: 16),
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
        width: 100,// to remove the overflow at the bottom of the card
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        //fix the RenderFlex at the bottom of the first & last season's card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              padding: const EdgeInsets.all(0),
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
    // if (rating == 10) return Color(0xFF007707);
    if (rating >= 8.0) return Colors.green;
    if (rating >= 6.0 && rating < 8.0) return Colors.orange;
    if (rating >= 4.0 && rating < 6.0) return Colors.amber;
    return Colors.red;
  }
}