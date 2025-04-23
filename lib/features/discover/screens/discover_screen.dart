import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../movie_details/providers/movie_details_provider.dart';
import '../widgets/category_tabs.dart';
import '../widgets/movie_grid.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/movies_provider.dart';
import '../../movie_details/screens/movie_details_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['New', 'Popular', 'Upcoming'];
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovies();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
      });
      _loadMovies();
    }
  }

  void _loadMovies() {
    final moviesProvider = Provider.of<MoviesProvider>(context, listen: false);

    switch (_tabController.index) {
      case 0:
        moviesProvider.fetchNewMovies(page: _currentPage, resetIfFirstPage: true);
        break;
      case 1:
        moviesProvider.fetchPopularMovies(page: _currentPage, resetIfFirstPage: true);
        break;
      case 2:
        moviesProvider.fetchUpcomingMovies(page: _currentPage, resetIfFirstPage: true);
        break;
    }
  }

  void _loadMoreMovies() {
    setState(() {
      _currentPage++;
    });
    _loadMovies();
  }

  void _navigateToMovieDetails(BuildContext context, String movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MovieDetailsProvider(),
          child: MovieDetailsScreen(movieId: movieId),
        ),
      ),
    );
  }

  void _navigateToProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser != null) {
      // Navigate to the profile screen with the provider
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => ProfileProvider(),
            child: const ProfileScreen(),
          ),
        ),
      ).then((_) {
        setState(() {});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to view your profile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar with profile button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DISCOVER',
                    style: TextStyles.headline2,
                  ),
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                              ? Image.network(
                            user.photoURL!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          )
                              : const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryTabs(
                tabs: _tabs,
                controller: _tabController,
              ),
            ),

            // Tab content
            Expanded(
              child: Consumer<MoviesProvider>(
                builder: (context, moviesProvider, _) {
                  // Determine which movies to display based on current tab
                  final isLoading = moviesProvider.isLoading;
                  final error = moviesProvider.error;

                  switch (_tabController.index) {
                    case 0: // New
                      return MovieGrid(
                        movies: moviesProvider.newMovies,
                        isLoading: isLoading,
                        errorMessage: error,
                        onMovieTap: (movie) => _navigateToMovieDetails(context, movie.id),
                        onRetry: _loadMovies,
                        onLoadMore: _loadMoreMovies,
                      );
                    case 1: // Popular
                      return MovieGrid(
                        movies: moviesProvider.popularMovies,
                        isLoading: isLoading,
                        errorMessage: error,
                        onMovieTap: (movie) => _navigateToMovieDetails(context, movie.id),
                        onRetry: _loadMovies,
                        onLoadMore: _loadMoreMovies,
                      );
                    case 2: // Upcoming
                      return MovieGrid(
                        movies: moviesProvider.upcomingMovies,
                        isLoading: isLoading,
                        errorMessage: error,
                        onMovieTap: (movie) => _navigateToMovieDetails(context, movie.id),
                        onRetry: _loadMovies,
                        onLoadMore: _loadMoreMovies,
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}