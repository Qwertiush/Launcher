import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mos/consts/colors.dart';
import 'package:mos/consts/sizes.dart';
import 'package:path_provider/path_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late final File backgroundImage;
  bool _bcChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateBack(String result){
    Navigator.pop(context, result);
  }

  Future<void> saveToFile(String data) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/settings.txt');

    // Read existing file content
    List<String> lines = [];
    if (await file.exists()) {
      lines = await file.readAsLines();
    }
    lines[0] = data;

    // Write the updated lines back to the file
    await file.writeAsString(lines.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        if(_bcChanged){
          _navigateBack("bcChanged");
        }
        else{
          _navigateBack("bcNotChanged");
        }

        return true;
      },
      child: Container(
        color: kcBackgroundColor,
        child: Column(
          children: [
            spacerVerticalSmall(context),
            GestureDetector(
              onTap: (){
                debugPrint("choosing bc pic");
                _bcChanged = true;
                _pickImage();
              },
              child: Container(
                color: kcPrimaryColorDark,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.1,
                child: Center(
                  child: textNormal("Choose background"),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if(pickedImage != null)
    {
      debugPrint(pickedImage.path);
      saveToFile(pickedImage.path);
    }
  }

}