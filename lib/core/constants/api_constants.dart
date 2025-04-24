// lib/core/constants/api_constants.dart
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  // API Key - Replace with your actual TMDB API key
  static const String apiKey = 'd64f0ecf30a298852d82fac294b62f45';

  static const Map<int, String> genres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Science Fiction',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  // Movie Endpoints
  static const String popularMovies = '$baseUrl/movie/popular';
  static const String upcomingMovies = '$baseUrl/movie/upcoming';
  static const String nowPlayingMovies = '$baseUrl/movie/now_playing';
  static const String topRatedMovies = '$baseUrl/movie/top_rated';

  // TV Show Endpoints
  static const String popularTVShows = '$baseUrl/tv/popular';
  static const String topRatedTVShows = '$baseUrl/tv/top_rated';
  static const String onTheAirTVShows = '$baseUrl/tv/on_the_air';
  static const String airingTodayTVShows = '$baseUrl/tv/airing_today';

  // Details Endpoints
  static String movieDetails(int movieId) => '$baseUrl/movie/$movieId';
  static String tvDetails(int tvId) => '$baseUrl/tv/$tvId';

  // Search Endpoints
  static const String searchMovie = '$baseUrl/search/movie';
  static const String searchTV = '$baseUrl/search/tv';
  static const String searchMulti = '$baseUrl/search/multi';

  // Discover Endpoints
  static const String discoverMovie = '$baseUrl/discover/movie';
  static const String discoverTV = '$baseUrl/discover/tv';

  // Image sizes
  static const String posterSize = 'w500';
  static const String backdropSize = 'original';
  static const String profileSize = 'w185';
  static const String stillSize = 'w300';  // For TV episode stills

  // Image URLs
  static String posterUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/500x750?text=No+Image+Available';
    }
    return '$imageBaseUrl/$posterSize$path';
  }

  static String backdropUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/1280x720?text=No+Backdrop+Available';
    }
    return '$imageBaseUrl/$backdropSize$path';
  }

  static String profileUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/185x278?text=No+Profile';
    }
    return '$imageBaseUrl/$profileSize$path';
  }

  static String stillUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/300x170?text=No+Still+Available';
    }
    return '$imageBaseUrl/$stillSize$path';
  }

  // YouTube video URL
  static String youtubeUrl(String videoKey) => 'https://www.youtube.com/watch?v=$videoKey';
  static String youtubeEmbedUrl(String videoKey) => 'https://www.youtube.com/embed/$videoKey';
  static String youtubeThumbnailUrl(String videoKey) => 'https://img.youtube.com/vi/$videoKey/hqdefault.jpg';
}