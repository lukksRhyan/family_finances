import 'package:flutter/material.dart';
class InputCard extends StatelessWidget {
  final Widget child;
  const InputCard(
   {super.key, required this.child,});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}