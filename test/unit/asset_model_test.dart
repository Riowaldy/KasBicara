import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_assets.dart';
import 'package:kasbicara/data/models/asset_model.dart';
import 'package:kasbicara/data/models/asset_type.dart';

void main() {
  Asset build({
    String id = 'a1',
    String name = 'Bank BCA',
    String icon = 'bank',
    AssetType type = AssetType.bank,
    bool isDefault = false,
    bool isPrimary = false,
    int sortOrder = 1,
  }) {
    return Asset(
      id: id,
      name: name,
      icon: icon,
      type: type,
      isDefault: isDefault,
      isPrimary: isPrimary,
      sortOrder: sortOrder,
    );
  }

  group('Asset.toMap / fromMap', () {
    test('round-trip mempertahankan semua field', () {
      final original = build(type: AssetType.eWallet, isPrimary: true);
      expect(Asset.fromMap(original.toMap()), original);
    });

    test('is_default & is_primary disimpan sebagai 1/0', () {
      expect(build(isDefault: true).toMap()['is_default'], 1);
      expect(build(isDefault: false).toMap()['is_default'], 0);
      expect(build(isPrimary: true).toMap()['is_primary'], 1);
      expect(build(isPrimary: false).toMap()['is_primary'], 0);
    });

    test('type disimpan sebagai nama enum & dibaca kembali', () {
      expect(build(type: AssetType.bankDigital).toMap()['type'], 'bankDigital');
      expect(
        Asset.fromMap(build(type: AssetType.investasi).toMap()).type,
        AssetType.investasi,
      );
    });

    test('baris pra-v4 tanpa kolom type/is_primary jatuh ke default', () {
      final map = build().toMap()
        ..remove('type')
        ..remove('is_primary');
      final asset = Asset.fromMap(map);
      expect(asset.type, AssetType.tunai);
      expect(asset.isPrimary, isFalse);
    });
  });

  group('Asset.validate', () {
    test('lolos untuk nama terisi', () {
      expect(() => build().validate(), returnsNormally);
    });

    test('menolak nama kosong', () {
      expect(() => build(name: '   ').validate(), throwsArgumentError);
    });
  });

  test('isMain true hanya untuk id kMainAssetId', () {
    expect(build(id: kMainAssetId).isMain, isTrue);
    expect(build(id: 'lain').isMain, isFalse);
  });

  group('defaultAssets', () {
    test('berisi tepat satu Aset Utama: id tetap, tunai, primary', () {
      expect(defaultAssets, hasLength(1));
      final main = defaultAssets.single;
      expect(main.id, kMainAssetId);
      expect(main.isDefault, isTrue);
      expect(main.isPrimary, isTrue);
      expect(main.type, AssetType.tunai);
      expect(main.sortOrder, 0);
      expect(() => main.validate(), returnsNormally);
    });
  });
}
