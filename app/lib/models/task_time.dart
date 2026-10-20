const taskPeriods = ['上午', '中午', '下午', '晚上'];

String dateValue(DateTime date) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${pad(date.month)}-${pad(date.day)}';
}

String minuteValue(DateTime date) {
  final local = date.toLocal();
  String pad(int n) => n.toString().padLeft(2, '0');
  final offset = local.timeZoneOffset;
  final minutes = offset.inMinutes.abs();
  return '${dateValue(local)}T${pad(local.hour)}:${pad(local.minute)}'
      '${offset.isNegative ? '-' : '+'}${pad(minutes ~/ 60)}:${pad(minutes % 60)}';
}

String validateStart(String value) {
  final input = value.trim().replaceFirst(' ', 'T');
  if (!RegExp(
    r'^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:\d{2})?)?$',
  ).hasMatch(input)) {
    throw const FormatException('Invalid task time');
  }
  final date = input.substring(0, 10);
  if (dateValue(DateTime.parse(date)) != date) {
    throw const FormatException('Invalid calendar date');
  }
  if (input.contains('T')) {
    if (int.parse(input.substring(11, 13)) > 23 ||
        int.parse(input.substring(14, 16)) > 59) {
      throw const FormatException('Invalid clock time');
    }
    return minuteValue(DateTime.parse(input));
  }
  return date;
}

DateTime? taskDate(String? value) {
  if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  final local = value.contains('T') ? parsed.toLocal() : parsed;
  return DateTime(local.year, local.month, local.day);
}

String startLabel(String value, [String? period]) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) return value;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = value.contains('T') ? parsed.toLocal() : parsed;
  String pad(int n) => n.toString().padLeft(2, '0');
  final date = '${local.year}年${pad(local.month)}月${pad(local.day)}日';
  if (value.contains('T')) {
    return '$date ${pad(local.hour)}:${pad(local.minute)}';
  }
  return period == null ? date : '$date $period';
}

String deadlineLabel(DateTime value, {bool? dateOnly, String? period}) {
  final local = value.toLocal();
  final onlyDate = dateOnly ?? (local.hour == 0 && local.minute == 0);
  return startLabel(onlyDate ? dateValue(local) : minuteValue(local), period);
}

String timeInput(String? value) {
  if (value == null) return '';
  if (!value.contains('T')) return value;
  final parsed = DateTime.tryParse(value)?.toLocal();
  return parsed == null
      ? value
      : minuteValue(parsed).substring(0, 16).replaceFirst('T', ' ');
}
