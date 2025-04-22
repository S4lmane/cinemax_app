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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: controller,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 3.0,
          ),
          insets: EdgeInsets.only(
            right: MediaQuery.of(context).size.width / tabs.length - 30,
            left: 10,
          ),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyles.headline6,
        unselectedLabelStyle: TextStyles.headline6.copyWith(
          fontWeight: FontWeight.w400,
        ),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}