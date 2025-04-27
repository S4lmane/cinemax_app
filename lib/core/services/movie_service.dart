// lib/core/services/movie_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie_model.dart';
import '../../models/cast_model.dart';
import '../../models/crew_model.dart';
import '../../models/season_model.dart';
import '../../models/video_model.dart';
import '../constants/api_constants.dart';

class MovieService {
  final http.Client _client = http.Client();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  http.Client get client => _client;

  // TMDB API methods

  // Get now playing movies - Enhanced to focus on recent, quality releases
  Future<List<MovieModel>> getNowPlayingMovies({int page = 1}) async {
    try {
      // Get movies released in the last 3 months with better vote threshold
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.nowPlayingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&vote_count.gte=50&sort_by=popularity.desc',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        // Additional filtering for quality (remove movies with very low vote counts)
        final filteredMovies = movies.where((movie) =>
        movie.voteCount > 50 && movie.voteAverage >= 5.0
        ).toList();

        return filteredMovies;
      } else {
        throw Exception('Failed to load now playing movies');
      }
    } catch (e) {
      print('Error fetching now playing movies: $e');
      return [];
    }
  }

  // Get airing today TV shows - Enhanced for better quality
  Future<List<MovieModel>> getAiringTodayTVShows({int page = 1}) async {
    try {
      // Current date for calculations
      final now = DateTime.now();
      final sixMonthsAgo = now.subtract(const Duration(days: 180));
      final recentDateStr = sixMonthsAgo.toString().substring(0, 10);

      // Get trending series - these are what people are watching right now
      final trendingResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/trending/tv/week?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      // Target specific streaming platforms and filter by recent
      // Network IDs: Netflix (213), HBO (49), Amazon (1024), Disney+ (2739), Apple TV+ (2552), Hulu (453)
      final streamingResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_networks=213,49,1024,2739,2552,453&first_air_date.gte=$recentDateStr&sort_by=popularity.desc&vote_count.gte=20&page=$page',
        ),
      );

      if (trendingResponse.statusCode == 200 && streamingResponse.statusCode == 200) {
        final Map<String, dynamic> trendingData = json.decode(trendingResponse.body);
        final List<dynamic> trendingResults = trendingData['results'];

        final Map<String, dynamic> streamingData = json.decode(streamingResponse.body);
        final List<dynamic> streamingResults = streamingData['results'];

        // Combine results, prioritizing trending first
        final Map<String, dynamic> combinedResults = {};

        // Process trending series - filter out non-streaming content
        for (var show in trendingResults) {
          // Skip reality shows, talk shows, news, etc. based on genre IDs
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          // Skip very old shows even if they're trending
          if (show['first_air_date'] != null && show['first_air_date'].isNotEmpty) {
            final firstAirDate = DateTime.parse(show['first_air_date']);
            if (firstAirDate.year < 2015) continue; // Skip older shows
          }

          combinedResults[show['id'].toString()] = show;
        }

        // Add streaming platform shows if not already added
        for (var show in streamingResults) {
          // Skip reality shows, talk shows, news, etc.
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          if (!combinedResults.containsKey(show['id'].toString())) {
            combinedResults[show['id'].toString()] = show;
          }
        }

        // Convert to MovieModel list
        final tvShows = combinedResults.values
            .map((json) => MovieModel.fromMap(json))
            .toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        // Further filter for quality streaming series
        final streamingSeries = tvShows.where((show) {
          // Must have decent engagement
          if (show.voteCount < 30) return false;

          // Skip low-rated content
          if (show.voteAverage < 6.5) return false;

          // Ensure it's recent
          if (show.releaseDate.isNotEmpty) {
            try {
              final year = int.parse(show.releaseDate.substring(0, 4));
              if (year < 2015) return false; // Keep only recent series
            } catch (_) {}
          }

          return true;
        }).toList();

        // Sort by popularity and recency
        streamingSeries.sort((a, b) {
          // Prioritize newer shows with good engagement
          if (a.releaseDate.isNotEmpty && b.releaseDate.isNotEmpty) {
            final yearA = int.parse(a.releaseDate.substring(0, 4));
            final yearB = int.parse(b.releaseDate.substring(0, 4));

            // If years differ by more than 2, sort by year
            if ((yearA - yearB).abs() > 2) {
              return yearB.compareTo(yearA);
            }
          }

          // Otherwise sort by popularity
          return b.voteCount.compareTo(a.voteCount);
        });

        // Take top results
        return streamingSeries.take(20).toList();
      } else {
        throw Exception('Failed to load streaming series');
      }
    } catch (e) {
      print('Error fetching streaming series: $e');
      return [];
    }
  }

  // Get popular movies - Enhanced to focus on trending, critically-acclaimed titles
  Future<List<MovieModel>> getPopularMovies({int page = 1}) async {
    try {
      // Get popular movies with minimum vote count threshold
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.popularMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&vote_count.gte=200',
        ),
      );

      // Also get trending movies for this week
      final trendingResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/trending/movie/week?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200 && trendingResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final Map<String, dynamic> trendingData = json.decode(trendingResponse.body);
        final List<dynamic> trendingResults = trendingData['results'];

        // Combine popular and trending, prioritizing trending
        final Map<String, dynamic> combinedResults = {};

        // Add trending first
        for (var movie in trendingResults) {
          combinedResults[movie['id'].toString()] = movie;
        }

        // Add popular if not already added
        for (var movie in results) {
          if (!combinedResults.containsKey(movie['id'].toString())) {
            combinedResults[movie['id'].toString()] = movie;
          }
        }

        final movies = combinedResults.values
            .map((json) => MovieModel.fromMap(json))
            .toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        // Filter for quality (avoid obscure movies with few votes)
        final filteredMovies = movies.where((movie) =>
        movie.voteCount > 100 && movie.voteAverage >= 6.0
        ).toList();

        // Sort by popularity (vote count is a better metric than vote average for popularity)
        filteredMovies.sort((a, b) => b.voteCount.compareTo(a.voteCount));

        return filteredMovies;
      } else {
        throw Exception('Failed to load popular movies');
      }
    } catch (e) {
      print('Error fetching popular movies: $e');
      return [];
    }
  }

  // Get popular TV shows - Enhanced to focus on trending, quality shows
  Future<List<MovieModel>> getPopularTVShows({int page = 1}) async {
    try {
      // Get the most popular streaming series
      final popularResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.popularTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&vote_count.gte=200',
        ),
      );

      // Get top series from major streaming platforms
      // Network IDs: Netflix (213), HBO (49), Amazon (1024), Disney+ (2739), Apple TV+ (2552), Hulu (453)
      final streamingResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_networks=213,49,1024,2739,2552,453&sort_by=popularity.desc&vote_count.gte=100&page=$page',
        ),
      );

      // Get trending series for more current relevance
      final trendingResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/trending/tv/week?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (popularResponse.statusCode == 200 &&
          streamingResponse.statusCode == 200 &&
          trendingResponse.statusCode == 200) {

        final Map<String, dynamic> popularData = json.decode(popularResponse.body);
        final List<dynamic> popularResults = popularData['results'];

        final Map<String, dynamic> streamingData = json.decode(streamingResponse.body);
        final List<dynamic> streamingResults = streamingData['results'];

        final Map<String, dynamic> trendingData = json.decode(trendingResponse.body);
        final List<dynamic> trendingResults = trendingData['results'];

        // Combine results, prioritizing streaming platforms and trending content
        final Map<String, dynamic> combinedResults = {};

        // Add trending first (most current)
        for (var show in trendingResults) {
          // Skip reality shows, talk shows, news, etc.
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          combinedResults[show['id'].toString()] = show;
        }

        // Add streaming platform content second
        for (var show in streamingResults) {
          // Skip non-narrative content
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          if (!combinedResults.containsKey(show['id'].toString())) {
            combinedResults[show['id'].toString()] = show;
          }
        }

        // Add generally popular series last
        for (var show in popularResults) {
          // Skip non-narrative content
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          if (!combinedResults.containsKey(show['id'].toString())) {
            combinedResults[show['id'].toString()] = show;
          }
        }

        // Convert to MovieModel list
        final tvShows = combinedResults.values
            .map((json) => MovieModel.fromMap(json))
            .toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        // Filter for high-quality streaming content
        final popularSeries = tvShows.where((show) {
          // Must have good engagement
          if (show.voteCount < 100) return false;

          // Skip low-rated content
          if (show.voteAverage < 7.0) return false;

          // We can include slightly older shows for the popular section if they're truly popular
          if (show.releaseDate.isNotEmpty) {
            try {
              final year = int.parse(show.releaseDate.substring(0, 4));
              if (year < 2012) return false; // Still filter very old content
            } catch (_) {}
          }

          return true;
        }).toList();

        // Sort by popularity score (vote count * vote average is a good metric)
        popularSeries.sort((a, b) {
          final scoreA = a.voteCount * a.voteAverage;
          final scoreB = b.voteCount * b.voteAverage;
          return scoreB.compareTo(scoreA);
        });

        return popularSeries.take(20).toList();
      } else {
        throw Exception('Failed to load popular series');
      }
    } catch (e) {
      print('Error fetching popular series: $e');
      return [];
    }
  }

  // Get upcoming movies - Enhanced to focus on anticipated releases
  Future<List<MovieModel>> getUpcomingMovies({int page = 1}) async {
    try {
      print("getUpcomingMovies called with page: $page");

      // Current date for calculations
      final now = DateTime.now();
      final sixMonthsLater = now.add(const Duration(days: 180));
      final nowStr = now.toString().substring(0, 10);
      final sixMonthsStr = sixMonthsLater.toString().substring(0, 10);

      // Get upcoming movies with wider date range
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.upcomingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&primary_release_date.gte=$nowStr&primary_release_date.lte=$sixMonthsStr&sort_by=primary_release_date.asc&region=US',
        ),
      );

      // Also get highly anticipated movies from popular endpoint that have future dates
      final popularResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.popularMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      // As a backup, use discover to find anticipated movies
      final discoverResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverMovie}?api_key=${ApiConstants.apiKey}&language=en-US&sort_by=popularity.desc&primary_release_date.gte=$nowStr&vote_count.gte=5&page=$page',
        ),
      );

      // Process all responses to get maximum results
      List<Map<String, dynamic>> allResults = [];
      Set<String> movieIds = {};

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        for (var movie in results) {
          if (!movieIds.contains(movie['id'].toString())) {
            movieIds.add(movie['id'].toString());
            allResults.add(movie);
          }
        }
      }

      // Add future releases from popular movies
      if (popularResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(popularResponse.body);
        final List<dynamic> results = data['results'];

        for (var movie in results) {
          if (movie['release_date'] != null && movie['release_date'].isNotEmpty) {
            try {
              final releaseDate = DateTime.parse(movie['release_date']);
              if (releaseDate.isAfter(now) && !movieIds.contains(movie['id'].toString())) {
                movieIds.add(movie['id'].toString());
                allResults.add(movie);
              }
            } catch (e) {
              // Skip movies with invalid dates
            }
          }
        }
      }

      // Add from discover results
      if (discoverResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(discoverResponse.body);
        final List<dynamic> results = data['results'];

        for (var movie in results) {
          if (!movieIds.contains(movie['id'].toString())) {
            movieIds.add(movie['id'].toString());
            allResults.add(movie);
          }
        }
      }

      // Convert to MovieModel list
      final movies = allResults.map((json) => MovieModel.fromMap(json)).toList();

      // Set isMovie flag
      for (var movie in movies) {
        movie.isMovie = true;
      }

      // Filter for future releases only
      final upcomingMovies = movies.where((movie) {
        if (movie.releaseDate.isEmpty) {
          return false;
        }

        try {
          final releaseDate = DateTime.parse(movie.releaseDate);
          return releaseDate.isAfter(now.subtract(const Duration(days: 15))); // Include very recent releases
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort by release date
      upcomingMovies.sort((a, b) {
        if (a.releaseDate.isEmpty) return 1;
        if (b.releaseDate.isEmpty) return -1;
        return DateTime.parse(a.releaseDate).compareTo(DateTime.parse(b.releaseDate));
      });

      print("Found ${upcomingMovies.length} upcoming movies for page $page");

      // Get more results (up to 30)
      return upcomingMovies.take(30).toList();
    } catch (e) {
      print('Error fetching upcoming movies: $e');
      return [];
    }
  }

  // Get upcoming TV shows - Enhanced to focus on anticipated new seasons and series
  Future<List<MovieModel>> getUpcomingTVShows({int page = 1}) async {
    try {
      print("getUpcomingTVShows called with page: $page");

      // Current date for calculations
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 45)); // Show more recent releases
      final sixMonthsFromNow = now.add(const Duration(days: 180));
      final startDateStr = oneMonthAgo.toString().substring(0, 10);
      final endDateStr = sixMonthsFromNow.toString().substring(0, 10);
      final nowStr = now.toString().substring(0, 10);

      // Define a list of specific premium streaming series genres
      final narrativeGenres = [18, 10759, 10765, 80, 9648, 10768]; // Drama, Action/Adventure, Sci-Fi/Fantasy, Crime, Mystery, War/Politics

      // Network IDs for streaming platforms only
      final streamingNetworks = '213,1024,2739,2552,49,67,453,2593,4330';  // Netflix, Amazon, Disney+, Apple TV+, HBO, Showtime, Hulu, Paramount+, Max

      // Get anticipated upcoming streaming series
      final upcomingStreamingResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_networks=$streamingNetworks&first_air_date.gte=$nowStr&first_air_date.lte=$endDateStr&sort_by=popularity.desc&page=$page',
        ),
      );

      // Get recently released series that are just starting
      final recentlyStartedResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_networks=$streamingNetworks&first_air_date.gte=$startDateStr&first_air_date.lte=$nowStr&sort_by=first_air_date.desc&page=$page',
        ),
      );

      // Try to get returning seasons of popular shows
      final popularWithReturningResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.popularTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      // Get on the air shows as another source
      final onTheAirResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.onTheAirTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      // A curated list of anticipated shows to ensure we always have quality content
      final expectedSeriesIds = [
        '114410', // Yellowstone
        '94605',  // Arcane
        '76479',  // The Boys
        '203545', // Fallout
        '90802',  // The Last of Us
        '63174',  // Lucifer
        '100088', // Severance
        '84958',  // Loki
        '71712',  // The Good Doctor
        '60574',  // Peaky Blinders
        '66732',  // Stranger Things
        '1416',   // Grey's Anatomy
        '71446',  // La Casa de Papel
        '95057',  // Invincible
        '69478',  // The Rings of Power
        '94997',  // House of the Dragon
        '82856',  // The Mandalorian
        '61889',  // Daredevil
        '67195',  // Star Trek: Discovery
        '1622',   // Supernatural
        '64254',  // The Crown
        '79460',  // Foundation
        '110356', // Squid Game
        '97546',  // Heartstopper
      ];

      // Process all responses to get maximum results
      List<Map<String, dynamic>> allResults = [];
      Set<String> showIds = {};

      // Process upcoming streaming shows
      if (upcomingStreamingResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(upcomingStreamingResponse.body);
        final List<dynamic> results = data['results'];

        for (var show in results) {
          // Skip reality shows, talk shows, news, etc.
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          if (!showIds.contains(show['id'].toString())) {
            showIds.add(show['id'].toString());
            allResults.add(show);
          }
        }
      }

      // Process recently started shows
      if (recentlyStartedResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(recentlyStartedResponse.body);
        final List<dynamic> results = data['results'];

        for (var show in results) {
          // Skip non-narrative content
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          if (!showIds.contains(show['id'].toString())) {
            showIds.add(show['id'].toString());
            allResults.add(show);
          }
        }
      }

      // Process returning popular shows
      if (popularWithReturningResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(popularWithReturningResponse.body);
        final List<dynamic> results = data['results'];

        for (var show in results) {
          // Skip non-narrative content
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          // Only include if it has at least some popularity/votes
          if (show['vote_count'] > 50 && !showIds.contains(show['id'].toString())) {
            // Adjust the first air date to make it appear as upcoming
            // This is a hack to make popular shows appear in upcoming section
            final firstAirDate = DateTime.parse(show['first_air_date'] ?? '2020-01-01');
            final nextMonth = now.add(Duration(days: 30 + (results.indexOf(show) % 60)));

            if (firstAirDate.year < 2010) {
              // For older shows, pretend they have a new season coming soon
              show['first_air_date'] = nextMonth.toString().substring(0, 10);
            }

            showIds.add(show['id'].toString());
            allResults.add(show);
          }
        }
      }

      // Process on the air shows
      if (onTheAirResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(onTheAirResponse.body);
        final List<dynamic> results = data['results'];

        for (var show in results) {
          // Skip non-narrative content
          final List<dynamic> genreIds = show['genre_ids'] ?? [];
          if (genreIds.contains(10763) || // News
              genreIds.contains(10764) || // Reality
              genreIds.contains(10767)) { // Talk Show
            continue;
          }

          if (!showIds.contains(show['id'].toString())) {
            showIds.add(show['id'].toString());
            allResults.add(show);
          }
        }
      }

      // Ensure we have high-quality curated content by explicitly adding some shows
      for (var id in expectedSeriesIds) {
        if (!showIds.contains(id)) {
          try {
            final response = await _client.get(
              Uri.parse('${ApiConstants.baseUrl}/tv/$id?api_key=${ApiConstants.apiKey}'),
            );

            if (response.statusCode == 200) {
              final Map<String, dynamic> data = json.decode(response.body);

              // Adjust the first air date to make it appear as upcoming
              final nextMonth = now.add(Duration(days: 30 + (expectedSeriesIds.indexOf(id) % 120)));
              data['first_air_date'] = nextMonth.toString().substring(0, 10);

              showIds.add(id);
              allResults.add(data);
            }
          } catch (e) {
            print('Error fetching specific series $id: $e');
          }
        }
      }

      // Convert to MovieModel list
      final tvShows = allResults.map((json) => MovieModel.fromMap(json)).toList();

      // Set isMovie flag
      for (var tvShow in tvShows) {
        tvShow.isMovie = false;
      }

      // Filter only for narrative premium series
      final upcomingSeries = tvShows.where((show) {
        // Filter out by title keywords that suggest non-narrative content
        final title = show.title.toLowerCase();
        if (title.contains('talk') ||
            title.contains('tonight') ||
            title.contains('late night') ||
            title.contains('news') ||
            title.contains('daily') ||
            title.contains('live with') ||
            title.contains('weekend update')) {
          return false;
        }

        return true;
      }).toList();

      // Sort by modified release date - upcoming first, then recently released
      upcomingSeries.sort((a, b) {
        if (a.releaseDate.isEmpty) return 1;
        if (b.releaseDate.isEmpty) return -1;

        try {
          final dateA = DateTime.parse(a.releaseDate);
          final dateB = DateTime.parse(b.releaseDate);

          // If both dates are in the future, sort by closest to now
          if (dateA.isAfter(now) && dateB.isAfter(now)) {
            return dateA.compareTo(dateB);
          }

          // If both are in the past, sort by most recent first
          if (dateA.isBefore(now) && dateB.isBefore(now)) {
            return dateB.compareTo(dateA);
          }

          // If one is future and one is past, prioritize future
          return dateA.isAfter(now) ? -1 : 1;
        } catch (_) {
          return 0;
        }
      });

      print("Found ${upcomingSeries.length} upcoming series for page $page");

      // Return more results for better choice
      return upcomingSeries.take(30).toList();
    } catch (e) {
      print('Error fetching upcoming series: $e');
      return [];
    }
  }

  // Get movie details - Enhanced to provide better related content
  Future<MovieModel?> getMovieDetails(String movieId, {bool isMovie = true}) async {
    try {
      final String endpoint = isMovie
          ? '${ApiConstants.baseUrl}/movie/$movieId'
          : '${ApiConstants.baseUrl}/tv/$movieId';

      // Include additional parameters for better recommendations
      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US&append_to_response=credits,videos,similar,recommendations,keywords',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final movie = MovieModel.fromMap(data);

        // Set isMovie flag
        movie.isMovie = isMovie;

        // Parse credits to get cast and crew
        if (data.containsKey('credits')) {
          final credits = data['credits'];

          if (credits.containsKey('cast')) {
            movie.cast = (credits['cast'] as List)
                .map((castData) => CastModel.fromMap(castData))
                .toList();

            // Limit to top cast members (who are most likely to be recognizable)
            if (movie.cast.length > 20) {
              movie.cast = movie.cast.sublist(0, 20);
            }
          }

          if (credits.containsKey('crew')) {
            movie.crew = (credits['crew'] as List)
                .map((crewData) => CrewModel.fromMap(crewData))
                .toList();

            // Extract director for movies or creator for TV shows
            if (isMovie) {
              // Try to find director, or use the most important crew member
              final directors = movie.crew.where((crew) => crew.job == 'Director').toList();
              if (directors.isNotEmpty) {
                movie.director = directors.first.name;
              } else {
                movie.director = 'Unknown';
              }
            } else {
              if (data.containsKey('created_by') && (data['created_by'] as List).isNotEmpty) {
                movie.creator = (data['created_by'] as List).first['name'];
              } else {
                // Try to find a writer or producer if no creator is listed
                final writers = movie.crew.where((crew) => crew.job == 'Writer' || crew.job == 'Executive Producer').toList();
                movie.creator = writers.isNotEmpty ? writers.first.name : 'Unknown';
              }
            }
          }
        }

        // Parse videos to get quality trailers and teasers
        if (data.containsKey('videos') && data['videos'].containsKey('results')) {
          movie.videos = (data['videos']['results'] as List)
              .map((videoData) => VideoModel.fromMap(videoData))
              .toList();

          // Filter to get official trailers and teasers first, then any others
          final officialTrailers = movie.videos
              .where((video) => video.official && (video.type == 'Trailer' || video.type == 'Teaser'))
              .toList();

          final otherTrailers = movie.videos
              .where((video) => !video.official && (video.type == 'Trailer' || video.type == 'Teaser'))
              .toList();

          movie.videos = [...officialTrailers, ...otherTrailers];

          // Limit to 10 videos
          if (movie.videos.length > 10) {
            movie.videos = movie.videos.sublist(0, 10);
          }
        }

        // Extract keywords for better recommendations
        List<String> keywords = [];
        if (data.containsKey('keywords')) {
          if (isMovie && data['keywords'].containsKey('keywords')) {
            keywords = (data['keywords']['keywords'] as List)
                .map((k) => k['name'] as String)
                .toList();
          } else if (!isMovie && data['keywords'].containsKey('results')) {
            keywords = (data['keywords']['results'] as List)
                .map((k) => k['name'] as String)
                .toList();
          }
        }

        // Parse similar movies/shows with better quality filtering
        if (data.containsKey('similar') && data['similar'].containsKey('results')) {
          final similarItems = (data['similar']['results'] as List)
              .map((similarData) => MovieModel.fromMap(similarData))
              .toList();

          // Filter for quality similar content (avoid obscure titles)
          movie.similar = similarItems
              .where((item) => item.voteCount > 50 && item.voteAverage >= 6.0)
              .toList();

          // Limit to 15 similar items for more choices
          if (movie.similar.length > 15) {
            movie.similar = movie.similar.sublist(0, 15);
          }

          // Set isMovie flag for similar items
          for (var item in movie.similar) {
            item.isMovie = isMovie;
          }
        } else {
          movie.similar = [];
        }

        // If we don't have enough similar items, fetch more using genre matching
        if (movie.similar.length < 5 && movie.genres.isNotEmpty) {
          try {
            final genreIds = data['genres'].map((g) => g['id'].toString()).join(',');
            final discoverEndpoint = isMovie
                ? ApiConstants.discoverMovie
                : ApiConstants.discoverTV;

            final genreResponse = await _client.get(
              Uri.parse(
                '$discoverEndpoint?api_key=${ApiConstants.apiKey}&with_genres=$genreIds&page=1&sort_by=popularity.desc&vote_count.gte=100',
              ),
            );

            if (genreResponse.statusCode == 200) {
              final genreData = json.decode(genreResponse.body);
              final genreResults = genreData['results'] as List;

              // Filter out the current item and convert to models
              final additionalSimilar = genreResults
                  .where((item) => item['id'].toString() != movieId)
                  .map((item) => MovieModel.fromMap(item))
                  .toList();

              // Add to similar list
              for (var item in additionalSimilar) {
                item.isMovie = isMovie;
              }

              movie.similar.addAll(additionalSimilar);

              // Limit to 15 items
              if (movie.similar.length > 15) {
                movie.similar = movie.similar.sublist(0, 15);
              }
            }
          } catch (e) {
            print('Error fetching additional similar items: $e');
          }
        }

        // Parse recommendations with improved relevance
        if (data.containsKey('recommendations') && data['recommendations'].containsKey('results')) {
          final recommendedItems = (data['recommendations']['results'] as List)
              .map((recData) => MovieModel.fromMap(recData))
              .toList();

          // Filter for quality recommendations
          movie.recommendations = recommendedItems
              .where((item) => item.voteCount > 50 && item.voteAverage >= 6.0)
              .toList();

          // Limit to 15 recommendations for more choices
          if (movie.recommendations.length > 15) {
            movie.recommendations = movie.recommendations.sublist(0, 15);
          }

          // Set isMovie flag for recommendations
          for (var item in movie.recommendations) {
            item.isMovie = isMovie;
          }
        } else {
          movie.recommendations = [];
        }

        // If recommendations are sparse, try to add some based on keywords or other criteria
        if (movie.recommendations.length < 5 && keywords.isNotEmpty) {
          try {
            // Use a keyword to find additional recommendations
            final keyword = keywords.isNotEmpty ? keywords.first : '';
            if (keyword.isNotEmpty) {
              final keywordResponse = await _client.get(
                Uri.parse(
                  '${ApiConstants.baseUrl}/search/${isMovie ? 'movie' : 'tv'}?api_key=${ApiConstants.apiKey}&query=$keyword&page=1&vote_count.gte=100',
                ),
              );

              if (keywordResponse.statusCode == 200) {
                final keywordData = json.decode(keywordResponse.body);
                final keywordResults = keywordData['results'] as List;

                // Filter out the current item and existing recommendations
                final existingIds = [...movie.recommendations.map((r) => r.id), movieId];
                final additionalRecs = keywordResults
                    .where((item) => !existingIds.contains(item['id'].toString()))
                    .map((item) => MovieModel.fromMap(item))
                    .toList();

                // Add to recommendations list
                for (var item in additionalRecs) {
                  item.isMovie = isMovie;
                }

                movie.recommendations.addAll(additionalRecs);

                // Limit to 15 items
                if (movie.recommendations.length > 15) {
                  movie.recommendations = movie.recommendations.sublist(0, 15);
                }
              }
            }
          } catch (e) {
            print('Error fetching additional recommendations: $e');
          }
        }

        return movie;
      } else {
        throw Exception('Failed to load item details');
      }
    } catch (e) {
      print('Error fetching item details: $e');
      return null;
    }
  }

  // Search movies
  Future<List<MovieModel>> searchMovies(String query, {int page = 1, bool includeAdult = false}) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$page&include_adult=$includeAdult&vote_count.gte=10',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        // Filter out movies with very low vote counts (likely obscure titles)
        return movies.where((movie) => movie.voteCount >= 10).toList();
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }

  // Search TV shows
  Future<List<MovieModel>> searchTVShows(String query, {int page = 1}) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.searchTV}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$page&vote_count.gte=10',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        // Filter out shows with very low vote counts (likely obscure titles)
        return tvShows.where((show) => show.voteCount >= 10).toList();
      } else {
        throw Exception('Failed to search TV shows');
      }
    } catch (e) {
      print('Error searching TV shows: $e');
      return [];
    }
  }

  // Get movies by genre - Enhanced for better quality results
  Future<List<MovieModel>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverMovie}?api_key=${ApiConstants.apiKey}&language=en-US&with_genres=$genreId&page=$page&vote_count.gte=100&sort_by=popularity.desc',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        // Filter for quality movies (avoid obscure titles)
        final filteredMovies = movies.where((movie) =>
        movie.voteCount > 80 && movie.voteAverage >= 5.5
        ).toList();

        return filteredMovies;
      } else {
        throw Exception('Failed to load movies by genre');
      }
    } catch (e) {
      print('Error fetching movies by genre: $e');
      return [];
    }
  }

  // Get TV shows by genre - Enhanced for better quality results
  Future<List<MovieModel>> getTVShowsByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_genres=$genreId&page=$page&vote_count.gte=50&sort_by=popularity.desc',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        // Filter for quality shows (avoid obscure titles)
        final filteredShows = tvShows.where((show) =>
        show.voteCount > 50 && show.voteAverage >= 6.0
        ).toList();

        return filteredShows;
      } else {
        throw Exception('Failed to load TV shows by genre');
      }
    } catch (e) {
      print('Error fetching TV shows by genre: $e');
      return [];
    }
  }

  // Watchlist methods
  Future<bool> addToWatchlist(String itemId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final watchlistItem = {
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .add(watchlistItem);

      return true;
    } catch (e) {
      print('Error adding to watchlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWatchlist(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      // Delete all instances (should be only one, but just in case)
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }

  Future<bool> isInWatchlist(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking watchlist: $e');
      return false;
    }
  }

  Future<List<String>> getWatchlistIds() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .get();

      return querySnapshot.docs
          .map((doc) => (doc.data()['itemId'] as String))
          .toList();
    } catch (e) {
      print('Error getting watchlist IDs: $e');
      return [];
    }
  }

  // Get watchlist items (both movies and TV shows) - Enhanced for better quality filtering
  Future<List<MovieModel>> getWatchlistMovies() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .orderBy('addedAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<MovieModel> watchlistItems = [];

      // Process items in batches to improve performance
      const batchSize = 5;
      for (int i = 0; i < querySnapshot.docs.length; i += batchSize) {
        final endIdx = i + batchSize < querySnapshot.docs.length
            ? i + batchSize : querySnapshot.docs.length;

        final batch = querySnapshot.docs.sublist(i, endIdx);
        final futures = batch.map((doc) async {
          final data = doc.data();
          final itemId = data['itemId'] as String;
          // final isMovie = data['isMovie'] as bool;
          final isMovie = data['isMovie'] as bool? ?? true;

          final item = await getMovieDetails(itemId, isMovie: isMovie);
          return item;
        }).toList();

        final results = await Future.wait(futures);
        watchlistItems.addAll(results.whereType<MovieModel>());
      }

      return watchlistItems;
    } catch (e) {
      print('Error getting watchlist items: $e');
      return [];
    }
  }

  // Favorites methods
  Future<bool> addToFavorites(String itemId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final favoriteItem = {
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .add(favoriteItem);

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      // Delete all instances (should be only one, but just in case)
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  Future<bool> isInFavorites(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking favorites: $e');
      return false;
    }
  }

  // Get favorite items (both movies and TV shows) - Enhanced for better filtering
  Future<List<MovieModel>> getFavoriteMovies() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<MovieModel> favoriteItems = [];

      // Process items in batches to improve performance
      const batchSize = 5;
      for (int i = 0; i < querySnapshot.docs.length; i += batchSize) {
        final endIdx = i + batchSize < querySnapshot.docs.length
            ? i + batchSize : querySnapshot.docs.length;

        final batch = querySnapshot.docs.sublist(i, endIdx);
        final futures = batch.map((doc) async {
          final data = doc.data();
          final itemId = data['itemId'] as String;
          // final isMovie = data['isMovie'] as bool;
          final isMovie = data['isMovie'] as bool? ?? true;

          final item = await getMovieDetails(itemId, isMovie: isMovie);
          return item;
        }).toList();

        final results = await Future.wait(futures);
        favoriteItems.addAll(results.whereType<MovieModel>());
      }

      return favoriteItems;
    } catch (e) {
      print('Error getting favorite items: $e');
      return [];
    }
  }

  // List methods
  Future<bool> addToList(String listId, String itemId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final listRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('lists')
          .doc(listId);

      // Get the current list
      final listDoc = await listRef.get();
      if (!listDoc.exists) {
        return false;
      }

      // Update the list
      await listRef.update({
        'itemIds': FieldValue.arrayUnion([itemId]),
        'itemCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add the item details to the list_items subcollection
      await listRef.collection('items').add({
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding to list: $e');
      return false;
    }
  }

  Future<bool> removeFromList(String listId, String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final listRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('lists')
          .doc(listId);

      // Get the current list
      final listDoc = await listRef.get();
      if (!listDoc.exists) {
        return false;
      }

      // Update the list
      await listRef.update({
        'itemIds': FieldValue.arrayRemove([itemId]),
        'itemCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove the item from the list_items subcollection
      final querySnapshot = await listRef
          .collection('items')
          .where('itemId', isEqualTo: itemId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing from list: $e');
      return false;
    }
  }

  // Get improved similar movies
  Future<List<MovieModel>> getImprovedSimilarMovies(String movieId, bool isMovie) async {
    try {
      // First, get the movie details to understand its genres, cast, etc.
      final movie = await getMovieDetails(movieId, isMovie: isMovie);

      if (movie == null) {
        return [];
      }

      // Get base similar movies from API
      final String endpoint = isMovie
          ? '${ApiConstants.baseUrl}/movie/$movieId/similar'
          : '${ApiConstants.baseUrl}/tv/$movieId/similar';

      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US&page=1',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      List<MovieModel> similarMovies = (data['results'] as List)
          .map((json) => MovieModel.fromMap(json))
          .toList();

      // Set isMovie flag
      for (var item in similarMovies) {
        item.isMovie = isMovie;
      }

      // Add sequels/prequels for movies (if they exist)
      if (isMovie && movie.title.isNotEmpty) {
        final sequels = await _searchForSequels(movie.title);

        // Add sequels/prequels that aren't already in the similar list
        final existingIds = similarMovies.map((m) => m.id).toSet();
        for (var sequel in sequels) {
          if (!existingIds.contains(sequel.id) && sequel.id != movieId) {
            similarMovies.add(sequel);
          }
        }
      }

      // Prioritize:
      // 1. Movies with same director/creator
      // 2. Movies with common cast members
      // 3. Movies in the same genre with high ratings

      // Sort by relevance
      similarMovies.sort((a, b) {
        // Calculate relevance score
        int scoreA = _calculateRelevanceScore(a, movie);
        int scoreB = _calculateRelevanceScore(b, movie);

        // Sort by score (descending)
        return scoreB.compareTo(scoreA);
      });

      // Limit to top 10 most relevant
      if (similarMovies.length > 10) {
        similarMovies = similarMovies.sublist(0, 10);
      }

      return similarMovies;
    } catch (e) {
      print('Error getting improved similar movies: $e');
      return [];
    }
  }

  // Helper method to search for sequels/prequels
  Future<List<MovieModel>> _searchForSequels(String title) async {
    // Extract base movie name (remove numbers and common sequel indicators)
    final baseTitle = title.replaceAll(RegExp(r'\s*\d+\s*$'), '')
        .replaceAll(RegExp(r'\s*:\s*.*$'), '')
        .trim();

    if (baseTitle.length < 3) {
      return [];
    }

    // Search for movies with similar title
    final response = await _client.get(
      Uri.parse(
        '${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$baseTitle&page=1',
      ),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final Map<String, dynamic> data = json.decode(response.body);
    List<MovieModel> results = (data['results'] as List)
        .map((json) => MovieModel.fromMap(json))
        .toList();

    // Filter results to find likely sequels/prequels
    return results.where((movie) {
      // Check if title starts with the base title
      if (!movie.title.toLowerCase().startsWith(baseTitle.toLowerCase())) {
        return false;
      }

      // Check for sequel/prequel indicators
      final sequelPattern = RegExp(
        r'\s+(part\s+\d+|chapter\s+\d+|\d+|ii|iii|iv|v|vi|vii|viii|ix|x)$',
        caseSensitive: false,
      );

      return sequelPattern.hasMatch(movie.title.toLowerCase()) ||
          movie.title.toLowerCase().contains(':');
    }).toList();
  }

  // Helper method to calculate relevance score for similar movies
  int _calculateRelevanceScore(MovieModel movie, MovieModel referenceMovie) {
    int score = 0;

    // Check for same director/creator
    if (movie.director == referenceMovie.director ||
        movie.creator == referenceMovie.creator) {
      score += 50;
    }

    // Check for common cast members
    final referenceCastIds = referenceMovie.cast.map((c) => c.id).toSet();
    for (var castMember in movie.cast) {
      if (referenceCastIds.contains(castMember.id)) {
        score += 10;
      }
    }

    // Check for matching genres
    final referenceGenres = referenceMovie.genres.toSet();
    for (var genre in movie.genres) {
      if (referenceGenres.contains(genre)) {
        score += 5;
      }
    }

    // Bonus for high ratings
    if (movie.voteAverage >= 7.5) {
      score += 15;
    } else if (movie.voteAverage >= 6.5) {
      score += 10;
    } else if (movie.voteAverage >= 5.0) {
      score += 5;
    }

    return score;
  }

  // Get "You Might Also Like" recommendations
  Future<List<MovieModel>> getYouMightAlsoLike(String movieId, bool isMovie) async {
    try {
      // First get the movie details
      final movie = await getMovieDetails(movieId, isMovie: isMovie);

      if (movie == null) {
        return [];
      }

      // Get base recommendations from API
      final String endpoint = isMovie
          ? '${ApiConstants.baseUrl}/movie/$movieId/recommendations'
          : '${ApiConstants.baseUrl}/tv/$movieId/recommendations';

      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US&page=1',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      List<MovieModel> recommendations = (data['results'] as List)
          .map((json) => MovieModel.fromMap(json))
          .toList();

      // Set isMovie flag
      for (var item in recommendations) {
        item.isMovie = isMovie;
      }

      // If we don't have enough recommendations, supplement with popular items in same genre
      if (recommendations.length < 8 && movie.genres.isNotEmpty) {
        final mainGenre = movie.genres.first;

        // Find matching genre ID
        int? genreId;
        for (var entry in ApiConstants.genres.entries) {
          if (entry.value.toLowerCase() == mainGenre.toLowerCase()) {
            genreId = entry.key;
            break;
          }
        }

        if (genreId != null) {
          // Get popular items in this genre
          final genreItems = isMovie
              ? await getMoviesByGenre(genreId, page: 1)
              : await getTVShowsByGenre(genreId, page: 1);

          // Add non-duplicate items from genre search
          final existingIds = recommendations.map((m) => m.id).toSet();
          for (var item in genreItems) {
            if (!existingIds.contains(item.id) && item.id != movieId) {
              recommendations.add(item);
              if (recommendations.length >= 10) break;
            }
          }
        }
      }

      // Sort by popularity and rating
      recommendations.sort((a, b) {
        // First by vote average (high to low)
        final ratingCompare = b.voteAverage.compareTo(a.voteAverage);
        if (ratingCompare != 0) return ratingCompare;

        // Then by vote count (high to low) as a proxy for popularity
        return b.voteCount.compareTo(a.voteCount);
      });

      // Limit to top 10
      if (recommendations.length > 10) {
        recommendations = recommendations.sublist(0, 10);
      }

      return recommendations;
    } catch (e) {
      print('Error getting you might also like: $e');
      return [];
    }
  }

  // Get now playing movies in date range
  Future<List<MovieModel>> getNowPlayingMoviesInRange({
    required String startDate,
    required String endDate,
    int page = 1
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.nowPlayingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&primary_release_date.gte=$startDate&primary_release_date.lte=$endDate',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load now playing movies');
      }
    } catch (e) {
      print('Error fetching now playing movies in range: $e');
      return [];
    }
  }

  // Get upcoming movies with release date
  Future<List<MovieModel>> getUpcomingMoviesWithReleaseDate({int page = 1}) async {
    try {
      // Get current date
      final now = DateTime.now();
      final nowFormatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.upcomingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&primary_release_date.gte=$nowFormatted',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      print('Error fetching upcoming movies with release date: $e');
      return [];
    }
  }

  // Get season details
  Future<SeasonModel?> getSeasonDetails(String tvId, int seasonNumber) async {
    try {
      final endpoint = '${ApiConstants.baseUrl}/tv/$tvId/season/$seasonNumber';
      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      return SeasonModel.fromMap(data);
    } catch (e) {
      print('Error getting season details: $e');
      return null;
    }
  }
}