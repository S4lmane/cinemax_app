import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_image.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;

  File? _selectedProfileImage;
  File? _selectedBannerImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the current nickname
    final userProfile = Provider.of<ProfileProvider>(context, listen: false).userProfile;
    _nicknameController = TextEditingController(text: userProfile?.nickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
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

  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedBannerImage = File(pickedFile.path);
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

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      bool success = true;

      // Update nickname
      if (_nicknameController.text != profileProvider.userProfile?.nickname) {
        success = await profileProvider.updateUserProfile(
          nickname: _nicknameController.text.trim(),
        );
      }

      // Upload profile image if selected
      if (success && _selectedProfileImage != null) {
        success = await profileProvider.uploadProfileImage(_selectedProfileImage!);
      }

      // Upload banner image if selected
      if (success && _selectedBannerImage != null) {
        success = await profileProvider.uploadBannerImage(_selectedBannerImage!);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate changes were made
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileProvider.error ?? 'Failed to update profile'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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
    final profileProvider = Provider.of<ProfileProvider>(context);
    final userProfile = profileProvider.userProfile;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('User profile not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner image
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                    ),
                    child: _selectedBannerImage != null
                        ? Image.file(
                      _selectedBannerImage!,
                      fit: BoxFit.cover,
                    )
                        : userProfile.bannerImageUrl.isNotEmpty
                        ? CustomImage(
                      imageUrl: userProfile.bannerImageUrl,
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
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: CircleAvatar(
                      backgroundColor: AppColors.cardBackground,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                        ),
                        onPressed: _pickBannerImage,
                      ),
                    ),
                  ),
                ],
              ),

              // Profile image
              Container(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, -40, 0),
                child: Stack(
                  children: [
                    Container(
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
                        child: _selectedProfileImage != null
                            ? Image.file(
                          _selectedProfileImage!,
                          fit: BoxFit.cover,
                        )
                            : userProfile.profileImageUrl.isNotEmpty
                            ? CustomImage(
                          imageUrl: userProfile.profileImageUrl,
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
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.cardBackground,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: _pickProfileImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email (non-editable)
                    const Text(
                      'Email',
                      style: TextStyles.headline6,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: double.infinity,
                      child: Text(
                        userProfile.email,
                        style: TextStyles.bodyText1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Username (non-editable)
                    const Text(
                      'Username',
                      style: TextStyles.headline6,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: double.infinity,
                      child: Text(
                        '@${userProfile.username}',
                        style: TextStyles.bodyText1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nickname (editable)
                    const Text(
                      'Display Name',
                      style: TextStyles.headline6,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your display name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}