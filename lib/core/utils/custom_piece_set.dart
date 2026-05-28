import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:squares/squares.dart';

class CustomPieceSet {
  static PieceSet fromSvgAssets({
    required String folder,
    required List<String> symbols,
  }) {
    Map<String, WidgetBuilder> pieces = {};
    for (String symbol in symbols) {
      pieces[symbol.toUpperCase()] = (BuildContext context) =>
          SvgPicture.asset('${folder}w$symbol.svg');
      pieces[symbol.toLowerCase()] = (BuildContext context) =>
          SvgPicture.asset('${folder}b$symbol.svg');
    }
    return PieceSet(pieces: pieces);
  }
}