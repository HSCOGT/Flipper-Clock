import 'package:flutter/material.dart';

class TileParams {
  bool isActive;
  Color primaryColor;
  Color secondaryColor;
  String text;
  IconData icon;

  TileParams(
      {this.isActive = false,
      this.primaryColor = const Color.fromRGBO(35, 47, 74, 1),
      this.secondaryColor = const Color.fromRGBO(35, 47, 74, 1),
      this.text = "",
      this.icon});
}
