class EpisodeModel {
  final int id;
  final String name;
  final String overview;
  final String stillPath;
  final int episodeNumber;
  final int seasonNumber;
  final String airDate;
  final double voteAverage;
  final int runtime;

  EpisodeModel({
    required this.id,
    required this.name,
    required this.overview,
    required this.stillPath,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.airDate,
    required this.voteAverage,
    required this.runtime,
  });

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      overview: map['overview'] ?? '',
      stillPath: map['still_path'] ?? '',
      episodeNumber: map['episode_number'] ?? 0,
      seasonNumber: map['season_number'] ?? 0,
      airDate: map['air_date'] ?? '',
      voteAverage: (map['vote_average'] ?? 0.0).toDouble(),
      runtime: map['runtime'] ?? 0,
    );
  }

  String getStillUrl({String size = 'w300'}) {
    if (stillPath.isEmpty) {
      return 'https://via.placeholder.com/500x281?text=No+Image+Available';
    }
    return 'https://image.tmdb.org/t/p/$size$stillPath';
  }

  String getFormattedRuntime() {
    if (runtime <= 0) return '';
    if (runtime < 60) return '$runtime min';
    final hrs = runtime ~/ 60;
    final mins = runtime % 60;
    return hrs > 0 ? '$hrs hr ${mins > 0 ? '$mins min' : ''}' : '$mins min';
  }
}