
import 'package:flutter/material.dart';
import 'package:mos/consts/colors.dart';

Widget spacerVerticalSmall(BuildContext context){
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.04,
  );
}
Widget spacerVerticalBig(BuildContext context){
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.4,
  );
}

Widget textNormal(String data){
  return Text(
    data,
    style: const TextStyle(
      fontSize: 20,
      color: kcTextColor,
      decoration: TextDecoration.none
    ),
  );
}

Widget textNormalCrossed(String data){
  return Text(
    data,
    style: const TextStyle(
      fontSize: 20,
      color: kcTextColor,
      decoration: TextDecoration.lineThrough,
      decorationColor: kcPrimaryColor,
      decorationThickness: 3.0,
    ),
  );
}

Widget textNormalWarning(String data){
  return Text(
    data,
    style: const TextStyle(
      fontSize: 20,
      color: kcWarningColor,
    ),
  );
}

Widget textNormalMenuItem(String data){
  return Text(
    data,
    style: const TextStyle(
      fontSize: 20,
      color: kcBlack,
    ),
  );
}