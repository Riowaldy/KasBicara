import '../models/asset_model.dart';

/// Aset bawaan: hanya Aset Utama. ID statis (`kMainAssetId`) agar seeding
/// idempotent — aman dijalankan ulang tanpa duplikasi (dipakai `onCreate` &
/// `onUpgrade`).
///
/// Nama di sini hanya cadangan; UI menampilkan `l10n.assetMainName` selama
/// `isDefault` true — lihat `assetDisplayName`.
final List<Asset> defaultAssets = [
  const Asset(
    id: kMainAssetId,
    name: 'Aset Utama',
    icon: 'cash',
    isDefault: true,
    sortOrder: 0,
  ),
];
