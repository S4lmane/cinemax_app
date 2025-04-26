import 'package:cloud_firestore/cloud_firestore.dart';

class ListModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String coverImageUrl;
  final bool isPublic;
  final bool allowMovies;
  final bool allowTvShows;
  final List<String> itemIds; // IDs of movies/shows in the list
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemCount;

  ListModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.coverImageUrl = '',
    this.isPublic = false,
    this.allowMovies = true,
    this.allowTvShows = true,
    this.itemIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.itemCount = 0,
  });

  factory ListModel.fromMap(Map<String, dynamic> map, String id) {
    return ListModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      coverImageUrl: map['coverImageUrl'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? false,
      allowMovies: map['allowMovies'] as bool? ?? true,
      allowTvShows: map['allowTvShows'] as bool? ?? true,
      itemIds: List<String>.from(map['itemIds'] as List? ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      itemCount: map['itemCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'isPublic': isPublic,
      'allowMovies': allowMovies,
      'allowTvShows': allowTvShows,
      'itemIds': itemIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'itemCount': itemCount,
    };
  }

  ListModel copyWith({
    String? name,
    String? description,
    String? coverImageUrl,
    bool? isPublic,
    bool? allowMovies,
    bool? allowTvShows,
    List<String>? itemIds,
    DateTime? updatedAt,
    int? itemCount,
  }) {
    return ListModel(
      id: this.id,
      userId: this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublic: isPublic ?? this.isPublic,
      allowMovies: allowMovies ?? this.allowMovies,
      allowTvShows: allowTvShows ?? this.allowTvShows,
      itemIds: itemIds ?? this.itemIds,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}