import 'package:flutter/material.dart';

Widget quickAppPlaceholder(BuildContext context, double scaleWidth, double scaleHeight,){
  return Container(
    width: MediaQuery.of(context).size.width * scaleWidth,
    height: MediaQuery.of(context).size.height * scaleHeight,
  );
}