// lib/features/discover/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/movie_model.dart';
import '../../movie_details/providers/movie_details_provider.dart';
import '../widgets/content_tabs.dart';
import '../widgets/movie_grid.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/discover_provider.dart';
import '../../movie_details/screens/movie_details_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with TickerProviderStateMixin {
  // class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TabController _contentTypeController;
  final List<String> _tabs = ['New', 'Popular', 'Upcoming'];
  final List<String> _contentTypes = ['Movies', 'TV Shows'];
  int _currentPage = 1;
  String _currentContentType = 'Movies';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _contentTypeController = TabController(length: _contentTypes.length, vsync: this);

    _tabController.addListener(_handleTabChange);
    _contentTypeController.addListener(_handleContentTypeChange);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _contentTypeController.removeListener(_handleContentTypeChange);
    _tabController.dispose();
    _contentTypeController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
      });
      _loadContent();
    }
  }

  void _handleContentTypeChange() {
    if (_contentTypeController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
        _currentContentType = _contentTypes[_contentTypeController.index];
      });
      _loadContent();
    }
  }

  void _loadContent() {
    final discoverProvider = Provider.of<DiscoverProvider>(context, listen: false);
    final isMovies = _currentContentType == 'Movies';

    switch (_tabController.index) {
      case 0: // New
        if (isMovies) {
          discoverProvider.fetchNewMovies(page: _currentPage, resetIfFirstPage: true);
        } else {
          discoverProvider.fetchNewTVShows(page: _currentPage, resetIfFirstPage: true);
        }
        break;
      case 1: // Popular
        if (isMovies) {
          discoverProvider.fetchPopularMovies(page: _currentPage, resetIfFirstPage: true);
        } else {
          discoverProvider.fetchPopularTVShows(page: _currentPage, resetIfFirstPage: true);
        }
        break;
      case 2: // Upcoming
        if (isMovies) {
          discoverProvider.fetchUpcomingMovies(page: _currentPage, resetIfFirstPage: true);
        } else {
          discoverProvider.fetchUpcomingTVShows(page: _currentPage, resetIfFirstPage: true);
        }
        break;
    }
  }

  void _loadMoreContent() {
    setState(() {
      _currentPage++;
    });
    _loadContent();
  }

  void _navigateToDetails(BuildContext context, MovieModel movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MovieDetailsProvider(),
          child: MovieDetailsScreen(
            movieId: movie.id,
            isMovie: movie.isMovie,
          ),
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

            // Content type toggle (Movies/TV Shows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _contentTypeController,
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  indicator: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: TextStyles.headline6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyles.headline6.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: _contentTypes.map((type) => Tab(text: type)).toList(),
                ),
              ),
            ),

            // Category tab bar (New/Popular/Upcoming)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ContentTabs(
                tabs: _tabs,
                controller: _tabController,
              ),
            ),

            // Tab content
            Expanded(
              child: Consumer<DiscoverProvider>(
                builder: (context, discoverProvider, _) {
                  // Determine which content to display based on current tab and content type
                  final isLoading = discoverProvider.isLoading;
                  final error = discoverProvider.error;

                  List<MovieModel> content = [];
                  bool isMovies = _currentContentType == 'Movies';

                  switch (_tabController.index) {
                    case 0: // New
                      content = isMovies
                          ? discoverProvider.newMovies
                          : discoverProvider.newTVShows;
                      break;
                    case 1: // Popular
                      content = isMovies
                          ? discoverProvider.popularMovies
                          : discoverProvider.popularTVShows;
                      break;
                    case 2: // Upcoming
                      content = isMovies
                          ? discoverProvider.upcomingMovies
                          : discoverProvider.upcomingTVShows;
                      break;
                  }

                  return MovieGrid(
                    movies: content,
                    isLoading: isLoading,
                    errorMessage: error,
                    onMovieTap: (movie) => _navigateToDetails(context, movie),
                    onRetry: _loadContent,
                    onLoadMore: _loadMoreContent,
                    emptyMessage: 'No ${isMovies ? 'movies' : 'TV shows'} found',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}