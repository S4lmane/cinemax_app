import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../widgets/category_tabs.dart';
import '../../auth/providers/auth_provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['New', 'Popular', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar with profile button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DISCOVER',
                    style: TextStyles.headline2,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to profile screen
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: user?.photoURL != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            user!.photoURL!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            CategoryTabs(
              tabs: _tabs,
              controller: _tabController,
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // New movies
                  _buildMoviesGrid('New'),

                  // Popular movies
                  _buildMoviesGrid('Popular'),

                  // Upcoming movies
                  _buildMoviesGrid('Upcoming'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesGrid(String category) {
    // This is just a placeholder. You'll implement this with real data later.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$category Movies',
            style: TextStyles.headline3,
          ),
          const SizedBox(height: 16),
          const Text(
            'This is a placeholder for the movie grid.',
            style: TextStyles.bodyText1,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Sign out (just for testing)
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Sign Out (Test)'),
          ),
        ],
      ),
    );
  }
}