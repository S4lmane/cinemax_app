import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistItem {
  final String id;
  final String itemId; // Movie or TV show ID
  final bool isMovie; // true if movie, false if TV show
  final DateTime addedAt;

  WatchlistItem({
    required this.id,
    required this.itemId,
    required this.isMovie,
    required this.addedAt,
  });

  factory WatchlistItem.fromMap(Map<String, dynamic> map, String id) {
    return WatchlistItem(
      id: id,
      itemId: map['itemId'] ?? '',
      isMovie: map['isMovie'] ?? true,
      addedAt: map['addedAt'] != null
          ? (map['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'isMovie': isMovie,
      'addedAt': addedAt,
    };
  }
}

class Watchlist {
  final String userId;
  final List<WatchlistItem> items;

  Watchlist({
    required this.userId,
    this.items = const [],
  });

  factory Watchlist.fromMap(Map<String, dynamic> map, String userId, List<QueryDocumentSnapshot> itemDocs) {
    List<WatchlistItem> items = itemDocs.map((doc) {
      return WatchlistItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Sort by most recently added
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    return Watchlist(
      userId: userId,
      items: items,
    );
  }

  bool contains(String itemId) {
    return items.any((item) => item.itemId == itemId);
  }

  WatchlistItem? getItem(String itemId) {
    try {
      return items.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }
}