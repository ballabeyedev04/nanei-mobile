extension DateTimeFormatting on DateTime {
  String toJjMmAa() {
    final j = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    final a = year.toString().substring(2);
    return '$j/$m/$a';
  }

  String toJjMmAaHhMm() {
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '${toJjMmAa()} $h:$min';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  String toRelative() {
    if (isToday) return 'Aujourd\'hui';
    if (isYesterday) return 'Hier';
    return toJjMmAa();
  }
}

extension NullableDateTimeFormatting on DateTime? {
  String toJjMmAaOrDash() => this == null ? '—' : this!.toJjMmAa();
}
