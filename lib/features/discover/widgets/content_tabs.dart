import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class ContentTabs extends StatelessWidget {
  final List<String> tabs;
  final TabController controller;

  const ContentTabs({
    super.key,
    required this.tabs,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        // a transparent background with a bottom border instead of coloring the whole tab
        indicator: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary,
              width: 3,
            ),
          ),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyles.headline6.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyles.headline6.copyWith(
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: tabs.map((tab) =>
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(tab),
              ),
            )
        ).toList(),
      ),
    );
  }
}