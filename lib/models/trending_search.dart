class TrendingSearch {
  final int id;
  final String query;
  final String category;

  TrendingSearch({
    required this.id,
    required this.query,
    required this.category,
  });

  factory TrendingSearch.fromJson(Map<String, dynamic> json) {
    return TrendingSearch(
      id: json['id'],
      query: json['query'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'category': category,
    };
  }
}