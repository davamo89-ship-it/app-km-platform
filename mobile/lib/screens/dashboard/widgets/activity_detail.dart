import 'package:flutter/material.dart';

class ActivityDetail extends StatelessWidget {
  const ActivityDetail({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }
}
