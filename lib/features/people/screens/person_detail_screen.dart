import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;  
import '../../../models/person_details.dart';
import '../../../models/person_credits.dart';
import '../providers/people_provider.dart';
import '../../movie_details/screens/movie_details_screen.dart';
import '../widgets/award_chip.dart';

class PersonDetailScreen extends StatefulWidget {
  final int personId;
  final String name;

  const PersonDetailScreen({
    Key? key,
    required this.personId,
    required this.name,
  }) : super(key: key);

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load person details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PeopleProvider>(context, listen: false)
          .fetchPersonDetails(widget.personId);
      Provider.of<PeopleProvider>(context, listen: false)
          .fetchPersonCredits(widget.personId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<PeopleProvider>(
        builder: (context, peopleProvider, child) {
          final personDetails = peopleProvider.currentPersonDetails;
          final personCredits = peopleProvider.currentPersonCredits;
          final isLoading = peopleProvider.isLoadingPersonDetails ||
              peopleProvider.isLoadingPersonCredits;
          final hasError = peopleProvider.personDetailsError != null ||
              peopleProvider.personCreditsError != null;

          if (isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (hasError) {
            // Using your project's actual ErrorWidget class with alias
            return app_error.ErrorWidget(
              message: peopleProvider.personDetailsError ??
                  peopleProvider.personCreditsError ??
                  "Failed to load person details",
              onRetry: () {
                peopleProvider.fetchPersonDetails(widget.personId);
                peopleProvider.fetchPersonCredits(widget.personId);
              },
            );
          }

          if (personDetails == null || personCredits == null) {
            return const Center(child: Text("No data available"));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, personDetails),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonInfo(personDetails, personCredits),
                      const SizedBox(height: 16),
                      _buildBiography(personDetails),
                      const SizedBox(height: 24),
                      if (personDetails.awards.isNotEmpty) ...[
                        _buildAwardsSection(personDetails),
                        const SizedBox(height: 24),
                      ],
                      _buildFilmographyHeader(personCredits),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildFilmographyGrid(context, personCredits),
              SliverToBoxAdapter(
                child: const SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, PersonDetails person) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Profile image
            person.profilePath != null
                ? Image.network(
              'https://image.tmdb.org/t/p/w780${person.profilePath}',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.cardBackground,
                  child: const Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.white54,
                  ),
                );
              },
            )
                : Container(
              color: AppColors.cardBackground,
              child: const Icon(
                Icons.person,
                size: 100,
                color: Colors.white54,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.8),
                    AppColors.background,
                  ],
                ),
              ),
            ),
            // Name at bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                person.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPersonInfo(PersonDetails person, PersonCredits credits) {
    final now = DateTime.now();
    final birthDate = person.birthday != null ? DateTime.parse(person.birthday!) : null;
    final deathDate = person.deathday != null ? DateTime.parse(person.deathday!) : null;

    int? age;
    if (birthDate != null) {
      if (deathDate != null) {
        age = deathDate.year - birthDate.year;
        if (deathDate.month < birthDate.month ||
            (deathDate.month == birthDate.month && deathDate.day < birthDate.day)) {
          age--;
        }
      } else {
        age = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
      }
    }

    String lifespan = '';
    if (birthDate != null) {
      final formattedBirthDate = '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';

      if (deathDate != null) {
        final formattedDeathDate = '${deathDate.year}-${deathDate.month.toString().padLeft(2, '0')}-${deathDate.day.toString().padLeft(2, '0')}';
        lifespan = '$formattedBirthDate to $formattedDeathDate (Age: $age)';
      } else {
        lifespan = 'Born: $formattedBirthDate' + (age != null ? ' (Age: $age)' : '');
      }
    }

    // Calculate total works
    final totalWorks = (credits.cast?.length ?? 0) + (credits.crew?.length ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic info row
        Row(
          children: [
            if (person.knownForDepartment != null) ...[
              Chip(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                label: Text(
                  person.knownForDepartment!,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (person.placeOfBirth != null) ...[
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  person.placeOfBirth!,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Birthdate/Age/Deathdate info
        if (lifespan.isNotEmpty)
          Text(
            lifespan,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),

        const SizedBox(height: 12),

        // Popularity and work count
        Row(
          children: [
            const Icon(Icons.trending_up, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Popularity: ${person.popularity?.toStringAsFixed(1) ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.movie_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Total works: $totalWorks',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBiography(PersonDetails person) {
    if (person.biography == null || person.biography!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biography',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          person.biography!,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAwardsSection(PersonDetails person) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Awards',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: person.awards.map((award) => AwardChip(award: award)).toList(),
        ),
      ],
    );
  }

  Widget _buildFilmographyHeader(PersonCredits credits) {
    final totalWorks = (credits.cast?.length ?? 0) + (credits.crew?.length ?? 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filmography ($totalWorks)',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilmographyGrid(BuildContext context, PersonCredits credits) {
    final allWorks = [...?credits.cast, ...?credits.crew];

    // Sort by popularity or release date
    allWorks.sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));

    // Remove duplicates (same movie might appear in both cast and crew)
    final uniqueWorks = <int, dynamic>{};
    for (var work in allWorks) {
      uniqueWorks[work.id] = work;
    }

    final items = uniqueWorks.values.toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final work = items[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsScreen(
                      movieId: work.id,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: work.posterPath != null
                          ? Image.network(
                        'https://image.tmdb.org/t/p/w185${work.posterPath}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.cardBackground,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            color: AppColors.cardBackground,
                            child: const Center(
                              child: Icon(
                                Icons.movie_outlined,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        },
                      )
                          : Container(
                        width: double.infinity,
                        color: AppColors.cardBackground,
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    work.title ?? work.name ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    work.releaseDate?.substring(0, 4) ??
                        work.firstAirDate?.substring(0, 4) ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}