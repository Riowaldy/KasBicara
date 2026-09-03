import 'package:flutter/material.dart';

/// Pemetaan kunci [Pocket.icon] (string, tersimpan di DB) ke `IconData`.
/// Set kecil khusus pocket (bukan set kategori) — mewakili "kantong /
/// wadah uang". Kunci tak dikenal jatuh ke [Icons.account_balance_wallet].
const Map<String, IconData> _pocketIcons = {
  'wallet': Icons.account_balance_wallet_rounded,
  'savings': Icons.savings_rounded,
  'safe': Icons.lock_rounded,
  'business': Icons.storefront_rounded,
  'family': Icons.family_restroom_rounded,
  'travel': Icons.flight_takeoff_rounded,
  'gift': Icons.card_giftcard_rounded,
  'emergency': Icons.health_and_safety_rounded,
  'education': Icons.school_rounded,
  'home': Icons.home_rounded,
  'bank': Icons.account_balance_rounded,
  'cash': Icons.payments_rounded,
};

/// Urutan pilihan ikon di form pocket.
const List<String> pocketIconKeys = [
  'wallet',
  'cash',
  'savings',
  'safe',
  'bank',
  'business',
  'emergency',
  'family',
  'home',
  'travel',
  'education',
  'gift',
];

IconData iconForPocketKey(String key) =>
    _pocketIcons[key] ?? Icons.account_balance_wallet_rounded;
