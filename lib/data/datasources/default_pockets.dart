import '../models/pocket_model.dart';

/// Pocket bawaan (konsep "Pocket KasBicara" §02): hanya Pocket Utama.
/// ID statis (`kMainPocketId`) agar seeding idempotent — aman dijalankan
/// ulang tanpa duplikasi (dipakai `onCreate` & `onUpgrade`).
///
/// Nama di sini hanya cadangan; UI menampilkan `l10n.pocketMainName`
/// selama `isDefault` true — lihat `pocketDisplayName`.
final List<Pocket> defaultPockets = [
  const Pocket(
    id: kMainPocketId,
    name: 'Pocket Utama',
    icon: 'wallet',
    isDefault: true,
    sortOrder: 0,
  ),
];
