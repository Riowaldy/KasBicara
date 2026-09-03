import 'package:flutter/foundation.dart';

import '../../core/utils/date_utils.dart' as date_utils;
import 'pocket_model.dart';
import 'transaction_type.dart';

/// Entitas transaksi sesuai skema PRD §9.
///
/// `date` disimpan tanpa komponen jam (hanya tanggal kalender) karena
/// direpresentasikan sebagai string `YYYY-MM-DD` di database.
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.pocketId = kMainPocketId,
  });

  final String id;
  final TransactionType type;

  /// Jumlah dalam Rupiah, tanpa desimal. Harus > 0 — lihat [validate].
  final int amount;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Pocket tempat transaksi ini dicatat (konsep "Pocket KasBicara" §02).
  /// Wajib & tunggal — default [kMainPocketId] agar transaksi tanpa pilihan
  /// eksplisit (mis. data pra‑migrasi, tes lama) tetap konsisten.
  final String pocketId;

  /// Validasi minimal sebelum disimpan (mitigasi risiko PRD §13: jumlah
  /// tidak boleh 0/negatif). Lempar [ArgumentError] jika tidak valid.
  void validate() {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Jumlah harus lebih dari 0');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError.value(category, 'category', 'Kategori wajib diisi');
    }
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    int? amount,
    String? category,
    Object? note = _sentinel,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pocketId,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: identical(note, _sentinel) ? this.note : note as String?,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pocketId: pocketId ?? this.pocketId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.value,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date_utils.toDateString(date),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'pocket_id': pocketId,
    };
  }

  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as String,
      type: TransactionType.fromValue(map['type'] as String),
      amount: map['amount'] as int,
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      pocketId: (map['pocket_id'] as String?) ?? kMainPocketId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          amount == other.amount &&
          category == other.category &&
          note == other.note &&
          date == other.date &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          pocketId == other.pocketId;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    category,
    note,
    date,
    createdAt,
    updatedAt,
    pocketId,
  );

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, amount: $amount, '
      'category: $category, pocket: $pocketId, '
      'date: ${date_utils.toDateString(date)})';
}

const _sentinel = Object();
