import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationService {
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    _showNotification(
      context,
      message,
      AppColors.success,
      Icons.check_circle,
      duration ?? const Duration(seconds: 2),
    );
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    _showNotification(
      context,
      message,
      AppColors.error,
      Icons.error_outline,
      duration ?? const Duration(seconds: 3),
    );
  }

  // Create a new method in the NotificationService
  static void showToast(BuildContext context, String message, {Duration? duration}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration ?? const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  static void _showNotification(
      BuildContext context,
      String message,
      Color color,
      IconData icon,
      Duration duration,
      ) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(
        bottom: 70.0,
        left: 16.0,
        right: 16.0,
      ),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}