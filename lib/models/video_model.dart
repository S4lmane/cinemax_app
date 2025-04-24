class VideoModel {
  final String id;
  final String name;
  final String key;
  final String site;
  final String type;
  final bool official;

  VideoModel({
    required this.id,
    required this.name,
    required this.key,
    required this.site,
    required this.type,
    required this.official,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      key: map['key'] ?? '',
      site: map['site'] ?? '',
      type: map['type'] ?? '',
      official: map['official'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'key': key,
      'site': site,
      'type': type,
      'official': official,
    };
  }

  String getVideoUrl() {
    if (site.toLowerCase() == 'youtube') {
      return 'https://www.youtube.com/watch?v=$key';
    } else if (site.toLowerCase() == 'vimeo') {
      return 'https://vimeo.com/$key';
    }
    return '';
  }

  String getThumbnailUrl() {
    if (site.toLowerCase() == 'youtube') {
      return 'https://img.youtube.com/vi/$key/hqdefault.jpg';
    }
    return '';
  }
}