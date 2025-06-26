import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/cast_model.dart';
import '../../people/providers/people_provider.dart';
import '../../people/screens/person_detail_screen.dart';

class CastList extends StatelessWidget {
  final List<CastModel> cast;

  const CastList({
    super.key,
    required this.cast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cast',
          style: TextStyles.headline5,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final castMember = cast[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == cast.length - 1 ? 0 : 16,
                ),
                child: _CastCard(
                  castMember: castMember,
                  onTap: () => _navigateToPersonDetails(context, castMember),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToPersonDetails(BuildContext context, CastModel castMember) {
    // Navigate to person detail screen with provider
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => PeopleProvider(),
          child: PersonDetailScreen(
            personId: int.parse(castMember.id),
            name: castMember.name,
          ),
        ),
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  final CastModel castMember;
  final VoidCallback onTap;

  const _CastCard({
    required this.castMember,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image with tap feedback
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: castMember.getProfileUrl(),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.cardBackground,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardBackground,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 40,
                      ),
                    ),
                  ),
                  // Overlay to indicate it's clickable
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                      ),
                      child: const Center(
                        /*child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),*/
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Name and character
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      castMember.name,
                      style: TextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      castMember.character,
                      style: TextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}