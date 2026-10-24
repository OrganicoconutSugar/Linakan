import 'dart:io';

/// Ekspor data ke file CSV sementara menggunakan dart:io.
///
/// [header] adalah daftar nama kolom. [rows] adalah daftar baris, tiap baris
/// berisi daftar nilai string sesuai urutan kolom. Mengembalikan path file
/// yang ditulis.
///
/// Catatan: memakai Directory.systemTemp (dart:io) sesuai spec demo. Pada
/// beberapa perangkat Android akses ke systemTemp dapat terbatas; penulisan
/// dibungkus try/catch oleh pemanggil.
Future<String> exportCsvToTempFile({
  required String fileName,
  required List<String> header,
  required List<List<String>> rows,
}) async {
  final buffer = StringBuffer();
  buffer.writeln(header.map(_escape).join(','));
  for (final row in rows) {
    buffer.writeln(row.map(_escape).join(','));
  }
  final dir = await Directory.systemTemp.createTemp('linakan_');
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(buffer.toString());
  return file.path;
}

/// Escape nilai sesuai aturan CSV (RFC 4180).
String _escape(String value) {
  final v = value;
  if (v.contains(',') ||
      v.contains('"') ||
      v.contains('\n') ||
      v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}
