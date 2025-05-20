import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as app_error;
import '../../../models/list_model.dart';
import '../providers/list_provider.dart';
import '../../movie_details/screens/movie_details_screen.dart';
import '../widgets/list_item.dart';

class ListScreen extends StatefulWidget {
  final String? listId;
  final ListModel? list; // Optional param if list is already loaded

  const ListScreen({
    super.key,
    this.listId,
    this.list,
  }) : assert(listId != null || list != null);

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final listProvider = Provider.of<ListProvider>(context, listen: false);

    if (widget.list != null) {
      // If list is provided, just get the items
      listProvider.clearCurrentList();
      await listProvider.getListById(widget.list!.id);
    } else if (widget.listId != null) {
      // Otherwise, load the list by ID
      await listProvider.getListById(widget.listId!);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteList() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    final listProvider = Provider.of<ListProvider>(context, listen: false);
    final success = await listProvider.deleteList();

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('List deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(listProvider.error ?? 'Failed to delete list'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _confirmDeleteList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('Are you sure you want to delete this list? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteList();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMovieDetails(String movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movieId: movieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListProvider>(
      builder: (context, listProvider, _) {
        final list = listProvider.currentList;
        final listItems = listProvider.listItems;
        final isLoading = listProvider.isLoading || _isLoading;
        final error = listProvider.error;

        if (isLoading && list == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('List'),
              centerTitle: true,
            ),
            body: const Center(
              child: LoadingIndicator(),
            ),
          );
        }

        if (error != null && list == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('List'),
              centerTitle: true,
            ),
            body: app_error.ErrorWidget(
              message: error,
              onRetry: _loadList,
            ),
          );
        }

        if (list == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('List'),
              centerTitle: true,
            ),
            body: const app_error.ErrorWidget(
              message: 'List not found',
              icon: Icons.playlist_remove,
            ),
          );
        }

        // Check if user is the owner
        final currentUser = FirebaseAuth.instance.currentUser;
        final isOwner = currentUser != null && currentUser.uid == list.userId;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    list.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image or gradient
                      list.coverImageUrl.isNotEmpty
                          ? Image.network(
                        list.coverImageUrl,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade700,
                              Colors.purple.shade500,
                            ],
                          ),
                        ),
                      ),

                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _isDeleting ? null : _confirmDeleteList,
                      tooltip: 'Delete List',
                    ),
                ],
              ),

              // List info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (list.description.isNotEmpty) ...[
                        Text(
                          list.description,
                          style: TextStyles.bodyText1,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // List stats
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: list.isPublic
                                  ? Colors.green.withOpacity(0.2)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: list.isPublic
                                    ? Colors.green
                                    : AppColors.textSecondary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  list.isPublic ? Icons.public : Icons.lock,
                                  color: list.isPublic
                                      ? Colors.green
                                      : AppColors.textSecondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  list.isPublic ? 'Public' : 'Private',
                                  style: TextStyles.caption.copyWith(
                                    color: list.isPublic
                                        ? Colors.green
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  list.allowMovies && list.allowTvShows
                                      ? Icons.video_library
                                      : list.allowMovies
                                      ? Icons.movie
                                      : Icons.tv,
                                  color: AppColors.textSecondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  list.allowMovies && list.allowTvShows
                                      ? 'Movies & TV'
                                      : list.allowMovies
                                      ? 'Movies Only'
                                      : 'TV Shows Only',
                                  style: TextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${list.itemCount} ${list.itemCount == 1 ? 'item' : 'items'}',
                            style: TextStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                  ),
                ),
              ),

              // List items
              listItems.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This list is empty',
                        style: TextStyles.headline6.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Add items by browsing movies and TV shows',
                          textAlign: TextAlign.center,
                          style: TextStyles.bodyText2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final movie = listItems[index];
                      return ListItem(
                        movie: movie,
                        onTap: () => _navigateToMovieDetails(movie.id),
                        onRemove: isOwner
                            ? () => listProvider.removeItemFromList(movie.id)
                            : null,
                      );
                    },
                    childCount: listItems.length,
                  ),
                ),
              ),

              // Loading indicator
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: LoadingIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}