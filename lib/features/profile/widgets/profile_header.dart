import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/custom_image.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;

  const ProfileHeader({
    Key? key,
    required this.user,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Banner
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
          ),
          child: user.bannerImageUrl.isNotEmpty
              ? CustomImage(
            imageUrl: user.bannerImageUrl,
            fit: BoxFit.cover,
          )
              : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),

        // Profile image and details
        Positioned(
          top: 130,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: user.profileImageUrl.isNotEmpty
                        ? CustomImage(
                      imageUrl: user.profileImageUrl,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: AppColors.cardBackground,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.nickname,
                style: TextStyles.headline4,
              ),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',  // Make sure to include the @ symbol
                style: TextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (user.isVerified || user.isModerator)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (user.isModerator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.shield,
                                color: Colors.black,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Moderator',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}