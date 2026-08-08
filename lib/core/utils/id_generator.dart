import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Buat ID unik (UUID v4) untuk entitas baru (transaksi/kategori kustom).
String generateId() => _uuid.v4();
