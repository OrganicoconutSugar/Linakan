import 'package:intl/intl.dart';

/// Memformat tanggal menjadi format lokal Indonesia.
/// Contoh: '15 Jan 2024'
String formatDate(DateTime date) {
  final formatter = DateFormat('d MMM yyyy', 'id_ID');
  return formatter.format(date);
}

/// Memformat tanggal dan waktu.
/// Contoh: '15 Jan 2024, 14:30'
String formatDateTime(DateTime date) {
  final formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  return formatter.format(date);
}

/// Memformat sisa waktu menjadi teks yang mudah dibaca.
/// Contoh: 'Tersisa 3 jam' atau 'Tersisa 2 hari'
String formatTimeRemaining(Duration duration) {
  if (duration.isNegative || duration.inSeconds <= 0) {
    return 'Sudah Kadaluarsa';
  }
  final int hours = duration.inHours;
  if (hours < 24) {
    return 'Tersisa $hours jam';
  }
  final int days = duration.inDays;
  return 'Tersisa $days hari';
}
