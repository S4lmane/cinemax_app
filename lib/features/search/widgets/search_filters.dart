// lib/features/search/widgets/search_filters.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/constants/app_constants.dart';

class SearchFilters extends StatefulWidget {
  final String contentType;
  final String selectedGenre;
  final RangeValues yearRange;
  final double minRating;
  final Function({
  String? contentType,
  String? genre,
  RangeValues? yearRange,
  double? minRating,
  }) onFilterChanged;

  const SearchFilters({
    super.key,
    required this.contentType,
    required this.selectedGenre,
    required this.yearRange,
    required this.minRating,
    required this.onFilterChanged,
  });

  @override
  _SearchFiltersState createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late String _contentType;
  late String _selectedGenre;
  late RangeValues _yearRange;
  late double _minRating;

  @override
  void initState() {
    super.initState();
    _contentType = widget.contentType;
    _selectedGenre = widget.selectedGenre;
    _yearRange = widget.yearRange;
    _minRating = widget.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content type filter
          const Text(
            'Content Type',
            style: TextStyles.headline6,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildContentTypeButton('all', 'All'),
              const SizedBox(width: 8),
              _buildContentTypeButton('movies', 'Movies'),
              const SizedBox(width: 8),
              _buildContentTypeButton('tv', 'TV Shows'),
            ],
          ),
          const SizedBox(height: 16),

          // Genre filter
          const Text(
            'Genre',
            style: TextStyles.headline6,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildGenreButton('all', 'All Genres'),
                ...AppConstants.genres.values.map((genre) => _buildGenreButton(genre, genre)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Year range filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Year Range',
                style: TextStyles.headline6,
              ),
              Text(
                '${_yearRange.start.toInt()} - ${_yearRange.end.toInt()}',
                style: TextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _yearRange,
            min: 1900,
            max: DateTime.now().year.toDouble(),
            divisions: DateTime.now().year - 1900,
            labels: RangeLabels(
              "${_yearRange.start.toInt()}",
              "${_yearRange.end.toInt()}",
            ),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
            onChanged: (values) {
              setState(() {
                _yearRange = values;
              });
            },
            onChangeEnd: (values) {
              widget.onFilterChanged(yearRange: values);
            },
          ),
          const SizedBox(height: 16),

          // Minimum rating filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minimum Rating',
                style: TextStyles.headline6,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_minRating.toInt()}+',
                    style: TextStyles.bodyText2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 10,
            divisions: 10,
            label: "${_minRating.toInt()}+",
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
            onChangeEnd: (value) {
              widget.onFilterChanged(minRating: value);
            },
          ),

          // Reset and Apply buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _contentType = 'all';
                    _selectedGenre = 'all';
                    _yearRange = RangeValues(1900, DateTime.now().year.toDouble());
                    _minRating = 0;
                  });

                  widget.onFilterChanged(
                    contentType: 'all',
                    genre: 'all',
                    yearRange: RangeValues(1900, DateTime.now().year.toDouble()),
                    minRating: 0,
                  );
                },
                child: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onFilterChanged(
                    contentType: _contentType,
                    genre: _selectedGenre,
                    yearRange: _yearRange,
                    minRating: _minRating,
                  );
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeButton(String value, String label) {
    final isSelected = _contentType == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _contentType = value;
        });
        widget.onFilterChanged(contentType: value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
        foregroundColor: isSelected ? Colors.black : AppColors.textSecondary,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppColors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildGenreButton(String value, String label) {
    final isSelected = _selectedGenre == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedGenre = value;
          });
          widget.onFilterChanged(genre: value);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
          foregroundColor: isSelected ? Colors.black : AppColors.textSecondary,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : AppColors.textSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}