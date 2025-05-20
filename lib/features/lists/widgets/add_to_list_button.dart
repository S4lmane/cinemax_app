// lib/features/lists/widgets/add_to_list_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/list_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/list_provider.dart';
import '../screens/create_list_screen.dart';

class AddToListButton extends StatelessWidget {
  final String movieId;
  final bool isMovie;

  const AddToListButton({
    super.key,
    required this.movieId,
    required this.isMovie,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.playlist_add),
      label: const Text('Add to List'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      onPressed: () => _showListsBottomSheet(context),
    );
  }

  void _showListsBottomSheet(BuildContext context) {
    // Load user lists
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.getUserLists(profileProvider.userProfile?.uid ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _ListSelectionSheet(
            movieId: movieId,
            isMovie: isMovie,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _ListSelectionSheet extends StatefulWidget {
  final String movieId;
  final bool isMovie;
  final ScrollController scrollController;

  const _ListSelectionSheet({
    required this.movieId,
    required this.isMovie,
    required this.scrollController,
  });

  @override
  _ListSelectionSheetState createState() => _ListSelectionSheetState();
}

class _ListSelectionSheetState extends State<_ListSelectionSheet> {
  final Map<String, bool> _selectedLists = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),

        // Header with title and content type indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Add to List',
                  style: TextStyles.headline5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.isMovie ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isMovie ? Icons.movie : Icons.tv,
                      color: widget.isMovie ? Colors.blue : Colors.purple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isMovie ? 'Movie' : 'TV Show',
                      style: TextStyles.caption.copyWith(
                        color: widget.isMovie ? Colors.blue : Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Divider
        const Divider(),

        // List of user's lists
        Expanded(
          child: Consumer<ProfileProvider>(
            builder: (context, profileProvider, _) {
              final lists = profileProvider.userLists;
              final isLoading = profileProvider.isLoading;
              final error = profileProvider.error;

              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (error != null && lists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: TextStyles.bodyText1,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          profileProvider.getUserLists(
                            profileProvider.userProfile?.uid ?? '',
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (lists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.playlist_add,
                        color: AppColors.textSecondary,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You don\'t have any lists yet',
                        style: TextStyles.headline6,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a list to add this item',
                        style: TextStyles.bodyText2,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create List'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }

              // Filter lists based on content type
              final filteredLists = lists.where((list) {
                if (widget.isMovie) {
                  return list.allowMovies;
                } else {
                  return list.allowTvShows;
                }
              }).toList();

              if (filteredLists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.playlist_add,
                        color: AppColors.textSecondary,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You don\'t have any lists that allow ${widget.isMovie ? 'movies' : 'TV shows'}',
                        textAlign: TextAlign.center,
                        style: TextStyles.headline6,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create New List'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: filteredLists.length,
                itemBuilder: (context, index) {
                  final list = filteredLists[index];

                  // Initialize selection state if needed
                  if (!_selectedLists.containsKey(list.id)) {
                    _selectedLists[list.id] = false;
                  }

                  return _buildEnhancedListCard(list, context);
                },
              );
            },
          ),
        ),

        // Submit button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _addToSelectedLists,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Text('Add to Lists'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced list card with proper UI
  Widget _buildEnhancedListCard(ListModel list, BuildContext context) {
    final isSelected = _selectedLists[list.id] ?? false;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLists[list.id] = !isSelected;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List header with cover image or gradient
            Stack(
              children: [
                // Cover image or gradient background
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: list.coverImageUrl.isEmpty
                          ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [AppColors.primary.withOpacity(0.8), AppColors.primary.withOpacity(0.5)]
                            : [Colors.blue.shade800.withOpacity(0.6), Colors.purple.shade900.withOpacity(0.6)],
                      )
                          : null,
                    ),
                    child: list.coverImageUrl.isNotEmpty
                        ? Image.network(
                      list.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [AppColors.primary.withOpacity(0.8), AppColors.primary.withOpacity(0.5)]
                                : [Colors.blue.shade800.withOpacity(0.6), Colors.purple.shade900.withOpacity(0.6)],
                          ),
                        ),
                      ),
                    )
                        : null,
                  ),
                ),

                // Checkbox overlay in the top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectedLists[list.id] = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Privacy indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          list.isPublic ? Icons.public : Icons.lock,
                          color: list.isPublic ? Colors.green : AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          list.isPublic ? 'Public' : 'Private',
                          style: TextStyles.caption.copyWith(
                            color: list.isPublic ? Colors.green : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // List details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // List name
                      Expanded(
                        child: Text(
                          list.name,
                          style: TextStyles.headline6.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Item count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${list.itemCount} ${list.itemCount == 1 ? 'item' : 'items'}',
                          style: TextStyles.caption.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description if available
                  if (list.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      list.description,
                      style: TextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Content type badges
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (list.allowMovies) ...[
                        _buildContentTypeBadge('Movies', Icons.movie, isSelected),
                        const SizedBox(width: 8),
                      ],
                      if (list.allowTvShows) ...[
                        _buildContentTypeBadge('TV Shows', Icons.tv, isSelected),
                      ],
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

  // Helper for content type badges
  Widget _buildContentTypeBadge(String text, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyles.caption.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToSelectedLists() async {
    // Check if at least one list is selected
    final selectedListIds = _selectedLists.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedListIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one list'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final listProvider = Provider.of<ListProvider>(context, listen: false);
      List<String> successLists = [];
      List<String> failedLists = [];

      // Add to each selected list
      for (final listId in selectedListIds) {
        // Clear current list first
        listProvider.clearCurrentList();

        // Get the list first
        final success = await listProvider.getListById(listId);
        if (!success) {
          failedLists.add(listId);
          continue;
        }

        // Add item to the list - CRITICAL: Pass isMovie flag correctly
        final addSuccess = await listProvider.addItemToList(
          widget.movieId,
          widget.isMovie,
        );

        if (addSuccess) {
          successLists.add(listId);
        } else {
          failedLists.add(listId);
        }
      }

      if (mounted) {
        if (successLists.isNotEmpty) {
          final count = successLists.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added to ${count == 1 ? '1 list' : '$count lists'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (failedLists.isNotEmpty) {
          final count = failedLists.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to add to ${count == 1 ? '1 list' : '$count lists'}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to lists: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}