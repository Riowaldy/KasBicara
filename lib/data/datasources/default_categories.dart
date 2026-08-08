import '../models/category_model.dart';
import '../models/transaction_type.dart';

/// Kategori default (PRD §6.4). ID dibuat statis/deterministik (bukan UUID
/// acak) agar seeding idempotent — aman dijalankan ulang tanpa duplikasi.
final List<Category> defaultCategories = [
  // Pengeluaran
  const Category(
    id: 'expense-makanan-minuman',
    name: 'Makanan & Minuman',
    type: TransactionType.keluar,
    icon: 'food',
    isDefault: true,
  ),
  const Category(
    id: 'expense-transportasi',
    name: 'Transportasi',
    type: TransactionType.keluar,
    icon: 'transport',
    isDefault: true,
  ),
  const Category(
    id: 'expense-belanja',
    name: 'Belanja',
    type: TransactionType.keluar,
    icon: 'shopping',
    isDefault: true,
  ),
  const Category(
    id: 'expense-tagihan-utilitas',
    name: 'Tagihan & Utilitas',
    type: TransactionType.keluar,
    icon: 'bills',
    isDefault: true,
  ),
  const Category(
    id: 'expense-kesehatan',
    name: 'Kesehatan',
    type: TransactionType.keluar,
    icon: 'health',
    isDefault: true,
  ),
  const Category(
    id: 'expense-hiburan',
    name: 'Hiburan',
    type: TransactionType.keluar,
    icon: 'entertainment',
    isDefault: true,
  ),
  const Category(
    id: 'expense-pendidikan',
    name: 'Pendidikan',
    type: TransactionType.keluar,
    icon: 'education',
    isDefault: true,
  ),
  const Category(
    id: 'expense-lainnya',
    name: 'Lainnya',
    type: TransactionType.keluar,
    icon: 'other',
    isDefault: true,
  ),

  // Pemasukan
  const Category(
    id: 'income-gaji',
    name: 'Gaji',
    type: TransactionType.masuk,
    icon: 'salary',
    isDefault: true,
  ),
  const Category(
    id: 'income-bonus',
    name: 'Bonus',
    type: TransactionType.masuk,
    icon: 'bonus',
    isDefault: true,
  ),
  const Category(
    id: 'income-investasi',
    name: 'Investasi',
    type: TransactionType.masuk,
    icon: 'investment',
    isDefault: true,
  ),
  const Category(
    id: 'income-transfer-masuk',
    name: 'Transfer Masuk',
    type: TransactionType.masuk,
    icon: 'transfer_in',
    isDefault: true,
  ),
  const Category(
    id: 'income-lainnya',
    name: 'Lainnya',
    type: TransactionType.masuk,
    icon: 'other',
    isDefault: true,
  ),
];
