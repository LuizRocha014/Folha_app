import 'package:intl/intl.dart';

/// Helpers de formatação BR — moeda, data, hora.
class FolhaFormatters {
  FolhaFormatters._();

  static final NumberFormat _brl = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  /// Formata como R$ 1.234,56 com sinal opcional.
  /// Negativos usam o sinal Unicode `−` (U+2212) para alinhamento editorial.
  static String brl(num value, {bool sign = false}) {
    final abs = _brl.format(value.abs()).trim();
    if (value < 0) return '−R\$ $abs';
    if (sign && value > 0) return '+R\$ $abs';
    return 'R\$ $abs';
  }

  /// "12:30"
  static String time(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// Hoje / Ontem / Amanhã / X dias atrás / dd MMM
  static String relativeDay(DateTime d) {
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final d0 = DateTime(d.year, d.month, d.day);
    final diff = t0.difference(d0).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff == -1) return 'Amanhã';
    if (diff < 0) return 'em ${-diff} dias';
    if (diff < 7) return '$diff dias atrás';
    return DateFormat('dd MMM', 'pt_BR').format(d);
  }

  /// "segunda-feira, 12 de outubro de 2025"
  static String fullDate(DateTime d) {
    return DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(d);
  }

  /// "Outubro"
  static String monthName(DateTime d) {
    return toBeginningOfSentenceCase(
          DateFormat('MMMM', 'pt_BR').format(d),
        ) ??
        '';
  }
}
