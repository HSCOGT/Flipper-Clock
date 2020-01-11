// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flipper_clock/custom_icons_icons.dart';
import 'package:flipper_clock/tile.dart';
import 'package:flipper_clock/tile_params.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  List<TileParams> _tiles = new List.generate(187, (_) => TileParams());

  //Cache
  String cachedTemperature;
  String cachedHigh;
  String cachedLow;

  //Data
  String get high => widget.model.highString;
  String get low => widget.model.lowString;
  String get temperature => widget.model.temperatureString;
  String get unit => widget.model.unitString;
  String get weather => widget.model.weatherString;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
    _tiles[120].icon = CustomIcons.up_dir;
    _tiles[137].icon = CustomIcons.down_dir;
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
      _displayTemperature();
      _displayWeather();
      _displayHighLow(high, 121, true);
      _displayHighLow(low, 138, false);

      // For the clock to update inmediatly if 24 Hour format is enabled/disabled
      _updateTime();
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();

      // Update once per minute.
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );

      final time = DateFormat(widget.model.is24HourFormat ? 'HHmm' : 'hhmm')
          .format(_dateTime);
      _refreshNumbers(time);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        color: Colors.black,
        child: GridView.count(
          crossAxisCount: 17,
          children: List<Widget>.generate(187, (i) {
            return Tile(
              tileParams: _tiles[i],
            );
          }),
        ),
      ),
      //Added for a Vignette Effect
      Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.black.withOpacity(0.0),
              Colors.black.withOpacity(0.4),
            ],
            focal: Alignment.center,
            radius: 0.9,
          ),
        ),
      ),
    ]);
  }

  void _refreshNumbers(time) {
    for (var i = 0; i < 4; i++) {
      var tempAreaIndexes = _getAreaIndexes(i + 1);
      var tempNumberIndexes =
          _getIndexesForNumber(int.parse(time[i]), _getAreaIndexes(i + 1));
      for (var index in tempAreaIndexes) {
        tempNumberIndexes.contains(index)
            ? _tiles[index].isActive = true
            : _tiles[index].isActive = false;
      }
      _setColors(tempAreaIndexes);
    }
  }

  //Display Temperature in Tiles
  void _displayTemperature() {
    //Clean of tiles, because the new temperature could be lower in length, thus not override the old text in tiles, leaving old data displayed.
    if (cachedTemperature != null) {
      for (int i = 0; i < cachedTemperature.length; i++) {
        _tiles[133 - i].text = "";
      }
    }
    cachedTemperature = temperature;
    _tiles[134].text = unit;
    //Rounding of temperature
    var _temperature = double.parse(temperature.replaceAll(unit, ''))
        .round()
        .toString()
        .split('')
        .reversed
        .join();
    for (int i = 0; i < _temperature.length; i++) {
      _tiles[133 - i].text = _temperature[i];
    }
  }

  //Sets the icon according to weather (All icons are under SIL Licence, see custom_icons_icons.dart for more details.)
  void _displayWeather() {
    switch (weather) {
      case 'cloudy':
        _tiles[151].icon = CustomIcons.cloud_sun_inv;
        break;
      case 'foggy':
        _tiles[151].icon = CustomIcons.fog_cloud;
        break;
      case 'rainy':
        _tiles[151].icon = CustomIcons.rain_inv;
        break;
      case 'snowy':
        _tiles[151].icon = CustomIcons.snow_heavy_inv;
        break;
      case 'sunny':
        _tiles[151].icon = CustomIcons.sun_inv;
        break;
      case 'thunderstorm':
        _tiles[151].icon = CustomIcons.cloud_flash_inv;
        break;
      case 'windy':
        _tiles[151].icon = CustomIcons.wind;
        break;
      default:
    }
  }

  //Display High or Low Temperatures in Tiles
  //temperatureToDisplay - High or Low
  //index                - Starting index
  //isHigh               - Is it high?
  void _displayHighLow(temperatureToDisplay, index, isHigh) {
    //Clean of tiles, because the new temperature could be lower in length, thus not override the old text in tiles, leaving old data displayed.
    if (isHigh) {
      if (cachedHigh != null) {
        for (int i = 0; i < cachedHigh.length; i++) {
          _tiles[index + i].text = "";
        }
      }
      cachedHigh = temperatureToDisplay;
    } else {
      if (cachedLow != null) {
        for (int i = 0; i < cachedLow.length; i++) {
          _tiles[index + i].text = "";
        }
      }
      cachedLow = temperatureToDisplay;
    }
    //Rounding of temperature
    var _temperature = double.parse(temperatureToDisplay.replaceAll(unit, ''))
        .round()
        .toString();
    for (int i = 0; i < _temperature.length; i++) {
      _tiles[index + i].text = _temperature[i];
    }
    _tiles[index + _temperature.length].text = unit;
  }

  //Gets a 3x5 matrix of indexes representing the tiles in which a number will be displayed
  //digitInHour
  //1 - First Digit, Left To Rigth, Hours
  //2 - Second Digit, Left To Rigth, Hours
  //3 - First Digit, Left To Rigth, Minutes
  //4 - Second Digit, Left To Rigth, Minutes
  List<int> _getAreaIndexes(int digitInHour) {
    List<int> baseIndexes = [
      18,
      19,
      20,
      35,
      36,
      37,
      52,
      53,
      54,
      69,
      70,
      71,
      86,
      87,
      88
    ];
    switch (digitInHour) {
      case 1:
        return baseIndexes;
        break;
      case 2:
        return baseIndexes.map((index) => index + 4).toList();
        break;
      case 3:
        return baseIndexes.map((index) => index + 8).toList();
        break;
      case 4:
        return baseIndexes.map((index) => index + 12).toList();
        break;
      default:
        return null;
    }
  }

  void _setColors(List<int> areaIndexes) {
    setState(() {
      for (var i = 0; i < 15; i++) {
        if (_tiles[areaIndexes[i]].isActive) {
          if (i < 3) {
            _tiles[areaIndexes[i]].primaryColor =
                Color.fromRGBO(254, 248, 216, 1);
            _tiles[areaIndexes[i]].secondaryColor =
                Color.fromRGBO(253, 238, 190, 1);
          } else if (i < 6) {
            _tiles[areaIndexes[i]].primaryColor =
                Color.fromRGBO(249, 222, 183, 1);
            _tiles[areaIndexes[i]].secondaryColor =
                Color.fromRGBO(236, 175, 162, 1);
          } else if (i < 9) {
            _tiles[areaIndexes[i]].primaryColor =
                Color.fromRGBO(231, 157, 155, 1);
            _tiles[areaIndexes[i]].secondaryColor =
                Color.fromRGBO(222, 115, 140, 1);
          } else if (i < 12) {
            _tiles[areaIndexes[i]].primaryColor =
                Color.fromRGBO(213, 96, 133, 1);
            _tiles[areaIndexes[i]].secondaryColor =
                Color.fromRGBO(167, 72, 129, 1);
          } else {
            _tiles[areaIndexes[i]].primaryColor =
                Color.fromRGBO(148, 65, 128, 1);
            _tiles[areaIndexes[i]].secondaryColor =
                Color.fromRGBO(95, 43, 124, 1);
          }
        }
      }
    });
  }

  //Removes the unnecessary positions, in a 3x5 matrix, to display the desired digit
  //digit: Desired digit.
  //areaIndexes: Indexes of area for the digit.
  List<int> _getIndexesForNumber(int digit, List<int> areaIndexes) {
    switch (digit) {
      case 0:
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(7);
        areaIndexes.removeAt(4);
        break;
      case 1:
        areaIndexes.removeAt(13);
        areaIndexes.removeAt(12);
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(9);
        areaIndexes.removeAt(7);
        areaIndexes.removeAt(6);
        areaIndexes.removeAt(4);
        areaIndexes.removeAt(3);
        areaIndexes.removeAt(1);
        areaIndexes.removeAt(0);
        break;
      case 2:
        areaIndexes.removeAt(11);
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(4);
        areaIndexes.removeAt(3);
        break;
      case 3:
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(9);
        areaIndexes.removeAt(4);
        areaIndexes.removeAt(3);
        break;
      case 4:
        areaIndexes.removeAt(13);
        areaIndexes.removeAt(12);
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(9);
        areaIndexes.removeAt(4);
        areaIndexes.removeAt(1);
        break;
      case 5:
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(9);
        areaIndexes.removeAt(5);
        areaIndexes.removeAt(4);
        break;
      case 6:
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(5);
        areaIndexes.removeAt(4);
        break;
      case 7:
        areaIndexes.removeAt(13);
        areaIndexes.removeAt(12);
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(9);
        areaIndexes.removeAt(7);
        areaIndexes.removeAt(6);
        areaIndexes.removeAt(4);
        areaIndexes.removeAt(3);
        break;
      case 8:
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(4);
        break;
      case 9:
        areaIndexes.removeAt(13);
        areaIndexes.removeAt(12);
        areaIndexes.removeAt(10);
        areaIndexes.removeAt(9);
        areaIndexes.removeAt(4);
        break;
      default:
    }
    return areaIndexes;
  }
}
