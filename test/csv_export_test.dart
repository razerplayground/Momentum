import 'dart:convert';
import 'dart:typed_data';

import 'package:bussiness_management/features/activity/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses CSV returned directly by the export endpoint', () {
    expect(
      extractCsvExport('id,name\r\n1,Example\r\n'),
      'id,name\r\n1,Example\r\n',
    );
  });

  test('converts exported record rows into escaped CSV', () {
    final csv = extractCsvExport({
      'data': {
        'records': [
          {'id': 'entry-1', 'name': 'Smith, Jane', 'note': 'Said "hello"'},
          {'id': 'entry-2', 'name': 'Alex', 'note': null},
        ],
      },
    });

    expect(
      csv,
      '"id","name","note"\r\n'
      '"entry-1","Smith, Jane","Said ""hello"""\r\n'
      '"entry-2","Alex",""',
    );
  });

  test('decodes CSV response bytes', () {
    expect(
      extractCsvExport(Uint8List.fromList(utf8.encode('id\n1'))),
      'id\n1',
    );
  });

  test('returns null when export response has no usable records', () {
    expect(extractCsvExport({'data': []}), isNull);
    expect(extractCsvExport('  '), isNull);
  });
}
