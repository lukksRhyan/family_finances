import 'package:flutter/material.dart';

class SectionStyle extends BoxDecoration{
  SectionStyle() : super(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}