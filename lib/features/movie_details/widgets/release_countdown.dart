import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class ReleaseCountdown extends StatefulWidget {
  final DateTime releaseDate;

  const ReleaseCountdown({
    super.key,
    required this.releaseDate,
  });

  @override
  _ReleaseCountdownState createState() => _ReleaseCountdownState();
}

class _ReleaseCountdownState extends State<ReleaseCountdown> {
  late Timer _timer;
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final difference = widget.releaseDate.difference(now);

    if (difference.inSeconds <= 0) {
      _timer.cancel();
      setState(() {
        _days = 0;
        _hours = 0;
        _minutes = 0;
        _seconds = 0;
      });
      return;
    }

    setState(() {
      _days = difference.inDays;
      _hours = difference.inHours % 24;
      _minutes = difference.inMinutes % 60;
      _seconds = difference.inSeconds % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Coming in',
            style: TextStyles.headline6,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeItem(_days, 'Days'),
              _buildDivider(),
              _buildTimeItem(_hours, 'Hours'),
              _buildDivider(),
              _buildTimeItem(_minutes, 'Minutes'),
              _buildDivider(),
              _buildTimeItem(_seconds, 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(int value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyles.headline4.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Text(
      ':',
      style: TextStyles.headline2.copyWith(
        color: AppColors.primary,
      ),
    );
  }
}