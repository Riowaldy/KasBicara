/// Kategori aset — dipakai oleh [Asset]. Nilai disimpan apa adanya (nama enum)
/// di kolom `assets.type`. Pola sama seperti [TransactionType].
enum AssetType {
  tunai,
  bank,
  eWallet,
  bankDigital,
  kartuKredit,
  investasi,
  lainnya;

  /// Baca dari nilai DB; nilai tak dikenal / null ditangani pemanggil
  /// (`Asset.fromMap` jatuh ke [AssetType.tunai]).
  static AssetType fromValue(String value) => AssetType.values.byName(value);

  String get value => name;

  /// Kunci ikon default yang disarankan saat tipe dipilih di form — pengguna
  /// tetap bisa menimpanya lewat pemilih ikon. Kunci mengacu ke
  /// `shared/widgets/asset_icons.dart`.
  String get defaultIconKey => switch (this) {
    AssetType.tunai => 'cash',
    AssetType.bank => 'bank',
    AssetType.eWallet => 'ewallet',
    AssetType.bankDigital => 'phone',
    AssetType.kartuKredit => 'card',
    AssetType.investasi => 'invest',
    AssetType.lainnya => 'other',
  };
}
