import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;

  const AuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        child: _buildButtonContent(),
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        child: _buildButtonContent(),
      );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.textPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}