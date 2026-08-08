import 'package:flutter/foundation.dart';

import 'transaction_type.dart';

/// Entitas kategori transaksi sesuai skema PRD §9.
///
/// [icon] adalah kunci string (mis. `"food"`, `"salary"`) yang dipetakan ke
/// `IconData` konkret di layer UI — lihat `lib/shared/widgets` (Fase 2).
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.isDefault,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String icon;
  final bool isDefault;

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama kategori wajib diisi');
    }
  }

  Category copyWith({
    String? id,
    String? name,
    TransactionType? type,
    String? icon,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'icon': icon,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TransactionType.fromValue(map['type'] as String),
      icon: map['icon'] as String,
      isDefault: (map['is_default'] as int) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          icon == other.icon &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(id, name, type, icon, isDefault);

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
