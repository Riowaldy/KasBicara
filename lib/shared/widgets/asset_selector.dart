import '../../data/models/asset_model.dart';
import '../../l10n/app_localizations.dart';

/// Nama aset untuk ditampilkan: Aset Utama memakai nama terlokalisasi,
/// sisanya memakai nama yang disimpan pengguna (mirror `pocketDisplayName`).
String assetDisplayName(Asset asset, AppLocalizations l10n) =>
    asset.isDefault ? l10n.assetMainName : asset.name;
