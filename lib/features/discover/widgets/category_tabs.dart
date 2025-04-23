import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class CategoryTabs extends StatelessWidget {
  final List<String> tabs;
  final TabController controller;

  const CategoryTabs({
    Key? key,
    required this.tabs,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary,
        ),
        labelColor: Colors.black,
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