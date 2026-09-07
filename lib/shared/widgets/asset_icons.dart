import 'package:flutter/material.dart';

/// Pemetaan kunci [Asset.icon] (string, tersimpan di DB) ke `IconData`.
/// Set kecil khusus aset — mewakili "wadah dana / akun / rekening". Kunci
/// tak dikenal jatuh ke [Icons.account_balance_wallet_rounded].
const Map<String, IconData> _assetIcons = {
  'cash': Icons.payments_rounded,
  'bank': Icons.account_balance_rounded,
  'card': Icons.credit_card_rounded,
  'ewallet': Icons.account_balance_wallet_rounded,
  'savings': Icons.savings_rounded,
  'invest': Icons.trending_up_rounded,
  'phone': Icons.phone_iphone_rounded,
  'gold': Icons.diamond_rounded,
  'crypto': Icons.currency_bitcoin_rounded,
  'receivable': Icons.request_quote_rounded,
  'wallet': Icons.wallet_rounded,
  'other': Icons.circle_outlined,
};

/// Urutan pilihan ikon di form aset.
const List<String> assetIconKeys = [
  'cash',
  'bank',
  'card',
  'ewallet',
  'savings',
  'invest',
  'phone',
  'gold',
  'crypto',
  'receivable',
  'wallet',
  'other',
];

IconData iconForAssetKey(String key) =>
    _assetIcons[key] ?? Icons.account_balance_wallet_rounded;
