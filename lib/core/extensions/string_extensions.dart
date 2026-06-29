extension StringFormatting on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get initiales {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(this);

  String masquerTel() {
    if (length < 4) return this;
    return '${substring(0, length - 4).replaceAll(RegExp(r'\d'), '*')}${substring(length - 4)}';
  }

  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}

extension NullableStringFormatting on String? {
  String get orDash => (this == null || this!.isEmpty) ? '—' : this!;
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
