import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/search_result_item.dart';
import '../../movie_details/screens/movie_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _showClearButton = _searchController.text.isNotEmpty;
    });

    if (_searchController.text.length > 2) {
      // Debounce search
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text.length > 2) {
          Provider.of<SearchProvider>(context, listen: false)
              .searchMovies(_searchController.text);
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    Provider.of<SearchProvider>(context, listen: false).clearSearch();
  }

  void _navigateToMovieDetails(String movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movieId: movieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CustomSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search for movies or TV shows',
                showClearButton: _showClearButton,
                onClear: _clearSearch,
              ),
            ),

            // Search results or suggestions
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  final isLoading = searchProvider.isLoading;
                  final hasQuery = searchProvider.query.isNotEmpty;
                  final searchResults = searchProvider.searchResults;

                  if (isLoading) {
                    return const Center(
                      child: LoadingIndicator(),
                    );
                  }

                  if (hasQuery && searchResults.isEmpty) {
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
                          Text(
                            'No results found for "${searchProvider.query}"',
                            style: TextStyles.headline6.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (hasQuery) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final movie = searchResults[index];
                        return SearchResultItem(
                          movie: movie,
                          onTap: () => _navigateToMovieDetails(movie.id),
                        );
                      },
                    );
                  }

                  // Show search suggestions
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  _searchFocusNode.unfocus();
                  Provider.of<SearchProvider>(context, listen: false)
                      .searchMovies(suggestion);
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
    );
  }
}