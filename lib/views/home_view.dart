import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mos/consts/colors.dart';
import 'package:mos/consts/consts.dart';
import 'package:mos/consts/sizes.dart';
import 'package:mos/views/apps_view.dart';
import 'package:intl/intl.dart';
import 'package:mos/views/left_view.dart';
import 'package:mos/views/settings_view.dart';
import 'package:mos/widgets/quick_app_placeholder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_apps/device_apps.dart';

import '../functions/apps_functions.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ValueNotifier<DateTime> _dateTimeNotifier = ValueNotifier<DateTime>(DateTime.now());
  late Timer _timer;

  late Future<String?> _backgroundPickPathFuture;
  List<String> quickApps = List<String>.generate(maxQuickAppsNr, (_) => "");

  final PageController _pageController = PageController(initialPage: 1);

  bool isPomodorActive = false;
  bool isQuickAppsActive = false;

  //pomodoro
  TextEditingController _textEditingControllerFocus = TextEditingController();
  String _textFieldValueFocus = '25:00';
  TextEditingController _textEditingControllerShortBreak = TextEditingController();
  String _textFieldValueShortBreak = '05:00';
  TextEditingController _textEditingControllerLongBreak = TextEditingController();
  String _textFieldValueLongBreak = '30:00';


  bool _pomodoroRunning = false;
  Timer? _countdownTimer;

  List<String> valueHolder = [];
  List<int> _countdownValueFocus = [];
  List<int> _countdownValueShortBreak = [];
  List<int> _countdownValueLongBreak = [];

  int timerType = 0; //0-countuing focus, 1 - short break, 2 - long break
  int pomodoroCycle = 0;
  int pomodoroCycleMax = 4;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void startCountdown() {
    setState(() {
      valueHolder = _textEditingControllerFocus.text.split(':');
      _countdownValueFocus = [int.tryParse(valueHolder[0]) ?? 0,int.tryParse(valueHolder[1]) ?? 0];
      valueHolder = _textEditingControllerFocus.text.split(':');
      _countdownValueShortBreak = [int.tryParse(valueHolder[0]) ?? 0,int.tryParse(valueHolder[1]) ?? 0];
      valueHolder = _textEditingControllerFocus.text.split(':');
      _countdownValueLongBreak = [int.tryParse(valueHolder[0]) ?? 0,int.tryParse(valueHolder[1]) ?? 0];
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if(timerType == 0){
          _countFocus();
        }
        else if(timerType == 1)
        {
          _countShortBreak();
        }
        else{
          _countLongBreak();
        }

      });
    });
  }

  void _countFocus(){
    setState(() {
      valueHolder = _textEditingControllerFocus.text.split(':');
      _countdownValueFocus = [int.tryParse(valueHolder[0]) ?? 0,int.tryParse(valueHolder[1]) ?? 0];
    });
    countDown(_countdownValueFocus);
    _textEditingControllerFocus.text = prepareTimeAsString(_countdownValueFocus);
    if(_countdownValueFocus[0] == 0 && _countdownValueFocus[1] == 0){
    //  _countdownTimer?.cancel();
      showNotification("Take a break", "");
      setState(() {
        pomodoroCycle++;
        if(pomodoroCycle < pomodoroCycleMax){
          timerType = 1;
          _textEditingControllerFocus.text = "25:00";
        }
        else{
          timerType = 2;
          _textEditingControllerFocus.text = "25:00";
        }
      });
    }
  }
  void _countShortBreak(){
    setState(() {
      valueHolder = _textEditingControllerShortBreak.text.split(':');
      _countdownValueShortBreak = [int.tryParse(valueHolder[0]) ?? 0,int.tryParse(valueHolder[1]) ?? 0];
    });
    countDown(_countdownValueShortBreak);
    _textEditingControllerShortBreak.text = prepareTimeAsString(_countdownValueShortBreak);
    if(_countdownValueShortBreak[0] == 0 && _countdownValueShortBreak[1] == 0){
    //  _countdownTimer?.cancel();
      showNotification("Time to focus", "End of $pomodoroCycle cycle");
      setState(() {
        timerType = 0;
        _textEditingControllerShortBreak.text = "05:00";
      });
    }
  }
  void _countLongBreak(){
    setState(() {
      valueHolder = _textEditingControllerLongBreak.text.split(':');
      _countdownValueLongBreak = [int.tryParse(valueHolder[0]) ?? 0,int.tryParse(valueHolder[1]) ?? 0];
    });
    countDown(_countdownValueLongBreak);
    _textEditingControllerLongBreak.text = prepareTimeAsString(_countdownValueLongBreak);
    if(_countdownValueLongBreak[0] == 0 && _countdownValueLongBreak[1] == 0){      
      showNotification("And of cycle", "End of $pomodoroCycle cycle");
      setState(() {
        timerType = 0;
        _textEditingControllerLongBreak.text = "30:00";
        pomodoroCycle = 0;
      });
    }
  }

  void countDown(List<int> time){
    if(time[1] > 0){
      time[1]--;
    }
    else{
      time[0]--;
      time[1] = 59;
    }
  }

  String prepareTimeAsString(List<int> time){
    String result = "";
    String zeroMinute = "";
    String zeroSecond = "";

    if(time[0] < 10){
      zeroMinute = "0";
    }

    if(time[1] < 10){
      zeroSecond = "0";
    }

    result = "$zeroMinute${time[0]}:$zeroSecond${time[1]}";
    return result;
  }

  void _stopPomodoro(){
    _countdownTimer?.cancel();
    pomodoroCycle = 0;
    timerType = 0;
    setState(() {
      _textEditingControllerFocus.text = "25:00";
      _textEditingControllerShortBreak.text = "05:00";
      _textEditingControllerLongBreak.text = "30:00";
    });
  }
  

  //pomodoro

  Future<String?> readBackgroundInfoFromFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File file = File('${appDocDir.path}/settings.txt');

    if (file.existsSync()) {
      List<String> lines = await file.readAsLines();

      if(lines.length >= 2){
        debugPrint("here 1");
      setState(() {
        List<String> appsTemp = lines[1].split(',');
        if(lines.length >=2){
          debugPrint("here 2");
          for(int i = 0; i < appsTemp.length; i++){
            List<String> appInfoTemp = appsTemp[i].split('-');
            if(appInfoTemp.length >= 2){
              debugPrint("here 3");
              quickApps[int.parse(appInfoTemp[1])] = appsTemp[i];
            }
          }
        }
        else{
          debugPrint("here 4");
          quickApps = [];
        }
      });
      }

      debugPrint("QuickApps Fetched");
      for(String app in lines){
        debugPrint(app);
      }

      return lines[0];
    }

    return null;
  }

  List<Application> _apps = [];

  void onFetchAppsButtonPressed() async {
    // Fetch installed apps
    final installedApps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

    setState(() {
      _apps = installedApps;
    });
    
    debugPrint("apps fetched");

    for(int i=0;i < installedApps.length; i++){
      debugPrint("$i: ${installedApps[i].appName}");
    }
  }
  
  @override
  void initState() {
    super.initState();
    startTimer();
    _backgroundPickPathFuture = readBackgroundInfoFromFile();

    _textEditingControllerFocus.text = _textFieldValueFocus;
    _textEditingControllerShortBreak.text = _textFieldValueShortBreak;
    _textEditingControllerLongBreak.text = _textFieldValueLongBreak;

    initializeNotifications();

    onFetchAppsButtonPressed();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String notificationTitle,String notificationContent) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'app_notifications',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      notificationTitle,
      notificationContent,
      platformChannelSpecifics,
  );
}

  void updateTextFieldValues(String value) {
    setState(() {
      _textFieldValueFocus = value;
      _textFieldValueShortBreak = value;
      _textFieldValueLongBreak = value;
    });
  }

  void changeBcImage()
  {
    setState(() {
      _backgroundPickPathFuture = readBackgroundInfoFromFile();
    });
  }

  @override
  void dispose() {

    _timer.cancel();
    _pageController.dispose();
    _dateTimeNotifier.dispose();

    _textEditingControllerFocus.dispose();
    _textEditingControllerShortBreak.dispose();
    _textEditingControllerLongBreak.dispose();

    _countdownTimer?.cancel();

    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _dateTimeNotifier.value = DateTime.now();
    });
  }

  void goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void refresh(){
    setState(() {
      quickApps = List<String>.generate(maxQuickAppsNr, (_) => "");
    });
    _backgroundPickPathFuture = readBackgroundInfoFromFile();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      body: FutureBuilder<String?>(
        future: _backgroundPickPathFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            final backgroundPickPath = snapshot.data;

            return Container(
              decoration: backgroundPickPath != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(backgroundPickPath)),
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              child: PageView(
                controller: _pageController,
                children: [
                  LeftView(),
                  Stack(
                    children: [ ValueListenableBuilder<DateTime>(
                      valueListenable: _dateTimeNotifier,
                      builder: (context, dateTime, _) {
                        final currentTime = DateFormat('hh:mm:ss a').format(dateTime);
                        final currentDate = DateFormat('MMM dd, yyyy').format(dateTime);
                        return Center(
                          child: Column(
                            children: [
                              spacerVerticalSmall(context),
                              isQuickAppsActive ? GestureDetector(
                                onTap: () {
                                  debugPrint("settings");
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsView())).then((result){
                                    if(result == "bcChanged"){
                                      debugPrint("Changing BackGroundImage");
                                      setState(() {
                                        _backgroundPickPathFuture = readBackgroundInfoFromFile();
                                      });             
                                    }
                                  });
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  color: kcPrimaryColor,
                                  child: Center(
                                    child: textNormal("Settings"),
                                    ),
                                ),
                              ) : Container(),
                              Container(
                                child: Column(
                                  children: [
                                    textNormal(currentTime),
                                    textNormal(currentDate),
                                  ],
                                ),
                              ),
                              spacerVerticalSmall(context),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 20,
                      right: 100,
                      child: FloatingActionButton(
                        onPressed: (){
                          debugPrint("show/hide pomodor");
                          setState(() {
                            isPomodorActive = !isPomodorActive;
                          });
                        },
                        child: Icon(Icons.cloud),
                        backgroundColor: kcPrimaryColor,
                        foregroundColor: kcPrimaryColorDark,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: (){
                          debugPrint("show/hide quick apps");
                          setState(() {
                            isQuickAppsActive = !isQuickAppsActive;
                          });
                        },
                        child: Icon(Icons.add),
                        backgroundColor: kcPrimaryColor,
                        foregroundColor: kcPrimaryColorDark,
                      ),
                    ),
                    isQuickAppsActive ? Positioned(
                      bottom: 20,
                      left: 20,
                      child: FloatingActionButton(
                        onPressed: (){
                          debugPrint("Refreshing settings (User's Prefs)");
                          refresh();
                        },
                        child: Icon(Icons.refresh),
                        backgroundColor: kcPrimaryColor,
                        foregroundColor: kcPrimaryColorDark,
                      ),
                    ) : Container(),
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.15,
                      child: isQuickAppsActive ? Container(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height * 0.3,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[0].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[1].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[2].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[3].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[4].split('-')[0]),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[5].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[6].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[7].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[8].split('-')[0]),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.05,
                                        ),
                                        QuickApp(quickApps[9].split('-')[0]),
                                      ],
                                    ),
                                  ],
                                ),
                              ) : Container(),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.2,
                      left: MediaQuery.of(context).size.width * 0.05,
                      child: isPomodorActive ? Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.3,
                                color: Colors.red,
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.45,
                                          height: MediaQuery.of(context).size.height * 0.2,
                                          color: Colors.black,
                                          child: Center(child: textNormal("Pomodor")),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.225,
                                                height: MediaQuery.of(context).size.height * 0.1,
                                                color: Colors.blue,
                                                child: Center(child: textNormal("Start")),
                                              ),
                                              onTap: (){
                                                debugPrint("Start/Pause");
                                                if(!_pomodoroRunning){
                                                  startCountdown();
                                                  _pomodoroRunning = true;
                                                }
                                              },
                                            ),
                                            GestureDetector(
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.225,
                                                height: MediaQuery.of(context).size.height * 0.1,
                                                color: Colors.green,
                                                child: Center(child: textNormal("Reset")),
                                              ),
                                              onTap: (){
                                                debugPrint("Reset");
                                                _stopPomodoro();
                                                _pomodoroRunning = false;
                                              },
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(width: MediaQuery.of(context).size.width * 0.05,),
                                    Column(
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context).size.height * 0.1,
                                          width: MediaQuery.of(context).size.width * 0.4,
                                          child: TextField(
                                            controller: _textEditingControllerFocus,
                                            style: TextStyle(color: kcLightGrey,fontSize: 25),
                                            decoration: InputDecoration(
                                              hintText: '25:00',
                                              hintStyle: TextStyle(color: kcTextHintColor,fontSize: 25),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context).size.height * 0.1,
                                          width: MediaQuery.of(context).size.width * 0.4,
                                          child: TextField(
                                            controller: _textEditingControllerShortBreak,
                                            style: TextStyle(color: kcLightGrey,fontSize: 25),
                                            decoration: InputDecoration(
                                              hintText: '5:00',
                                              hintStyle: TextStyle(color: kcTextHintColor,fontSize: 25),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context).size.height * 0.1,
                                          width: MediaQuery.of(context).size.width * 0.4,
                                          child: TextField(
                                            controller: _textEditingControllerLongBreak,
                                            style: TextStyle(color: kcLightGrey,fontSize: 25),
                                            decoration: InputDecoration(
                                              hintText: '30:00',
                                              hintStyle: TextStyle(color: kcTextHintColor,fontSize: 25),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ) : Container(), 
                    ),
                  ]
                  ),
                  AppsView(_apps, quickApps),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget QuickApp(String packageName){
    return Builder(
      builder: (context) {
        final app = _apps.firstWhere((app) => app.packageName == packageName, orElse: () => _apps[0]);
        if(app.packageName != packageName){
          return quickAppPlaceholder(context, 0.14, 0.15);
        }

        return GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(app is ApplicationWithIcon ? app.icon : Uint8List(2)),
              ),
            ),
            width: MediaQuery.of(context).size.width * 0.14,
            height: MediaQuery.of(context).size.height * 0.15,
          ),
          onTap: () {
            DeviceApps.openApp(app.packageName);
          },
          onLongPress: (){
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
                  value: 'info',
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: Center(child: textNormalWarning('App info'))
                  ),
                ),
                PopupMenuItem(
                  value: 'add-remove',
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: Center(child: textNormal('Remove from Home'))
                  ),
                ),
                PopupMenuItem(
                  value: 'change-position',
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: Center(child: textNormal('Change position'))
                  ),
                ),
              ]
            ).then((value) {
              if(value == 'info'){
                debugPrint("Infoing " + app.appName);
                showInfoApp(app);
              }
              if(value == 'add-remove'){
                debugPrint("Removing quick app " + app.appName);
                removeQuickApp(app.packageName).then((value) => refresh());
              }
              if(value == 'change-position'){
                debugPrint("Changing position");

              }
            });
          },
        );
      },
    );
  }
}
