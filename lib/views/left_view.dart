import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mos/consts/colors.dart';
import 'package:mos/consts/consts.dart';
import 'package:mos/consts/sizes.dart';
import 'package:mos/items/task.dart';
import 'package:path_provider/path_provider.dart';

class LeftView extends StatefulWidget {
  const LeftView({super.key});

  @override
  State<LeftView> createState() => __LeftViewState();
}

class __LeftViewState extends State<LeftView>
    with SingleTickerProviderStateMixin {

  final TextEditingController _taskController = TextEditingController();

  List<Task> tasks = [];
  String currentTaskText = "";
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    getTasksFromFile();
  }

  Future<void> getTasksFromFile() async{
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/tasks.txt');

    debugPrint("looking for tasks");
    if (file.existsSync()) {
      debugPrint("fetching tasks");
      List<String> lines = await file.readAsLines();

      for(String line in lines) {
        debugPrint(line);
        setState(() {
          tasks.add(Task.fromLineOfData(line));
        });
      }
    }
  }

  Future<void> saveTasksInFile() async{
    debugPrint("saving tasks");
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/tasks.txt');

    List<String> lines = tasks.map((task) => task.prepareSaveForm()).toList();
    String data = lines.join('\n');

    await file.writeAsString(data);
  }

  void addTask() {
    final currentTaskText = _taskController.text;
    if(currentTaskText.contains(splitPattern)){
      debugPrint('Task $currentTaskText was not added');
      return;
    }

    debugPrint('Task $currentTaskText was added');
    _taskController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      tasks.add(Task(currentTaskText, false));
      saveTasksInFile();
    });

    // Add your logic to handle the task addition
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kcBackgroundTasksColorBlur,
      child: Column(
        children: [
          spacerVerticalSmall(context),
          Expanded(
            flex: 8,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (context, index){
                return Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: ListTile(
                        title: !tasks[index].done ? textNormal(tasks[index].content) : textNormalCrossed(tasks[index].content),
                        onLongPress: () {
                            final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                            final position = RelativeRect.fromLTRB(
                              overlay.size.width,
                              overlay.size.height, 
                              0, 
                              0
                            );
    
                            showMenu(
                              context: context,
                              position: position,
                              color: kcPrimaryColorDark,
                              items: [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height * 0.1,
                                    child: Center(child: textNormalWarning('Delete ' + (tasks[index].content.length > 10 ? tasks[index].content.substring(0, 10) + "..." : tasks[index].content))),
                                    ),
                                  ),
                              ],
                            ).then((value){
                              if(value == 'delete'){
                                debugPrint("Deleteing " + tasks[index].content);
                                setState(() {
                                  tasks.removeAt(index);
                                  saveTasksInFile();
                                });
                              }    
                            });
                        }
                      ),
                    ),
                      Transform.scale(
                        scale: 1.5,
                        child: Checkbox(
                          value: tasks[index].done, 
                          onChanged: (value) {
                            setState(() {
                              tasks[index].done = value!;
                              saveTasksInFile();
                            });
                          },
                        ),
                      )
                  ],
                );
              }
            ,)
          ),
          Container(
            color: kcPrimaryColorDark,
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.05,
                ),
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: TextField(
                      controller: _taskController,
                      style: TextStyle(color: kcTextHintColor,fontSize: 25),
                      decoration: InputDecoration(
                        hintText: 'Write Task...',
                        hintStyle: TextStyle(color: kcLightGrey,fontSize: 25),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: IconButton(
                    onPressed: addTask,
                    icon: Icon(Icons.add_task, size: 40,),
                    color: kcPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}