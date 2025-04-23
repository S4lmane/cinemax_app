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
    Key? key,
    required this.movieId,
    required this.isMovie,
  }) : super(key: key);

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
    Key? key,
    required this.movieId,
    required this.isMovie,
    required this.scrollController,
  }) : super(key: key);

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
        // Header
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Add to List',
            style: TextStyles.headline5,
          ),
        ),

        // List of lists
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

                  return Card(
                    color: _selectedLists[list.id]!
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.cardBackground,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedLists[list.id]!
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        list.name,
                        style: TextStyles.headline6.copyWith(
                          color: _selectedLists[list.id]!
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        list.description.isNotEmpty
                            ? list.description
                            : '${list.itemCount} ${list.itemCount == 1 ? 'item' : 'items'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.caption,
                      ),
                      secondary: Icon(
                        list.isPublic ? Icons.public : Icons.lock,
                        color: _selectedLists[list.id]!
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      value: _selectedLists[list.id],
                      onChanged: (value) {
                        setState(() {
                          _selectedLists[list.id] = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
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
        // Get the list first
        final success = await listProvider.getListById(listId);
        if (!success) {
          failedLists.add(listId);
          continue;
        }

        // Add item to the list
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