import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/list_model.dart';
import '../providers/profile_provider.dart';
import '../../lists/screens/create_list_screen.dart';
import '../../lists/screens/list_screen.dart';

class UserLists extends StatelessWidget {
  final List<ListModel> lists;
  final bool isCurrentUser;

  const UserLists({
    Key? key,
    required this.lists,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lists
        lists.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
          padding: EdgeInsets.only(
            top: 16,
            bottom: isCurrentUser ? 80 : 16,
            left: 16,
            right: 16,
          ),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return _buildListItem(context, list);
          },
        ),

        // Create list button (only for current user)
        if (isCurrentUser)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateListScreen(),
                  ),
                ).then((_) {
                  // Refresh lists after creating a new one
                  Provider.of<ProfileProvider>(context, listen: false)
                      .initializeUserProfile();
                });
              },
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.add,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isCurrentUser
                  ? 'You haven\'t created any lists yet'
                  : 'This user hasn\'t created any lists yet',
              style: TextStyles.headline6.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateListScreen(),
                    ),
                  ).then((_) {
                    // Refresh lists after creating a new one
                    Provider.of<ProfileProvider>(context, listen: false)
                        .initializeUserProfile();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Create List'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ListModel list) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListScreen(list: list),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List image or gradient
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                gradient: list.coverImageUrl.isEmpty
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primary.withOpacity(0.3),
                  ],
                )
                    : null,
                image: list.coverImageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(list.coverImageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image load error silently
                  },
                )
                    : null,
              ),
              child: Stack(
                children: [
                  // Privacy indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            list.isPublic ? Icons.public : Icons.lock,
                            color: list.isPublic
                                ? Colors.green
                                : AppColors.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            list.isPublic ? 'Public' : 'Private',
                            style: TextStyles.caption.copyWith(
                              color: list.isPublic
                                  ? Colors.green
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: TextStyles.headline5,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (list.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      list.description,
                      style: TextStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.movie_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${list.itemCount} ${list.itemCount == 1 ? 'item' : 'items'}',
                        style: TextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_getTimeAgo(list.updatedAt)}',
                        style: TextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'just now'; // Handle future dates gracefully
    }

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}