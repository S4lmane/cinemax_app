class CrewModel {
  final String id;
  final String name;
  final String job;
  final String profilePath;

  CrewModel({
    required this.id,
    required this.name,
    required this.job,
    required this.profilePath,
  });

  factory CrewModel.fromMap(Map<String, dynamic> map) {
    return CrewModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      job: map['job'] ?? '',
      profilePath: map['profile_path'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'job': job,
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