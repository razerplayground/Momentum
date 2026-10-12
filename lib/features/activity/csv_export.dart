import 'dart:convert';
import 'dart:typed_data';

String? extractCsvExport(dynamic response) {
  if (response is String) {
    return response.trim().isEmpty ? null : response;
  }
  if (response is Uint8List || response is List<int>) {
    final csv = utf8.decode(response as List<int>);
    return csv.trim().isEmpty ? null : csv;
  }
  if (response is List) {
    final records = response
        .whereType<Map>()
        .map((record) => Map<String, dynamic>.from(record))
        .toList();
    return _recordsToCsv(records);
  }
  if (response is Map) {
    var hasEnvelope = false;
    for (final key in const [
      'csv',
      'content',
      'data',
      'result',
      'records',
      'rows',
      'items',
      'finances',
      'payroll',
      'employees',
    ]) {
      if (response.containsKey(key)) {
        hasEnvelope = true;
        final csv = extractCsvExport(response[key]);
        if (csv != null) return csv;
      }
    }
    if (hasEnvelope) return null;
    return _recordsToCsv([Map<String, dynamic>.from(response)]);
  }
  return null;
}

String? _recordsToCsv(List<Map<String, dynamic>> records) {
  if (records.isEmpty) return null;

  final columns = <String>[];
  for (final record in records) {
    for (final key in record.keys) {
      if (!columns.contains(key)) columns.add(key);
    }
  }
  if (columns.isEmpty) return null;

  final rows = <List<String>>[
    columns,
    for (final record in records)
      [
        for (final column in columns) _csvValue(record[column]),
      ],
  ];
  return rows.map((row) => row.map(_escapeCsvValue).join(',')).join('\r\n');
}

String _csvValue(dynamic value) {
  if (value == null) return '';
  if (value is Map || value is List) return jsonEncode(value);
  return value.toString();
}

String _escapeCsvValue(String value) => '"${value.replaceAll('"', '""')}"';
