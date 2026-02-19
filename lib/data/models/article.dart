import 'package:equatable/equatable.dart';

class Article extends Equatable {
  final int? id;
  final int feedId;
  final String title;
  final String link;
  final String content;
  final String summary;
  final String author;
  final DateTime published;
  final bool isRead;
  final bool isSaved;
  final bool isDownloaded;
  final String? imageUrl;

  const Article({
    this.id,
    required this.feedId,
    required this.title,
    required this.link,
    this.content = '',
    this.summary = '',
    this.author = '',
    required this.published,
    this.isRead = false,
    this.isSaved = false,
    this.isDownloaded = false,
    this.imageUrl,
  });

  Article copyWith({
    int? id,
    int? feedId,
    String? title,
    String? link,
    String? content,
    String? summary,
    String? author,
    DateTime? published,
    bool? isRead,
    bool? isSaved,
    bool? isDownloaded,
    String? imageUrl,
  }) {
    return Article(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      title: title ?? this.title,
      link: link ?? this.link,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      author: author ?? this.author,
      published: published ?? this.published,
      isRead: isRead ?? this.isRead,
      isSaved: isSaved ?? this.isSaved,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedId': feedId,
      'title': title,
      'link': link,
      'content': content,
      'summary': summary,
      'author': author,
      'published': published.millisecondsSinceEpoch,
      'isRead': isRead ? 1 : 0,
      'isSaved': isSaved ? 1 : 0,
      'isDownloaded': isDownloaded ? 1 : 0,
      'imageUrl': imageUrl,
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as int?,
      feedId: map['feedId'] as int,
      title: map['title'] as String,
      link: map['link'] as String,
      content: map['content'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      author: map['author'] as String? ?? '',
      published: DateTime.fromMillisecondsSinceEpoch(map['published'] as int),
      isRead: (map['isRead'] as int?) == 1,
      isSaved: (map['isSaved'] as int?) == 1,
      isDownloaded: (map['isDownloaded'] as int?) == 1,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        feedId,
        title,
        link,
        content,
        summary,
        author,
        published,
        isRead,
        isSaved,
        isDownloaded,
        imageUrl,
      ];
}
