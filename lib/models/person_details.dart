class PersonDetails {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final double? popularity;
  final String? placeOfBirth;
  final String? profilePath;
  final String? knownForDepartment;
  final List<Award> awards;

  PersonDetails({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.popularity,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment,
    this.awards = const [],
  });

  factory PersonDetails.fromJson(Map<String, dynamic> json) {
    // Process awards (need to be added from an external source or api)
    List<Award> awardsList = [];
    if (json['awards'] != null) {
      awardsList = (json['awards'] as List)
          .map((award) => Award.fromJson(award))
          .toList();
    }

    return PersonDetails(
      id: json['id'],
      name: json['name'],
      biography: json['biography'],
      birthday: json['birthday'],
      deathday: json['deathday'],
      popularity: json['popularity']?.toDouble(),
      placeOfBirth: json['place_of_birth'],
      profilePath: json['profile_path'],
      knownForDepartment: json['known_for_department'],
      awards: awardsList,
    );
  }
}

class Award {
  final String name;
  final String? year;
  final String? category;
  final bool won;

  Award({
    required this.name,
    this.year,
    this.category,
    this.won = true,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      name: json['name'],
      year: json['year'],
      category: json['category'],
      won: json['won'] ?? true,
    );
  }
}