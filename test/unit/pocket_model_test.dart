import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_pockets.dart';
import 'package:kasbicara/data/models/pocket_model.dart';

void main() {
  Pocket build({
    String id = 'p1',
    String name = 'Dana Darurat',
    String icon = 'emergency',
    bool isDefault = false,
    int sortOrder = 1,
  }) {
    return Pocket(
      id: id,
      name: name,
      icon: icon,
      isDefault: isDefault,
      sortOrder: sortOrder,
    );
  }

  group('Pocket.toMap / fromMap', () {
    test('round-trip mempertahankan semua field', () {
      final original = build();
      expect(Pocket.fromMap(original.toMap()), original);
    });

    test('is_default disimpan sebagai 1/0', () {
      expect(build(isDefault: true).toMap()['is_default'], 1);
      expect(build(isDefault: false).toMap()['is_default'], 0);
    });
  });

  group('Pocket.validate', () {
    test('lolos untuk nama terisi', () {
      expect(() => build().validate(), returnsNormally);
    });

    test('menolak nama kosong', () {
      expect(() => build(name: '   ').validate(), throwsArgumentError);
    });
  });

  test('isMain true hanya untuk id kMainPocketId', () {
    expect(build(id: kMainPocketId).isMain, isTrue);
    expect(build(id: 'lain').isMain, isFalse);
  });

  group('defaultPockets', () {
    test('berisi tepat satu Pocket Utama dengan id & sortOrder tetap', () {
      expect(defaultPockets, hasLength(1));
      final main = defaultPockets.single;
      expect(main.id, kMainPocketId);
      expect(main.isDefault, isTrue);
      expect(main.sortOrder, 0);
      expect(() => main.validate(), returnsNormally);
    });
  });
}
