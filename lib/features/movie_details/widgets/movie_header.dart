import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';
import '../../../core/widgets/custom_image.dart';

class MovieHeader extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onPosterTap;

  const MovieHeader({
    Key? key,
    required this.movie,
    required this.onPosterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image
          CustomImage(
            imageUrl: movie.getBackdropUrl(),
            fit: BoxFit.cover,
          ),

          // Gradient overlay
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

          // Home button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.home),
              color: Colors.white,
              onPressed: () {
                // Navigate to the main/home screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              tooltip: 'Home',
            ),
          ),

          // Poster and title
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Movie poster with tap for fullscreen
                GestureDetector(
                  onTap: onPosterTap,
                  child: Hero(
                    tag: 'poster_${movie.id}',
                    child: Container(
                      width: 150,
                      height: 200,
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
                            CustomImage(
                              imageUrl: movie.getPosterUrl(size: 'w200'),
                              fit: BoxFit.cover,
                              height: 150,
                              width: 100,
                            ),
                            // Zoom indicator
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

                // Movie title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyles.headline4.copyWith(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Year and duration
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
    );
  }
}