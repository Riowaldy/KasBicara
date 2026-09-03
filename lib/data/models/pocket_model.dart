import 'package:flutter/foundation.dart';

/// ID tetap Pocket Utama — deterministik (bukan UUID acak) agar seeding &
/// migrasi idempotent, dan agar transaksi lama bisa di‑backfill ke sini.
const kMainPocketId = 'pocket_main';

/// Wadah bernama untuk sekumpulan uang (konsep "Pocket KasBicara" §02).
///
/// Saldo TIDAK disimpan di sini — selalu dihitung ulang dari transaksi yang
/// menunjuk ke pocket ini (lihat `pocketBalanceProvider`), konsisten dengan
/// pola `balanceProvider`.
@immutable
class Pocket {
  const Pocket({
    required this.id,
    required this.name,
    required this.icon,
    required this.isDefault,
    required this.sortOrder,
  });

  final String id;

  /// Untuk Pocket Utama, [name] hanya nilai cadangan — UI menampilkan nama
  /// terlokalisasi (`l10n.pocketMainName`) bila [isDefault] true. Lihat
  /// `pocketDisplayName`.
  final String name;

  /// Kunci string ikon, dipetakan ke `IconData` di layer UI
  /// (`shared/widgets/pocket_icons.dart`) — pola sama seperti kategori.
  final String icon;

  /// `true` hanya untuk Pocket Utama (`id == kMainPocketId`). Dipakai untuk
  /// mengunci aksi hapus & rename.
  final bool isDefault;

  /// Urutan tampil di selector & layar kelola. Pocket Utama selalu `0`.
  final int sortOrder;

  bool get isMain => id == kMainPocketId;

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama pocket wajib diisi');
    }
  }

  Pocket copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
    int? sortOrder,
  }) {
    return Pocket(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_default': isDefault ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Pocket.fromMap(Map<String, Object?> map) {
    return Pocket(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      isDefault: (map['is_default'] as int) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pocket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          isDefault == other.isDefault &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(id, name, icon, isDefault, sortOrder);

  @override
  String toString() =>
      'Pocket(id: $id, name: $name, isDefault: $isDefault, '
      'sortOrder: $sortOrder)';
}
