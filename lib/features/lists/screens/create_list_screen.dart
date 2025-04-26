import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../profile/providers/profile_provider.dart';
import 'list_screen.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({Key? key}) : super(key: key);

  @override
  _CreateListScreenState createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isPublic = false;
  bool _allowMovies = true;
  bool _allowTvShows = false;

  File? _coverImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _createList() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      final listId = await profileProvider.createList(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        allowMovies: _allowMovies,
        allowTvShows: _allowTvShows,
        coverImage: _coverImage,
      );

      if (listId != null) {
        if (mounted) {
          // Navigate to the list screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ListScreen(listId: listId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileProvider.error ?? 'Failed to create list'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating list: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create List'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      image: _coverImage != null
                          ? DecorationImage(
                        image: FileImage(_coverImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _coverImage == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add Cover Image',
                          style: TextStyles.bodyText1,
                        ),
                        Text(
                          '(Optional)',
                          style: TextStyles.caption,
                        ),
                      ],
                    )
                        : null,
                  ),
                ),

                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'List Name',
                    hintText: 'Enter a name for your list',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for your list';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your list (optional)',
                  ),
                  maxLines: 3,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 24),

                // Privacy toggle
                SwitchListTile(
                  title: const Text('Public List'),
                  subtitle: const Text('Anyone can view this list'),
                  value: _isPublic,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),

                const Divider(),

                // Content type options
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    'Content Type',
                    style: TextStyles.headline6,
                  ),
                ),

                CheckboxListTile(
                  title: const Text('Movies'),
                  value: _allowMovies,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                    setState(() {
                      _allowMovies = value ?? false;
                      // Ensure at least one content type is selected
                      if (!_allowMovies && !_allowTvShows) {
                        _allowTvShows = true;
                      }
                    });
                  },
                  activeColor: AppColors.primary,
                ),

                CheckboxListTile(
                  title: const Text('TV Shows'),
                  value: _allowTvShows,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                    setState(() {
                      _allowTvShows = value ?? false;
                      // Ensure at least one content type is selected
                      if (!_allowTvShows && !_allowMovies) {
                        _allowMovies = true;
                      }
                    });
                  },
                  activeColor: AppColors.primary,
                ),

                const SizedBox(height: 32),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createList,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                        : const Text('Create List'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}