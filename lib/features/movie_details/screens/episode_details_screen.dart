// Create a new file lib/features/movie_details/screens/episode_details_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../../../models/episode_model.dart';
import '../providers/tv_details_provider.dart';

class EpisodeDetailsScreen extends StatefulWidget {
  final String tvShowId;
  final int seasonNumber;
  final int episodeNumber;
  final String tvShowName;

  const EpisodeDetailsScreen({
    Key? key,
    required this.tvShowId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.tvShowName,
  }) : super(key: key);

  @override
  _EpisodeDetailsScreenState createState() => _EpisodeDetailsScreenState();
}

class _EpisodeDetailsScreenState extends State<EpisodeDetailsScreen> {
  late TvDetailsProvider _provider;
  bool _isLoading = true;
  String? _error;
  EpisodeModel? _episode;

  @override
  void initState() {
    super.initState();
    _provider = TvDetailsProvider();
    _loadEpisodeDetails();
  }

  Future<void> _loadEpisodeDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final episode = await _provider.getEpisodeDetails(
        widget.tvShowId,
        widget.seasonNumber,
        widget.episodeNumber,
      );

      if (mounted) {
        setState(() {
          _episode = episode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load episode details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tvShowName} - S${widget.seasonNumber}E${widget.episodeNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return app_error.ErrorWidget(
        message: _error!,
        onRetry: _loadEpisodeDetails,
      );
    }

    if (_episode == null) {
      return const app_error.ErrorWidget(
        message: 'Episode details not found',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episode image
          if (_episode!.stillPath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _episode!.getStillUrl(size: 'w500'),
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 16),

          // Episode title and info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_episode!.episodeNumber}',
                  style: TextStyles.headline6.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _episode!.name,
                      style: TextStyles.headline5,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _episode!.airDate.isNotEmpty
                              ? _episode!.airDate
                              : 'Air date unknown',
                          style: TextStyles.bodyText2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (_episode!.runtime > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _episode!.getFormattedRuntime(),
                            style: TextStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rating
          if (_episode!.voteAverage > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: TextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_episode!.voteAverage.toStringAsFixed(1)}/10',
                        style: TextStyles.headline4,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Overview
          Text(
            'Overview',
            style: TextStyles.headline6,
          ),
          const SizedBox(height: 8),
          Text(
            _episode!.overview.isNotEmpty
                ? _episode!.overview
                : 'No overview available for this episode.',
            style: TextStyles.bodyText1.copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Previous/Next episode navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_episode!.episodeNumber > 1)
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EpisodeDetailsScreen(
                          tvShowId: widget.tvShowId,
                          seasonNumber: widget.seasonNumber,
                          episodeNumber: widget.episodeNumber - 1,
                          tvShowName: widget.tvShowName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: AppColors.textPrimary,
                  ),
                )
              else
                const SizedBox.shrink(),

              // Continuing from lib/features/movie_details/screens/episode_details_screen.dart

              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EpisodeDetailsScreen(
                        tvShowId: widget.tvShowId,
                        seasonNumber: widget.seasonNumber,
                        episodeNumber: widget.episodeNumber + 1,
                        tvShowName: widget.tvShowName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}