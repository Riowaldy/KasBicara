import '../models/asset_model.dart';
import '../models/asset_type.dart';

/// Aset bawaan: hanya Aset Utama. ID statis (`kMainAssetId`) agar seeding
/// idempotent — aman dijalankan ulang tanpa duplikasi (dipakai `onCreate` &
/// `onUpgrade`).
///
/// Nama di sini hanya cadangan; UI menampilkan `l10n.assetMainName` selama
/// `isDefault` true — lihat `assetDisplayName`. Dimulai sebagai "Sumber Aset
/// Utama" (`isPrimary`), tetapi pengguna bisa memindah flag itu.
final List<Asset> defaultAssets = [
  const Asset(
    id: kMainAssetId,
    name: 'Aset Utama',
    icon: 'cash',
    type: AssetType.tunai,
    isDefault: true,
    isPrimary: true,
    sortOrder: 0,
  ),
];
