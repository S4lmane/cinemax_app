class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  // API Key - Replace with your actual TMDB API key
  static const String apiKey = 'd64f0ecf30a298852d82fac294b62f45';

  // Endpoints
  static const String popularMovies = '$baseUrl/movie/popular';
  static const String upcomingMovies = '$baseUrl/movie/upcoming';
  static const String nowPlayingMovies = '$baseUrl/movie/now_playing';
  static const String topRatedMovies = '$baseUrl/movie/top_rated';

  // Movie details
  static String movieDetails(int movieId) => '$baseUrl/movie/$movieId';

  // Search
  static const String searchMovie = '$baseUrl/search/movie';

  // Image sizes
  static const String posterSize = 'w500';
  static const String backdropSize = 'original';
  static const String profileSize = 'w185';

  // Image URLs
  static String posterUrl(String path) => '$imageBaseUrl/$posterSize$path';
  static String backdropUrl(String path) => '$imageBaseUrl/$backdropSize$path';
  static String profileUrl(String path) => '$imageBaseUrl/$profileSize$path';
}