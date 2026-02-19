import 'package:equatable/equatable.dart';

class Feed extends Equatable {
  final int? id;
  final int? categoryId;
  final String url;
  final String title;
  final String description;
  final String favicon;
  final DateTime? lastFetched;

  const Feed({
    this.id,
    this.categoryId,
    required this.url,
    required this.title,
    this.description = '',
    this.favicon = '',
    this.lastFetched,
  });

  Feed copyWith({
    int? id,
    int? categoryId,
    String? url,
    String? title,
    String? description,
    String? favicon,
    DateTime? lastFetched,
  }) {
    return Feed(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      favicon: favicon ?? this.favicon,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'url': url,
      'title': title,
      'description': description,
      'favicon': favicon,
      'lastFetched': lastFetched?.millisecondsSinceEpoch,
    };
  }

  factory Feed.fromMap(Map<String, dynamic> map) {
    return Feed(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int?,
      url: map['url'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      favicon: map['favicon'] as String? ?? '',
      lastFetched: map['lastFetched'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastFetched'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, url, title, description, favicon, lastFetched];
}
