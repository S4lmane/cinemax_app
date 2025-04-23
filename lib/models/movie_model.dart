class MovieModel {
  final String id;
  final String title;
  final String posterPath;
  final String backdropPath;
  final String overview;
  final double voteAverage;
  final int voteCount;
  final String releaseDate;
  final List<String> genres;
  final int runtime;
  final bool isMovie; // true for movie, false for TV show
  final int? numberOfSeasons; // null for movies
  final int? numberOfEpisodes; // null for movies

  MovieModel({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.voteCount,
    required this.releaseDate,
    required this.genres,
    required this.runtime,
    required this.isMovie,
    this.numberOfSeasons,
    this.numberOfEpisodes,
  });

  factory MovieModel.fromMap(Map<String, dynamic> map) {
    final List<dynamic> genresData = map['genres'] ?? [];
    final List<String> parsedGenres = genresData.isNotEmpty
        ? List<String>.from(genresData.map((genre) => genre['name']))
        : List<String>.from(map['genre_ids']?.map((id) => id.toString()) ?? []);

    return MovieModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? map['name'] ?? '',
      posterPath: map['poster_path'] ?? '',
      backdropPath: map['backdrop_path'] ?? '',
      overview: map['overview'] ?? '',
      voteAverage: (map['vote_average'] ?? 0.0).toDouble(),
      voteCount: map['vote_count'] ?? 0,
      releaseDate: map['release_date'] ?? map['first_air_date'] ?? '',
      genres: parsedGenres,
      runtime: map['runtime'] ?? map['episode_run_time']?[0] ?? 0,
      isMovie: map['title'] != null, // If 'title' exists, it's a movie; if 'name' exists, it's a TV show
      numberOfSeasons: map['number_of_seasons'],
      numberOfEpisodes: map['number_of_episodes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'overview': overview,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genres': genres,
      'runtime': runtime,
      'is_movie': isMovie,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
    };
  }

  String getYear() {
    if (releaseDate.isEmpty) return '';
    try {
      return releaseDate.substring(0, 4);
    } catch (e) {
      return '';
    }
  }

  String getGenreString() {
    return genres.isNotEmpty ? genres.first : 'Unknown';
  }

  String getPosterUrl({String size = 'w500'}) {
    if (posterPath.isEmpty) {
      return 'https://via.placeholder.com/342x513?text=No+Image';
    }
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }

  String getBackdropUrl({String size = 'original'}) {
    if (backdropPath.isEmpty) {
      return 'https://via.placeholder.com/780x439?text=No+Image';
    }
    return 'https://image.tmdb.org/t/p/$size$backdropPath';
  }

  String getFormattedRuntime() {
    if (runtime <= 0) return '';
    final hrs = runtime ~/ 60;
    final mins = runtime % 60;
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}