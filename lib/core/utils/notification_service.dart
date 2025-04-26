import 'package:flutter/material.dart';

class NotificationService {
  static final List<_NotificationData> _notificationQueue = [];
  static bool _isShowing = false;
  static OverlayEntry? _currentOverlayEntry;
  static _AnimatedNotificationState? _currentNotificationState;

  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    _enqueueNotification(
      context,
      message,
      const Color(0xFF4CAF50), // Green
      const Color(0xFF81C784), // Lighter green for border
      Icons.check_circle,
      duration ?? const Duration(seconds: 2),
    );
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    _enqueueNotification(
      context,
      message,
      const Color(0xFFF44336), // Red
      const Color(0xFFE57373), // Lighter red for border
      Icons.error_outline,
      duration ?? const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    _enqueueNotification(
      context,
      message,
      const Color(0xFFFFC107), // Yellow
      const Color(0xFFFFE082), // Lighter yellow for border
      Icons.info_outline,
      duration ?? const Duration(seconds: 2),
    );
  }

  static void showTip(BuildContext context, String message, {Duration? duration}) {
    _enqueueNotification(
      context,
      message,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFBA68C8), // Lighter purple for border
      Icons.lightbulb_outline,
      duration ?? const Duration(seconds: 2),
    );
  }

  static void showToast(BuildContext context, String message, {Duration? duration}) {
    _enqueueNotification(
      context,
      message,
      const Color(0xFF333333), // Dark gray
      const Color(0xFF616161), // Lighter gray for border
      Icons.share,
      duration ?? const Duration(seconds: 2),
    );
  }

  static void _enqueueNotification(
      BuildContext context,
      String message,
      Color color,
      Color borderColor,
      IconData icon,
      Duration duration,
      ) {
    _notificationQueue.add(_NotificationData(
      context: context,
      message: message,
      color: color,
      borderColor: borderColor,
      icon: icon,
      duration: duration,
    ));

    if (_isShowing) {
      _dismissCurrent(isReplacing: true);
    }
    _processQueue();
  }

  static void _processQueue() {
    if (_isShowing || _notificationQueue.isEmpty) return;

    final data = _notificationQueue.removeAt(0);
    // Check if context is still valid
    if (!data.context.mounted) {
      _processQueue(); // Skip invalid context and process next
      return;
    }

    _isShowing = true;
    final overlay = Overlay.of(data.context);

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => _AnimatedNotification(
        message: data.message,
        color: data.color,
        borderColor: data.borderColor,
        icon: data.icon,
        duration: data.duration,
        onDismiss: () {
          _currentOverlayEntry?.remove();
          _currentOverlayEntry = null;
          _currentNotificationState = null;
          _isShowing = false;
          _processQueue();
        },
      ),
    );

    overlay.insert(_currentOverlayEntry!);
  }

  static void _dismissCurrent({bool isReplacing = false}) {
    if (_currentNotificationState != null && _isShowing) {
      _currentNotificationState!.dismiss(isReplacing: isReplacing);
    }
  }
}

class _NotificationData {
  final BuildContext context;
  final String message;
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Duration duration;

  _NotificationData({
    required this.context,
    required this.message,
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.duration,
  });
}

class _AnimatedNotification extends StatefulWidget {
  final String message;
  final Color color; // Background color
  final Color borderColor; // Border color
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AnimatedNotification({
    required this.message,
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  _AnimatedNotificationState createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  double _opacity = 1.0;
  bool _isDismissing = false;
  double _dismissOffset = 0.0;

  @override
  void initState() {
    super.initState();
    NotificationService._currentNotificationState = this;
    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissing) {
        dismiss();
      }
    });
  }

  @override
  void dispose() {
    if (NotificationService._currentNotificationState == this) {
      NotificationService._currentNotificationState = null;
    }
    super.dispose();
  }

  void dismiss({bool isReplacing = false}) {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
      _opacity = 0.0;
      if (isReplacing) {
        _dismissOffset = 100.0; // Move up when replaced
      }
    });
    Future.delayed(Duration(milliseconds: isReplacing ? 200 : 300), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _isDragging = true;
      _dragOffset -= details.delta.dy; // Up drag increases offset, down drag decreases
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    if (_dragOffset.abs() > 100) {
      dismiss();
    } else {
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      bottom: 90 + (_isDismissing ? _dismissOffset : _dragOffset),
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(milliseconds: _isDismissing && _dismissOffset != 0 ? 200 : 300),
        child: GestureDetector(
          onTap: () => dismiss(),
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.9),
                    widget.color.withOpacity(0.8),
                  ],
                ),
                border: Border.all(color: widget.borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}