import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final double size;
  final String text;
  final Color color;
  final FontWeight weight;
  final TextAlign alignment;
  final double letterSpacing;
  final bool isItalic;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText({
    super.key,
    required this.text,
    this.size = 24.0,
    this.color = Colors.black,
    this.weight = FontWeight.w500,
    this.alignment = TextAlign.left,
    this.letterSpacing = 0.0,
    this.isItalic = false,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      ),
      textAlign: alignment,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
