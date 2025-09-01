
import 'package:flutter/material.dart';
class RowOption extends StatelessWidget {
  final String title;
  final IconData iconData;
  final VoidCallback onTap;

  const RowOption({
    required this.title,
    required this.iconData,
    required this.onTap,
  }); 
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
      IconButton.filled(
        color: Colors.white,
        iconSize: 40,
        highlightColor: Colors.grey[300],
        onPressed: onTap, 
        icon: Icon(iconData),
        ),
        Text(title),
        ]
      );
  }
}