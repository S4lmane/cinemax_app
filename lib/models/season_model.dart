import 'episode_model.dart';

class SeasonModel {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final int seasonNumber;
  final String airDate;
  final List<EpisodeModel> episodes;

  SeasonModel({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.seasonNumber,
    required this.airDate,
    required this.episodes,
  });

  factory SeasonModel.fromMap(Map<String, dynamic> map) {
    final List<EpisodeModel> episodes = [];

    if (map.containsKey('episodes') && map['episodes'] is List) {
      for (var episode in map['episodes']) {
        episodes.add(EpisodeModel.fromMap(episode));
      }
    }

    return SeasonModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      overview: map['overview'] ?? '',
      posterPath: map['poster_path'] ?? '',
      seasonNumber: map['season_number'] ?? 0,
      airDate: map['air_date'] ?? '',
      episodes: episodes,
    );
  }

  String getPosterUrl({String size = 'w300'}) {
    if (posterPath.isEmpty) {
      return 'https://via.placeholder.com/300x450?text=No+Image+Available';
    }
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }
}