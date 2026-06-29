extension DoubleFormatting on double {
  String toXof() => '${toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')} FCFA';

  String toPourcent({int decimals = 1}) => '${toStringAsFixed(decimals)} %';

  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
}

extension NullableDoubleFormatting on double? {
  String toXofOrDash() => this == null ? '—' : this!.toXof();
}
