import 'package:flutter/material.dart';

class CardShell extends StatelessWidget {
  const CardShell({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
