import 'package:flutter/material.dart';

/// A brand-safe company monogram tile.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.name,
    required this.tint,
    this.size = 48,
  });

  final String name;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final circleRadius = size * 0.3;
    final bg = tint.withValues(alpha: 0.1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(circleRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: tint,
        ),
      ),
    );
  }
}
