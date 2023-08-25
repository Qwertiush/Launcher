import 'package:flutter/material.dart';

class AppPopUpSettings extends StatefulWidget {
  const AppPopUpSettings({super.key});

  @override
  State<AppPopUpSettings> createState() => _AppPopUpSettingsState();
}

class _AppPopUpSettingsState extends State<AppPopUpSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.red,
    );
  }
}