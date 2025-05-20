import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool showClearButton;
  final VoidCallback onClear;
  final VoidCallback? onSubmitted;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.showClearButton,
    required this.onClear,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyles.bodyText1,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) {
          if (onSubmitted != null) {
            onSubmitted!();
          }
          FocusScope.of(context).unfocus();
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyles.bodyText1.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: showClearButton
              ? IconButton(
            icon: const Icon(
              Icons.clear,
              color: AppColors.textSecondary,
            ),
            onPressed: onClear,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}