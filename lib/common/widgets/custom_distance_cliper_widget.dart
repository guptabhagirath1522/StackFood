import 'package:flutter/material.dart';
class CurvedTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.9, 5);
    path.quadraticBezierTo(size.width * 0.85, -5, size.width * 0.7, 0);
    path.lineTo(size.width * 0.2, 0);
    path.quadraticBezierTo(size.width * 0.1, 0, size.width * 0.1, 3);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}