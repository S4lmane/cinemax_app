class CastModel {
  final String id;
  final String name;
  final String character;
  final String profilePath;

  CastModel({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory CastModel.fromMap(Map<String, dynamic> map) {
    return CastModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      character: map['character'] ?? '',
      profilePath: map['profile_path'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'character': character,
      'profile_path': profilePath,
    };
  }

  String getProfileUrl() {
    if (profilePath.isEmpty) {
      return 'https://via.placeholder.com/185x278?text=No+Profile';
    }
    return 'https://image.tmdb.org/t/p/w185$profilePath';
  }
}