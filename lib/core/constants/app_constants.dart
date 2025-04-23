class AppConstants {
  // App info
  static const String appName = 'Cinemax';
  static const String appVersion = '1.0.0';

  // Default values
  static const String defaultProfileImage = 'https://firebasestorage.googleapis.com/v0/b/cinemax-app.appspot.com/o/defaults%2Fdefault_profile.png?alt=media';
  static const String defaultBannerImage = 'https://firebasestorage.googleapis.com/v0/b/cinemax-app.appspot.com/o/defaults%2Fdefault_banner.jpg?alt=media';

  // Collection names
  static const String usersCollection = 'users';
  static const String listsCollection = 'lists';
  static const String watchlistCollection = 'watchlist';
  static const String favoritesCollection = 'favorites';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String bannerImagesPath = 'banner_images';
  static const String listCoversPath = 'list_covers';

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchPageSize = 20;

  // Error messages
  static const String defaultErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Authentication error. Please sign in again.';

  // Genres mapping (TMDB)
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

  // TV Genres
  static const Map<int, String> tvGenres = {
    10759: 'Action & Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    10762: 'Kids',
    9648: 'Mystery',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
    37: 'Western',
  };

  // Get genre name by id
  static String getGenreName(int genreId, {bool isTv = false}) {
    if (isTv) {
      return tvGenres[genreId] ?? 'Unknown';
    }
    return genres[genreId] ?? 'Unknown';
  }
}