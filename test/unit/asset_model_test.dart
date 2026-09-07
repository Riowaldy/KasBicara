import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_assets.dart';
import 'package:kasbicara/data/models/asset_model.dart';

void main() {
  Asset build({
    String id = 'a1',
    String name = 'Bank BCA',
    String icon = 'bank',
    bool isDefault = false,
    int sortOrder = 1,
  }) {
    return Asset(
      id: id,
      name: name,
      icon: icon,
      isDefault: isDefault,
      sortOrder: sortOrder,
    );
  }

  group('Asset.toMap / fromMap', () {
    test('round-trip mempertahankan semua field', () {
      final original = build();
      expect(Asset.fromMap(original.toMap()), original);
    });

    test('is_default disimpan sebagai 1/0', () {
      expect(build(isDefault: true).toMap()['is_default'], 1);
      expect(build(isDefault: false).toMap()['is_default'], 0);
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
    test('berisi tepat satu Aset Utama dengan id & sortOrder tetap', () {
      expect(defaultAssets, hasLength(1));
      final main = defaultAssets.single;
      expect(main.id, kMainAssetId);
      expect(main.isDefault, isTrue);
      expect(main.sortOrder, 0);
      expect(() => main.validate(), returnsNormally);
    });
  });
}
