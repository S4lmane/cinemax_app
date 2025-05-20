// lib/features/search/widgets/search_result_item.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_image.dart';

class SearchResultItem extends StatelessWidget {
  final String title;
  final String posterPath;
  final double voteAverage;
  final bool isMovie;
  final String overview;
  final String releaseDate;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.title,
    required this.posterPath,
    required this.voteAverage,
    required this.isMovie,
    this.overview = '', // Optional with default value
    this.releaseDate = '', // Optional with default value
    required this.onTap,
  });

  String getYear() {
    if (releaseDate.isEmpty) return '';
    try {
      return releaseDate.substring(0, 4);
    } catch (e) {
      return '';
    }
  }

  String getPosterUrl({String size = 'w200'}) {
    if (posterPath.isEmpty) {
      return 'https://via.placeholder.com/500x750?text=No+Image+Available';
    }
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 100,
                height: 140,
                child: CustomImage(
                  imageUrl: getPosterUrl(),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyles.headline6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Year and content type
                    Row(
                      children: [
                        Text(
                          getYear(),
                          style: TextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2
                          ),
                          decoration: BoxDecoration(
                            color: isMovie
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isMovie ? 'Movie' : 'TV Show',
                            style: TextStyles.caption.copyWith(
                              color: isMovie ? Colors.blue : Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          voteAverage.toStringAsFixed(1),
                          style: TextStyles.bodyText2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        overview,
                        style: TextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}