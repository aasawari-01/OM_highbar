import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SizeConfig {
  static double _screenWidth = 0;
  static double _screenHeight = 0;
  static double _blockWidth = 0;
  static double _blockHeight = 0;

  static double textMultiplier = 0;
  static double imageSizeMultiplier = 0;
  static double heightMultiplier = 0;
  static double widthMultiplier = 0;
  static bool isPortrait = true;
  static bool isMobilePortrait = false;

  void init(BoxConstraints constraints, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      print("Orientation == 1");
      _screenWidth = constraints.maxWidth;
      _screenHeight = constraints.maxHeight;
      isPortrait = true;
      if (_screenWidth < 750) {
        isMobilePortrait = true;
      }
    } else {
      print("Orientation == 2");
      _screenWidth = constraints.maxHeight;
      _screenHeight = constraints.maxWidth;
      isPortrait = false;
      isMobilePortrait = false;
    }
    _screenWidth = constraints.maxWidth;
    _screenHeight = constraints.maxHeight;

    _blockWidth = _screenWidth / 100;
    _blockHeight = _screenHeight / 100;

    textMultiplier = _blockHeight;
    imageSizeMultiplier = _blockWidth;
    heightMultiplier = _blockHeight;
    widthMultiplier = _blockWidth;

    print("Orientation >>> == ${orientation}");
    print("imageSizeMultiplier == $_screenWidth");
    print("_screenWidth == $_screenWidth");
    print("_screenHeight == $_screenHeight");
    print("_blockWidth == $_blockWidth");
    print("_blockHeight == $_blockHeight");
    print("isPortrait == $isPortrait");
    print("isMobilePortrait == $isMobilePortrait");
  }
}


/*
imageSizeMultiplier == 392.72727272727275
I/flutter (16612): _screenWidth == 392.72727272727275
I/flutter (16612): _screenHeight == 803.6363636363636
I/flutter (16612): _blockWidth == 3.9272727272727277
I/flutter (16612): _blockHeight == 8.036363636363637*/
