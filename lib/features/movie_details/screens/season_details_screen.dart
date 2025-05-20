import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../../../models/season_model.dart';
import '../../../models/episode_model.dart';
import '../providers/tv_details_provider.dart';
import 'episode_details_screen.dart';

class SeasonDetailsScreen extends StatefulWidget {
  final String tvShowId;
  final int seasonNumber;
  final String tvShowName;

  const SeasonDetailsScreen({
    super.key,
    required this.tvShowId,
    required this.seasonNumber,
    required this.tvShowName,
  });

  @override
  _SeasonDetailsScreenState createState() => _SeasonDetailsScreenState();
}

class _SeasonDetailsScreenState extends State<SeasonDetailsScreen> {
  late TvDetailsProvider _provider;
  bool _isLoading = true;
  String? _error;
  SeasonModel? _season;

  @override
  void initState() {
    super.initState();
    _provider = TvDetailsProvider();
    _loadSeasonDetails();
  }

  Future<void> _loadSeasonDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final season = await _provider.getSeasonDetails(
        widget.tvShowId,
        widget.seasonNumber,
      );

      if (mounted) {
        setState(() {
          _season = season;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load season details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tvShowName} - Season ${widget.seasonNumber}'),
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
        onRetry: _loadSeasonDetails,
      );
    }

    if (_season == null) {
      return const app_error.ErrorWidget(
        message: 'Season details not found',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Season poster and info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _season!.posterPath.isNotEmpty
                    ? 'https://image.tmdb.org/t/p/w200${_season!.posterPath}'
                    : 'https://via.placeholder.com/200x300?text=No+Image',
                width: 120,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Season info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _season!.name,
                    style: TextStyles.headline5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_season!.episodes.length} Episodes',
                    style: TextStyles.bodyText1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Air Date: ${_season!.airDate}',
                    style: TextStyles.bodyText2,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Season overview
        if (_season!.overview.isNotEmpty) ...[
          Text(
            'Overview',
            style: TextStyles.headline6,
          ),
          const SizedBox(height: 8),
          Text(
            _season!.overview,
            style: TextStyles.bodyText2,
          ),
          const SizedBox(height: 24),
        ],

        // Episodes list
        Text(
          'Episodes',
          style: TextStyles.headline6,
        ),
        const SizedBox(height: 16),
        ..._season!.episodes.map((episode) => _buildEpisodeItem(episode)),
      ],
    );
  }

  Widget _buildEpisodeItem(EpisodeModel episode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EpisodeDetailsScreen(
                tvShowId: widget.tvShowId,
                seasonNumber: widget.seasonNumber,
                episodeNumber: episode.episodeNumber,
                tvShowName: widget.tvShowName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Episode image
            if (episode.stillPath.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w500${episode.stillPath}',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode number and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${episode.episodeNumber}',
                          style: TextStyles.bodyText2.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          episode.name,
                          style: TextStyles.headline6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Air date and rating
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        episode.airDate,
                        style: TextStyles.caption,
                      ),
                      const Spacer(),
                      if (episode.voteAverage > 0) ...[
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          episode.voteAverage.toStringAsFixed(1),
                          style: TextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Overview
                  Text(
                    episode.overview.isNotEmpty
                        ? episode.overview
                        : 'No overview available for this episode.',
                    style: TextStyles.bodyText2,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}