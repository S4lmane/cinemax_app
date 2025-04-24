// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/user_stats.dart';
import '../widgets/user_lists.dart';
import '../widgets/user_watchlist.dart';
import '../widgets/user_favorites.dart';
import 'edit_profile_screen.dart';
import '../../movie_details/providers/movie_details_provider.dart';
import '../../movie_details/screens/movie_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Lists', 'Watchlist', 'Favorites'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Load user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  void _loadUserProfile() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final String uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isNotEmpty) {
      profileProvider.initializeUserProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    ).then((_) {
      // Refresh profile after editing
      _loadUserProfile();
    });
  }

  void _navigateToMovieDetails(String movieId) {
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

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSignOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _performSignOut() {
    try {
      // Try using Firebase Auth directly instead of the provider
      FirebaseAuth.instance.signOut().then((_) {
        // Navigate back to the root after signing out
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = widget.userId == null ||
        widget.userId == currentUser?.uid;

    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          final userProfile = profileProvider.userProfile;
          final isLoading = profileProvider.isLoading;
          final error = profileProvider.error;

          if (isLoading && userProfile == null) {
            return const Center(
              child: LoadingIndicator(),
            );
          }

          if (error != null && userProfile == null) {
            return app_error.ErrorWidget(
              message: error,
              onRetry: _loadUserProfile,
            );
          }

          if (userProfile == null) {
            return const app_error.ErrorWidget(
              message: 'User profile not found',
              icon: Icons.person_off_outlined,
            );
          }

          // Get stats
          final listsCount = profileProvider.userLists.length;
          final watchlistCount = profileProvider.watchlistItems.length;
          final favoritesCount = profileProvider.favoriteItems.length;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _navigateToEditProfile,
                        tooltip: 'Edit Profile',
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'signout' && isCurrentUser) {
                          _signOut();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (isCurrentUser)
                          const PopupMenuItem<String>(
                            value: 'signout',
                            child: ListTile(
                              leading: Icon(Icons.logout, color: AppColors.error),
                              title: Text('Sign Out'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (!isCurrentUser)
                          const PopupMenuItem<String>(
                            value: 'report',
                            child: ListTile(
                              leading: Icon(Icons.report_outlined, color: AppColors.error),
                              title: Text('Report User'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: ProfileHeader(
                      user: userProfile,
                      isCurrentUser: isCurrentUser,
                    ),
                  ),
                ),

                // Stats section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: UserStats(
                      listsCount: listsCount,
                      watchlistCount: watchlistCount,
                      favoritesCount: favoritesCount,
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.primary,
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: TextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: TextStyles.bodyText1,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Lists Tab
                  UserLists(
                    lists: profileProvider.userLists,
                    isCurrentUser: isCurrentUser,
                  ),

                  // Watchlist Tab - Implement the new watchlist widget
                  UserWatchlist(
                    movies: profileProvider.watchlistItems,
                    isCurrentUser: isCurrentUser,
                    isLoading: profileProvider.isLoadingWatchlist,
                    onMovieTap: _navigateToMovieDetails,
                    onRefresh: () => profileProvider.refreshWatchlist(),
                  ),

                  // Favorites Tab - Implement the new favorites widget
                  UserFavorites(
                    movies: profileProvider.favoriteItems,
                    isCurrentUser: isCurrentUser,
                    isLoading: profileProvider.isLoadingFavorites,
                    onMovieTap: _navigateToMovieDetails,
                    onRefresh: () => profileProvider.refreshFavorites(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}