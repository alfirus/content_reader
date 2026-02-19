import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final int color;

  const Category({
    this.id,
    required this.name,
    this.color = 0xFF2196F3, // Default blue
  });

  Category copyWith({
    int? id,
    String? name,
    int? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int? ?? 0xFF2196F3,
    );
  }

  @override
  List<Object?> get props => [id, name, color];
}
