import 'package:intl/intl.dart';

// Formato colombiano: punto como separador de miles, sin decimales (ej. \$650.000).
final _thousands = NumberFormat('#,##0', 'es');
final _date = DateFormat('dd/MM/yyyy HH:mm');

String formatCop(num value) => '\$${_thousands.format(value)}';

String formatLocalDate(DateTime utc) => _date.format(utc.toLocal());
