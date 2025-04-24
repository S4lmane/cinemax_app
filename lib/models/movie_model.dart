import 'cast_model.dart';
import 'crew_model.dart';
import 'video_model.dart';

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
  bool isMovie; // true for movie, false for TV show
  final int? numberOfSeasons; // null for movies
  final int? numberOfEpisodes; // null for movies

  // New fields for enhanced details
  List<CastModel> cast;
  List<CrewModel> crew;
  List<VideoModel> videos;
  List<MovieModel> similar;
  List<MovieModel> recommendations;
  String? director; // For movies
  String? creator; // For TV shows
  String status; // e.g. "Released", "In Production"

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
    this.cast = const [],
    this.crew = const [],
    this.videos = const [],
    this.similar = const [],
    this.recommendations = const [],
    this.director,
    this.creator,
    this.status = 'Unknown',
  });

  factory MovieModel.fromMap(Map<String, dynamic> map) {
    // Extract genres data
    List<String> parsedGenres = [];

    if (map.containsKey('genres') && map['genres'] != null) {
      parsedGenres = (map['genres'] as List)
          .map((genre) => genre['name'] as String)
          .toList();
    } else if (map.containsKey('genre_ids') && map['genre_ids'] != null) {
      // For list results, map genre IDs to genre names
      final genreIds = List<int>.from(map['genre_ids'] ?? []);
      parsedGenres = genreIds.map((id) {
        // Look up genre name from AppConstants.genres
        return id.toString(); // Use id as string for now, can be replaced later
      }).toList();
    }

    // Determine the title field (different for movies vs TV shows)
    String itemTitle = '';
    if (map.containsKey('title')) {
      itemTitle = map['title'] ?? '';
    } else if (map.containsKey('name')) {
      itemTitle = map['name'] ?? '';
    }

    // Determine the release date field (different for movies vs TV shows)
    String itemReleaseDate = '';
    if (map.containsKey('release_date')) {
      itemReleaseDate = map['release_date'] ?? '';
    } else if (map.containsKey('first_air_date')) {
      itemReleaseDate = map['first_air_date'] ?? '';
    }

    // Determine runtime (different for movies vs TV shows)
    int itemRuntime = 0;
    if (map.containsKey('runtime')) {
      itemRuntime = map['runtime'] ?? 0;
    } else if (map.containsKey('episode_run_time') &&
        map['episode_run_time'] is List &&
        (map['episode_run_time'] as List).isNotEmpty) {
      itemRuntime = (map['episode_run_time'] as List).first ?? 0;
    }

    // Determine status
    String itemStatus = 'Unknown';
    if (map.containsKey('status')) {
      itemStatus = map['status'] ?? 'Unknown';
    }

    return MovieModel(
      id: map['id']?.toString() ?? '',
      title: itemTitle,
      posterPath: map['poster_path'] ?? '',
      backdropPath: map['backdrop_path'] ?? '',
      overview: map['overview'] ?? '',
      voteAverage: (map['vote_average'] ?? 0.0).toDouble(),
      voteCount: map['vote_count'] ?? 0,
      releaseDate: itemReleaseDate,
      genres: parsedGenres,
      runtime: itemRuntime,
      isMovie: map.containsKey('title'), // If 'title' exists, it's a movie; if 'name' exists, it's a TV show
      numberOfSeasons: map['number_of_seasons'],
      numberOfEpisodes: map['number_of_episodes'],
      status: itemStatus,
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
      'status': status,
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
    return genres.isNotEmpty ? genres.join(', ') : 'Unknown';
  }

  String getPosterUrl({String size = 'w500'}) {
    if (posterPath.isEmpty) {
      return 'https://via.placeholder.com/500x750?text=No+Image+Available';
    }
    return 'https://image.tmdb.org/t/p/$size$posterPath';
  }

  String getBackdropUrl({String size = 'original'}) {
    if (backdropPath.isEmpty) {
      return 'https://via.placeholder.com/1280x720?text=No+Image+Available';
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

  String getStatusBadge() {
    // Return a human-readable status indicator
    if (isMovie) {
      if (status == 'Released') return 'Released';
      if (status == 'In Production') return 'In Production';
      if (status == 'Post Production') return 'Coming Soon';
      if (status == 'Planned') return 'Planned';
      return status;
    } else {
      // For TV shows
      if (status == 'Returning Series') return 'Ongoing';
      if (status == 'Ended') return 'Ended';
      if (status == 'Canceled') return 'Canceled';
      if (status == 'In Production') return 'In Production';
      return status;
    }
  }

  // Get the trailer video if available
  VideoModel? getTrailer() {
    if (videos.isEmpty) return null;

    // First try to find an official trailer
    for (var video in videos) {
      if (video.type == 'Trailer' && video.official) {
        return video;
      }
    }

    // If no official trailer, try any trailer
    for (var video in videos) {
      if (video.type == 'Trailer') {
        return video;
      }
    }

    // If no trailer at all, use any video
    return videos.first;
  }

  // Check if has trailer
  bool hasTrailer() {
    return getTrailer() != null;
  }
}