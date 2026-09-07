import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/asset_model.dart';
import 'default_assets.dart';
import 'default_categories.dart';

/// Nama file database & kunci penyimpanan passphrase di secure storage.
const _dbFileName = 'kasbicara.db';
const _passphraseKey = 'kasbicara_db_passphrase';

/// v2 (usang): dulu menambah tabel `pockets` + kolom `transactions.pocket_id`.
/// Fitur Pocket dihapus di v5, jadi migrasi v2 kini tak berbuat apa‑apa.
///
/// v3: tabel `assets` + kolom `transactions.asset_id`. Transaksi lama
/// di‑backfill ke Aset Utama.
///
/// v4: kolom `assets.type` (kategori aset) + `assets.is_primary` ("Sumber
/// Aset Utama" yang bisa dipindah pengguna). Aset bawaan di‑set primary.
///
/// v5: fitur Pocket dihapus — `DROP TABLE pockets`, `DROP INDEX`, dan
/// `DROP COLUMN transactions.pocket_id` (fallback: kolom dibiarkan yatim).
const _dbVersion = 5;

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
            asset_id TEXT NOT NULL DEFAULT '$kMainAssetId'
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_category ON transactions(category)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_asset ON transactions(asset_id)',
        );

        await _createAssetsTable(db);

        final batch = db.batch();
        for (final category in defaultCategories) {
          batch.insert(
            'categories',
            category.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        for (final asset in defaultAssets) {
          batch.insert(
            'assets',
            asset.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateToV2(db);
        if (oldVersion < 3) await _migrateToV3(db);
        if (oldVersion < 4) await _migrateToV4(db);
        if (oldVersion < 5) await _migrateToV5(db);
      },
    );
  }

  /// Migrasi v1 → v2 — dulu memasang fitur Pocket. Fitur itu dihapus di v5,
  /// jadi langkah ini sengaja tak berbuat apa‑apa (dipertahankan hanya karena
  /// `onUpgrade` memanggilnya untuk DB yang benar‑benar lama). `_migrateToV5`
  /// membersihkan sisa tabel/kolom pocket bila ada.
  Future<void> _migrateToV2(Database db) async {}

  /// Skema tabel `assets` — dipakai `onCreate` (instalasi baru) &
  /// `_migrateToV3` (upgrade). Idempotent lewat `IF NOT EXISTS`.
  Future<void> _createAssetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'tunai',
        is_default INTEGER NOT NULL DEFAULT 0,
        is_primary INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Migrasi v2 → v3: tabel `assets` + kolom `transactions.asset_id`. Semua
  /// langkah idempotent; sqflite membungkus `onUpgrade` dalam satu transaksi.
  Future<void> _migrateToV3(Database db) async {
    await _createAssetsTable(db);

    for (final asset in defaultAssets) {
      await db.insert(
        'assets',
        asset.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Tambah kolom hanya bila belum ada (aman kalau migrasi terulang).
    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    final hasAssetId = columns.any((c) => c['name'] == 'asset_id');
    if (!hasAssetId) {
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN asset_id TEXT NOT NULL "
        "DEFAULT '$kMainAssetId'",
      );
    }

    // DEFAULT sudah mengisi baris lama; UPDATE eksplisit sebagai jaring
    // pengaman untuk baris yang mungkin lolos.
    await db.update('transactions', {
      'asset_id': kMainAssetId,
    }, where: "asset_id IS NULL OR asset_id = ''");

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_asset '
      'ON transactions(asset_id)',
    );
  }

  /// Migrasi v3 → v4: kolom `assets.type` + `assets.is_primary`. Semua langkah
  /// idempotent; sqflite membungkus `onUpgrade` dalam satu transaksi.
  Future<void> _migrateToV4(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(assets)');
    final hasType = columns.any((c) => c['name'] == 'type');
    if (!hasType) {
      await db.execute(
        "ALTER TABLE assets ADD COLUMN type TEXT NOT NULL DEFAULT 'tunai'",
      );
    }
    final hasIsPrimary = columns.any((c) => c['name'] == 'is_primary');
    if (!hasIsPrimary) {
      await db.execute(
        'ALTER TABLE assets ADD COLUMN is_primary INTEGER NOT NULL DEFAULT 0',
      );
    }

    // Tetapkan Aset Utama bawaan sebagai "Sumber Aset Utama" bila belum ada
    // aset yang ditandai (mis. baris baru ditambahkan lewat migrasi terulang).
    final primaryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM assets WHERE is_primary = 1'),
    );
    if ((primaryCount ?? 0) == 0) {
      await db.update(
        'assets',
        {'is_primary': 1},
        where: 'id = ?',
        whereArgs: [kMainAssetId],
      );
    }
  }

  /// Migrasi v4 → v5: fitur Pocket dihapus. Buang tabel `pockets`, indeks
  /// terkait, dan kolom `transactions.pocket_id`. Semua langkah idempotent &
  /// aman bila artefak pocket memang tak pernah ada (guard `IF EXISTS` /
  /// pengecekan PRAGMA). `DROP COLUMN` butuh SQLite ≥ 3.35 — bila ditolak,
  /// kolom dibiarkan yatim (tak ada kode yang membacanya lagi).
  Future<void> _migrateToV5(Database db) async {
    await db.execute('DROP INDEX IF EXISTS idx_transactions_pocket');
    await db.execute('DROP TABLE IF EXISTS pockets');

    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    if (columns.any((c) => c['name'] == 'pocket_id')) {
      try {
        await db.execute('ALTER TABLE transactions DROP COLUMN pocket_id');
      } catch (_) {
        // SQLite lawas tanpa DROP COLUMN — biarkan kolom yatim.
      }
    }
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
