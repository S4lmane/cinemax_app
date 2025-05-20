import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/movie_model.dart';
import '../../../shared/utils/recent_items_service.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/search_result_item.dart';
import '../widgets/search_filters.dart';
import '../../movie_details/screens/movie_details_screen.dart';
import '../../movie_details/providers/movie_details_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showClearButton = false;
  List<String> _searchHistory = [];
  bool _isFilterOpen = false;

  String _contentType = 'all';
  String _selectedGenre = 'all';
  RangeValues _yearRange = RangeValues(1900, DateTime.now().year.toDouble());
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.isEmpty) return;

    try {
      setState(() {
        _searchHistory.remove(query);
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.sublist(0, 10);
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      setState(() {
        _searchHistory = [];
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _showClearButton = _searchController.text.isNotEmpty;
    });

    if (_searchController.text.length > 2) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text.length > 2) {
          _performSearch(_searchController.text);
        }
      });
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    searchProvider.setFilters(
      contentType: _contentType,
      genre: _selectedGenre != 'all' ? _selectedGenre : null,
      startYear: _yearRange.start.toInt(),
      endYear: _yearRange.end.toInt(),
      minRating: _minRating,
    );

    searchProvider.searchMovies(query);
  }

  void _clearSearch() {
    _searchController.clear();
    Provider.of<SearchProvider>(context, listen: false).clearSearch();
  }

  void _toggleFilters() {
    setState(() {
      _isFilterOpen = !_isFilterOpen;
    });
  }

  void _updateFilters({
    String? contentType,
    String? genre,
    RangeValues? yearRange,
    double? minRating,
  }) {
    setState(() {
      if (contentType != null) _contentType = contentType;
      if (genre != null) _selectedGenre = genre;
      if (yearRange != null) _yearRange = yearRange;
      if (minRating != null) _minRating = minRating;
    });

    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  void _navigateToMovieDetails(dynamic item) {
    if (_searchController.text.isNotEmpty) {
      _saveSearchHistory(_searchController.text.trim());
    }

    String movieId;
    bool isMovie;

    if (item is Map<String, dynamic>) {
      movieId = item['id'].toString();
      isMovie = item['media_type'] == 'movie';
    } else if (item is MovieModel) {
      movieId = item.id;
      isMovie = item.isMovie;
    } else if (item is String) {
      movieId = item;
      isMovie = true;
    } else {
      print('Unexpected type for movie details navigation: ${item.runtimeType}');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MovieDetailsProvider(),
          child: MovieDetailsScreen(
            movieId: movieId,
            isMovie: isMovie,
          ),
        ),
      ),
    );

    if (item is MovieModel) {
      RecentItemsService.addRecentItem(item);
    } else if (item is Map<String, dynamic> &&
        (item['title'] != null || item['name'] != null)) {
      final movie = MovieModel(
        id: movieId,
        title: item['title'] ?? item['name'] ?? 'Unknown',
        posterPath: item['poster_path'] ?? '',
        backdropPath: item['backdrop_path'] ?? '',
        overview: item['overview'] ?? '',
        voteAverage: (item['vote_average'] ?? 0.0).toDouble(),
        voteCount: item['vote_count'] ?? 0,
        releaseDate: item['release_date'] ?? item['first_air_date'] ?? '',
        genres: [],
        runtime: 0,
        isMovie: isMovie,
      );

      RecentItemsService.addRecentItem(movie);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hintText: 'Search for movies or TV shows',
                      showClearButton: _showClearButton,
                      onClear: _clearSearch,
                      onSubmitted: () {
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFilterOpen ? Icons.filter_list_off : Icons.filter_list,
                      color: _isFilterOpen ? AppColors.primary : AppColors.textSecondary,
                    ),
                    onPressed: _toggleFilters,
                    tooltip: 'Search Filters',
                  ),
                ],
              ),
            ),

            if (_isFilterOpen)
              SearchFilters(
                contentType: _contentType,
                selectedGenre: _selectedGenre,
                yearRange: _yearRange,
                minRating: _minRating,
                onFilterChanged: _updateFilters,
              ),

            if (_contentType != 'all' || _selectedGenre != 'all' ||
                _yearRange.start > 1900 || _yearRange.end < DateTime.now().year ||
                _minRating > 0.0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_contentType != 'all')
                      FilterChip(
                        label: Text(_contentType == 'movies' ? 'Movies' : 'TV Shows'),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (_) {
                          _updateFilters(contentType: 'all');
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          _updateFilters(contentType: 'all');
                        },
                      ),
                    if (_selectedGenre != 'all')
                      FilterChip(
                        label: Text(_selectedGenre),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (_) {
                          _updateFilters(genre: 'all');
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          _updateFilters(genre: 'all');
                        },
                      ),
                    if (_yearRange.start > 1900 || _yearRange.end < DateTime.now().year)
                      FilterChip(
                        label: Text('${_yearRange.start.toInt()}-${_yearRange.end.toInt()}'),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (_) {
                          _updateFilters(yearRange: RangeValues(1900, DateTime.now().year.toDouble()));
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          _updateFilters(yearRange: RangeValues(1900, DateTime.now().year.toDouble()));
                        },
                      ),
                    if (_minRating > 0.0)
                      FilterChip(
                        label: Text('Rating ≥ ${_minRating.toInt()}'),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (_) {
                          _updateFilters(minRating: 0.0);
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          _updateFilters(minRating: 0.0);
                        },
                      ),
                  ],
                ),
              ),

            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  final isLoading = searchProvider.isLoading;
                  final hasQuery = searchProvider.query.isNotEmpty;
                  final searchResults = searchProvider.searchResults;

                  if (isLoading && !hasQuery) {
                    return const Center(
                      child: LoadingIndicator(),
                    );
                  }

                  if (hasQuery && searchResults.isEmpty && !isLoading) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'No results found for "${searchProvider.query}"',
                              style: TextStyles.headline6.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or search terms',
                            style: TextStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (hasQuery) {
                    return Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 16,
                          ),
                          itemCount: searchResults.length + (isLoading ? 1 : 0) + (searchProvider.hasMoreResults ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == searchResults.length) {
                              if (isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: LoadingIndicator(),
                                  ),
                                );
                              } else if (searchProvider.hasMoreResults) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        searchProvider.loadMoreResults();
                                      },
                                      child: const Text('Load More'),
                                    ),
                                  ),
                                );
                              }
                            }

                            if (index < searchResults.length) {
                              final result = searchResults[index];

                              String id;
                              String title;
                              String posterPath;
                              bool isMovie;
                              double voteAverage;
                              String overview = '';
                              String releaseDate = '';

                              if (result is Map<String, dynamic>) {
                                id = result['id'].toString();
                                title = result['title'] ?? result['name'] ?? 'Unknown';
                                posterPath = result['poster_path'] ?? '';
                                isMovie = result['media_type'] == 'movie';
                                voteAverage = (result['vote_average'] ?? 0.0).toDouble();
                                overview = result['overview'] ?? '';
                                releaseDate = result['release_date'] ?? result['first_air_date'] ?? '';
                              } else if (result is MovieModel) {
                                id = result.id;
                                title = result.title;
                                posterPath = result.posterPath;
                                isMovie = result.isMovie;
                                voteAverage = result.voteAverage;
                                overview = result.overview;
                                releaseDate = result.releaseDate;
                              } else {
                                return const SizedBox.shrink();
                              }

                              return SearchResultItem(
                                title: title,
                                posterPath: posterPath,
                                voteAverage: voteAverage,
                                isMovie: isMovie,
                                overview: overview,
                                releaseDate: releaseDate,
                                onTap: () => _navigateToMovieDetails(result),
                              );
                            }

                            return null;
                          },
                        ),

                        if (isLoading && searchResults.isNotEmpty)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: AppColors.background.withOpacity(0.8),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading more results...'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return _buildSearchSuggestions();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'Action Movies',
      'Popular TV Shows',
      'Sci-Fi',
      'Oscar Winners',
      'Comedy',
      'Drama',
      'Thriller',
      'Animation',
      'Documentary',
      'Romance',
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: TextStyles.headline6,
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Search History'),
                          content: const Text('Are you sure you want to clear your search history?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearSearchHistory();
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchHistory.map((query) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = query;
                      _performSearch(query);
                      _searchFocusNode.unfocus();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            query,
                            style: TextStyles.bodyText2,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            Text(
              'Trending Searches',
              style: TextStyles.headline6,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((suggestion) {
                return InkWell(
                  onTap: () {
                    _searchController.text = suggestion;
                    _performSearch(suggestion);
                    _searchFocusNode.unfocus();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          suggestion,
                          style: TextStyles.bodyText2,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}