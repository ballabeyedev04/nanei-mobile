import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int note;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.note,
    this.size = 24,
    this.color = const Color(0xFFFFB800),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < note ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: color,
        );
      }),
    );
  }
}
