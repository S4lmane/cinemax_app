import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/person_details.dart';

class AwardChip extends StatelessWidget {
  final Award award;

  const AwardChip({Key? key, required this.award}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: award.won
            ? AppColors.primary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: award.won ? AppColors.primary : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (award.won)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(
                Icons.emoji_events,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          Flexible(
            child: Text(
              '${award.name}${award.year != null ? ' (${award.year})' : ''}${award.category != null ? '\n${award.category}' : ''}',
              style: TextStyle(
                color: award.won ? AppColors.primary : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}