import '../../data/models/asset_model.dart';
import '../../data/models/asset_type.dart';
import '../../l10n/app_localizations.dart';

/// Nama aset untuk ditampilkan: Aset Utama memakai nama terlokalisasi,
/// sisanya memakai nama yang disimpan pengguna (mirror `pocketDisplayName`).
String assetDisplayName(Asset asset, AppLocalizations l10n) =>
    asset.isDefault ? l10n.assetMainName : asset.name;

/// Label terlokalisasi untuk kategori aset (dipakai form & layar kelola).
String assetTypeLabel(AssetType type, AppLocalizations l10n) => switch (type) {
  AssetType.tunai => l10n.assetTypeTunai,
  AssetType.bank => l10n.assetTypeBank,
  AssetType.eWallet => l10n.assetTypeEwallet,
  AssetType.bankDigital => l10n.assetTypeBankDigital,
  AssetType.kartuKredit => l10n.assetTypeKartuKredit,
  AssetType.investasi => l10n.assetTypeInvestasi,
  AssetType.lainnya => l10n.assetTypeLainnya,
};
