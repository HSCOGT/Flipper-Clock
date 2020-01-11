import 'package:auto_size_text/auto_size_text.dart';
import 'package:flipper_clock/tile_params.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class Tile extends StatefulWidget {
  final TileParams tileParams;

  Tile({this.tileParams});

  @override
  _TileState createState() => _TileState();
}

class _TileState extends State<Tile> with SingleTickerProviderStateMixin {
  double _ratio = 0.0;
  AnimationController _controller;

  //Data
  bool get isActive => widget.tileParams.isActive;
  String get textToDisplay => widget.tileParams.text;
  Color get primaryColor => widget.tileParams.primaryColor;
  Color get secondaryColor => widget.tileParams.secondaryColor;
  IconData get icon => widget.tileParams.icon;

  Color _primaryColor;
  Color _secondaryColor;
  double _glow = 0;

  @override
  void initState() {
    super.initState();
    _primaryColor = primaryColor;
    _secondaryColor = secondaryColor;
    _controller = AnimationController(vsync: this);
    _controller.duration = Duration(milliseconds: 1000);
    _controller.addListener(_tick);
    isActive ? _controller.reverse() : _controller.forward();
  }

  @override
  void didUpdateWidget(Tile oldWidget) {
    isActive ? _controller.reverse() : _controller.forward();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double ratio = max(0.0, min(1.0, _ratio));

    Matrix4 mtx = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..setEntry(1, 2, 0.2)
      ..rotateX(pi * (ratio - 1.0));

    return Transform(
        alignment: Alignment.center,
        transform: mtx,
        child: Padding(
          padding: const EdgeInsets.all(0.7),
          child: Stack(children: [
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_primaryColor, _secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _secondaryColor,
                      blurRadius: isActive ? _glow : 0,
                      spreadRadius: isActive ? _glow : 0,
                    )
                  ]),
            ),
            Center(
              child: AutoSizeText(
                textToDisplay,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ]),
        ));
  }

  void _tick() {
    setState(() {
      _ratio = Curves.easeInQuad.transform(_controller.value);
      //Updates color at the middle of the flip transition.
      if (isActive) {
        if (_ratio < 0.5) {
          _primaryColor = primaryColor;
          _secondaryColor = secondaryColor;
          _glow = _ratio * 30;
        }
      } else {
        if (_ratio > 0.5) {
          _primaryColor = Color.fromRGBO(35, 47, 74, 1);
          _secondaryColor = Color.fromRGBO(35, 47, 74, 1);
        }
      }
    });
  }
}
