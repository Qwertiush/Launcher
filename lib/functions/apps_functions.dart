  import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<void> addQuickApp(String packageName, int position) async {
    bool isAppAdded = await checkQuickApp(packageName);
    if (isAppAdded) {
      debugPrint('App is already added.');
      removeQuickApp(packageName);
      return;
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/settings.txt');

    // Read existing file content
    List<String> lines = [];
    if (await file.exists()) {
      lines = await file.readAsLines();
    }

    // Check if the file has at least 2 lines
    if (lines.length >= 2) {
      // Modify the line at index 1 (second line) with the new data
      if(lines[1] == ""){
        lines[1] += '$packageName-$position';
      }
      else{
        lines[1] += ",$packageName-$position";
      }

      // Write the updated lines back to the file
      await file.writeAsString(lines.join('\n'));

      debugPrint(lines[1]);
    }
    else{
      lines.add('$packageName-$position');

      await file.writeAsString(lines.join('\n'));
    }

    debugPrint(lines[1]);
  }

  Future<void> removeQuickApp(String packageName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/settings.txt');

    // Read existing file content
    List<String> lines = [];
    if (await file.exists()) {
      lines = await file.readAsLines();
    }

    // Check if the file has at least 2 lines
    if (lines.length >= 2) {
      List<String> lineContent = lines[1].split(',');
      for(int i = 0; i < lineContent.length; i++){
        if(lineContent[i].split('-')[0] == packageName){
          debugPrint("removing ${lineContent[i]}");
          lineContent.removeAt(i);
        }
      }
      String result = "";
      for(int j = 0; j < lineContent.length; j++){
        if(j == 0){
          result += lineContent[j];
        }
        else{
          result += ",${lineContent[j]}";
        }
      }
      lines[1] = result;

      // Write the updated lines back to the file
      await file.writeAsString(lines.join('\n'));
    }

    debugPrint(lines[1]);
  }

  Future<bool> checkQuickApp(String packageName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/settings.txt');
    bool result = false;

    // Read existing file content
    List<String> lines = [];
    if (await file.exists()) {
      lines = await file.readAsLines();
    }

    // Check if the file has at least 2 lines
    if (lines.length >= 2) {
      if(lines[1].contains(packageName)){
        result = true;     
      }
      debugPrint(lines[1]);
    }

    return result;
  }

  void showInfoApp(Application app) async {
    try {
      DeviceApps.openAppSettings(app.packageName);
    } catch (e) {
      debugPrint('Error occurred while infoing the app: $e');
    }
  }