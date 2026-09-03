import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/pocket_model.dart';
import 'default_categories.dart';
import 'default_pockets.dart';

/// Nama file database & kunci penyimpanan passphrase di secure storage.
const _dbFileName = 'kasbicara.db';
const _passphraseKey = 'kasbicara_db_passphrase';

/// v2 (konsep "Pocket KasBicara" §04): tabel `pockets` + kolom
/// `transactions.pocket_id`. Transaksi lama di‑backfill ke Pocket Utama.
const _dbVersion = 2;

/// Membuka & mengelola koneksi database SQLite terenkripsi (SQLCipher).
///
/// Passphrase dibangkitkan sekali secara acak & disimpan di
/// [FlutterSecureStorage] (Android Keystore / iOS Keychain) — tidak pernah
/// ditulis dalam bentuk teks biasa ke disk maupun kode sumber.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  // Opsi dibuat EKSPLISIT (bukan cuma andalkan default paket) agar postur
  // keamanan terdokumentasi & tidak diam-diam berubah kalau versi paket
  // naik. Android: AndroidOptions() default sudah AES-GCM + RSA-OAEP lewat
  // Keystore (Fase 6 hardening — dicek: sudah kuat sejak v11, tak perlu
  // encryptedSharedPreferences manual seperti versi lama). iOS: accessible
  // hanya saat perangkat ter-unlock (KeychainAccessibility.unlocked) — pas
  // untuk app foreground-only tanpa proses background.
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(),
  );

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final passphrase = await _getOrCreatePassphrase();
    final path = join(await getDatabasesPath(), _dbFileName);

    return openDatabase(
      path,
      password: passphrase,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            icon TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            pocket_id TEXT NOT NULL DEFAULT '$kMainPocketId'
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_category ON transactions(category)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_pocket ON transactions(pocket_id)',
        );

        await _createPocketsTable(db);

        final batch = db.batch();
        for (final category in defaultCategories) {
          batch.insert(
            'categories',
            category.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        for (final pocket in defaultPockets) {
          batch.insert(
            'pockets',
            pocket.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateToV2(db);
      },
    );
  }

  /// Skema tabel `pockets` — dipakai `onCreate` (instalasi baru) &
  /// `_migrateToV2` (upgrade). Idempotent lewat `IF NOT EXISTS`.
  Future<void> _createPocketsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pockets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Migrasi v1 → v2 (konsep "Pocket KasBicara" §04). Semua langkah
  /// idempotent; sqflite membungkus `onUpgrade` dalam satu transaksi.
  Future<void> _migrateToV2(Database db) async {
    await _createPocketsTable(db);

    for (final pocket in defaultPockets) {
      await db.insert(
        'pockets',
        pocket.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Tambah kolom hanya bila belum ada (aman kalau migrasi terulang).
    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    final hasPocketId = columns.any((c) => c['name'] == 'pocket_id');
    if (!hasPocketId) {
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN pocket_id TEXT NOT NULL "
        "DEFAULT '$kMainPocketId'",
      );
    }

    // DEFAULT sudah mengisi baris lama; UPDATE eksplisit sebagai jaring
    // pengaman untuk baris yang mungkin lolos (mis. NULL dari migrasi lama).
    await db.update('transactions', {
      'pocket_id': kMainPocketId,
    }, where: "pocket_id IS NULL OR pocket_id = ''");

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_pocket '
      'ON transactions(pocket_id)',
    );
  }

  Future<String> _getOrCreatePassphrase() async {
    final existing = await _secureStorage.read(key: _passphraseKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await _secureStorage.write(key: _passphraseKey, value: generated);
    return generated;
  }

  /// Hanya untuk pengujian/reset — tutup & hapus referensi koneksi aktif.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
