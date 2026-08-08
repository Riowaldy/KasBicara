/// Jenis transaksi — dipakai oleh [Transaction] dan [Category].
enum TransactionType {
  masuk,
  keluar;

  static TransactionType fromValue(String value) =>
      TransactionType.values.byName(value);

  String get value => name;
}
