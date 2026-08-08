import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'default_categories.dart';

/// Nama file database & kunci penyimpanan passphrase di secure storage.
const _dbFileName = 'kasbicara.db';
const _passphraseKey = 'kasbicara_db_passphrase';
const _dbVersion = 1;

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
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_category ON transactions(category)',
        );

        final batch = db.batch();
        for (final category in defaultCategories) {
          batch.insert(
            'categories',
            category.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      },
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
