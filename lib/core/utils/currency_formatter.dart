import 'package:intl/intl.dart';

/// Memformat angka menjadi format Rupiah Indonesia.
/// Contoh: 60000 → 'Rp 60.000'
String formatRupiah(int amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
