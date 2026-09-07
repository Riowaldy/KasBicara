import 'package:flutter/foundation.dart';

import 'asset_type.dart';

/// ID tetap Aset Utama — deterministik (bukan UUID acak) agar seeding &
/// migrasi idempotent, dan agar transaksi lama bisa di‑backfill ke sini.
const kMainAssetId = 'asset_main';

/// Sumber dana / akun tempat uang benar‑benar berada (mis. Tunai, rekening
/// bank, e‑wallet). Dimensi pengelompokan utama transaksi: setiap transaksi
/// terikat tepat satu aset.
///
/// Saldo TIDAK disimpan di sini — selalu dihitung ulang dari transaksi yang
/// menunjuk ke aset ini (lihat `assetBalanceProvider`).
@immutable
class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.icon,
    required this.isDefault,
    required this.sortOrder,
    this.type = AssetType.tunai,
    this.isPrimary = false,
  });

  final String id;

  /// Untuk Aset Utama, [name] hanya nilai cadangan — UI menampilkan nama
  /// terlokalisasi (`l10n.assetMainName`) bila [isDefault] true. Lihat
  /// `assetDisplayName`.
  final String name;

  /// Kunci string ikon, dipetakan ke `IconData` di layer UI
  /// (`shared/widgets/asset_icons.dart`).
  final String icon;

  /// Kategori aset (Tunai, Bank, E‑Wallet, dst.). Dipilih pengguna di form.
  final AssetType type;

  /// `true` hanya untuk Aset Utama bawaan (`id == kMainAssetId`). Dipakai
  /// untuk mengunci aksi hapus & rename. TERPISAH dari [isPrimary].
  final bool isDefault;

  /// "Sumber Aset Utama" — dipilih pengguna, bisa dipindah ke aset mana pun.
  /// Tepat satu aset ber‑[isPrimary] `true` setiap saat (dijaga
  /// `AssetRepository.setPrimary`). Menyetir nilai awal field aset di form
  /// transaksi & target reassign saat aset lain dihapus.
  final bool isPrimary;

  /// Urutan tampil di selector & layar kelola. Aset Utama selalu `0`.
  final int sortOrder;

  bool get isMain => id == kMainAssetId;

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama aset wajib diisi');
    }
  }

  Asset copyWith({
    String? id,
    String? name,
    String? icon,
    AssetType? type,
    bool? isDefault,
    bool? isPrimary,
    int? sortOrder,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type.value,
      'is_default': isDefault ? 1 : 0,
      'is_primary': isPrimary ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Asset.fromMap(Map<String, Object?> map) {
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      // Toleran terhadap baris pra‑v4 tanpa kolom `type` / `is_primary`.
      type: AssetType.fromValue(
        (map['type'] as String?) ?? AssetType.tunai.value,
      ),
      isDefault: (map['is_default'] as int) == 1,
      isPrimary: (map['is_primary'] as int?) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          type == other.type &&
          isDefault == other.isDefault &&
          isPrimary == other.isPrimary &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      Object.hash(id, name, icon, type, isDefault, isPrimary, sortOrder);

  @override
  String toString() =>
      'Asset(id: $id, name: $name, type: ${type.value}, '
      'isDefault: $isDefault, isPrimary: $isPrimary, sortOrder: $sortOrder)';
}
