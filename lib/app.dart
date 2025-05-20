import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/discover/screens/discover_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/discover/providers/movies_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/search/providers/search_provider.dart';
import 'shared/navigation/bottom_nav_bar.dart';
import 'core/widgets/loading_indicator.dart';

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MoviesProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MaterialApp(
        title: 'Movie App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: LoadingIndicator(),
                ),
              );
            }

            if (authProvider.isAuthenticated) {
              return const MainScreen();
            }

            return const OnboardingScreen();
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DiscoverScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Get safe area padding to avoid bottom overflow
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: _screens[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Padding(
        // Add padding to avoid overflow with system UI
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 8),
        child: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}