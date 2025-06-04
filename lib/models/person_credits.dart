class PersonCredits {
  final List<CreditItem>? cast;
  final List<CreditItem>? crew;

  PersonCredits({
    this.cast,
    this.crew,
  });

  factory PersonCredits.fromJson(Map<String, dynamic> json) {
    return PersonCredits(
      cast: json['cast'] != null
          ? (json['cast'] as List).map((x) => CreditItem.fromJson(x)).toList()
          : null,
      crew: json['crew'] != null
          ? (json['crew'] as List).map((x) => CreditItem.fromJson(x)).toList()
          : null,
    );
  }
}

class CreditItem {
  final int id;
  final String? title;  // For movies
  final String? name;   // For TV shows
  final String? posterPath;
  final String? releaseDate;  // For movies
  final String? firstAirDate; // For TV shows
  final String? character;    // For cast
  final String? job;          // For crew
  final String? department;   // For crew
  final String? mediaType;    // movie or tv
  final double? popularity;
  final bool adult;

  CreditItem({
    required this.id,
    this.title,
    this.name,
    this.posterPath,
    this.releaseDate,
    this.firstAirDate,
    this.character,
    this.job,
    this.department,
    this.mediaType,
    this.popularity,
    this.adult = false,
  });

  factory CreditItem.fromJson(Map<String, dynamic> json) {
    return CreditItem(
      id: json['id'],
      title: json['title'],
      name: json['name'],
      posterPath: json['poster_path'],
      releaseDate: json['release_date'],
      firstAirDate: json['first_air_date'],
      character: json['character'],
      job: json['job'],
      department: json['department'],
      mediaType: json['media_type'],
      popularity: json['popularity']?.toDouble(),
      adult: json['adult'] ?? false,
    );
  }
}