import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:mos/consts/colors.dart';
import 'package:mos/consts/consts.dart';
import 'package:mos/consts/sizes.dart';
import 'package:mos/widgets/quick_app_placeholder.dart';

import '../functions/apps_functions.dart';

class AppsView extends StatefulWidget {
  AppsView(this.appsFetched, this.quickApps, {super.key});

  List<Application> appsFetched = [];
  List<String> quickApps = [];

  @override
  State<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends State<AppsView> {
  Future<List<Application>>? _fetchAppsFuture;
  String _searchQuery = '';

  bool isquickAppPositionMenuOpen = false;
  String currentPackageName = "";

  @override
  void initState() {
    super.initState();
  }

  void onFetchAppsButtonPressed() async {
    // Fetch installed apps
    final installedApps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

    setState(() {
      widget.appsFetched = installedApps;
    });

    debugPrint("view refreshed");
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Application> _performSearch() {
    if (_searchQuery.isEmpty) {
      widget.appsFetched.sort(
          (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      return widget.appsFetched;
    }

    final lowercaseQuery = _searchQuery.toLowerCase();
    final filteredApps = widget.appsFetched
        .where((app) => app.appName.toLowerCase().contains(lowercaseQuery))
        .toList();

    filteredApps.sort((a, b) => a.appName.compareTo(b.appName));

    return filteredApps;
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _performSearch();

    return Stack(children: [
      Container(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: kcBackgroundAppsColorBlur,
            child: Column(
              children: [
                spacerVerticalSmall(context),
                Expanded(
                  flex: 8,
                  child: FutureBuilder<List<Application>>(
                    future: _fetchAppsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: kcTextColor),
                        );
                      } else {
                        return ListView.builder(
                          reverse: true,
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: MemoryImage(
                                    app is ApplicationWithIcon
                                        ? app.icon
                                        : Uint8List(2)),
                              ),
                              title: textNormal(app.appName),
                              onTap: () {
                                DeviceApps.openApp(app.packageName);
                              },
                              onLongPress: () {
                                final RenderBox overlay = Overlay.of(context)
                                    .context
                                    .findRenderObject() as RenderBox;
                                final position = RelativeRect.fromLTRB(
                                    overlay.size.width,
                                    overlay.size.height,
                                    0,
                                    0);

                                showMenu(
                                  context: context,
                                  position: position,
                                  color: kcPrimaryColorDark,
                                  items: [
                                    PopupMenuItem(
                                      value: 'info',
                                      child: Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.1,
                                          child: Center(
                                              child: textNormalWarning(
                                                  'App info'))),
                                    ),
                                    PopupMenuItem(
                                      value: 'add-remove',
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.1,
                                        child: Center(
                                            child: FutureBuilder<bool>(
                                          future:
                                              checkQuickApp(app.packageName),
                                          builder: ((context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return Text(
                                                'Error ${snapshot.error}',
                                                style: TextStyle(
                                                    color: kcTextColor),
                                              );
                                            } else {
                                              final isAppAdded = snapshot.data;
                                              if (isAppAdded!) {
                                                return textNormal(
                                                    "Remove from Home");
                                              } else {
                                                isquickAppPositionMenuOpen =
                                                    true;
                                                return textNormal(
                                                    "Add to Home");
                                              }
                                            }
                                          }),
                                        )),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value == 'info') {
                                    debugPrint("Infoing " + app.appName);
                                    showInfoApp(app);
                                  }
                                  if (value == 'add-remove') {
                                    debugPrint(
                                        "Adding quick app " + app.appName);
                                    setState(() {
                                      if (!isquickAppPositionMenuOpen) {
                                        removeQuickApp(app.packageName);
                                      }
                                      currentPackageName = app.packageName;
                                    });
                                  }
                                });
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Container(
                  color: kcPrimaryColorDark,
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.05,
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: _updateSearchQuery,
                          style:
                              TextStyle(color: kcTextHintColor, fontSize: 25),
                          decoration: InputDecoration(
                            hintText: 'Search apps...',
                            hintStyle:
                                TextStyle(color: kcLightGrey, fontSize: 25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 40.0,
        right: 20.0,
        child: FloatingActionButton(
          onPressed: () {
            onFetchAppsButtonPressed();
          },
          child: Icon(Icons.refresh),
          backgroundColor: kcPrimaryColorDark,
          foregroundColor: kcPrimaryColor,
        ),
      ),
      isquickAppPositionMenuOpen
          ? Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.05,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.4,
                color: kcPrimaryColorDark,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < 10 / 2; i++)
                          GestureDetector(
                            child: Container(
                              child: quickAppPlaceholder(context, 0.14, 0.07),
                              color: kcPrimaryColor,
                              margin: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.02),
                            ),
                            onTap: () {
                              debugPrint(i.toString());
                              if (currentPackageName != "") {
                                addQuickApp(currentPackageName, i);
                                setState(() {
                                  isquickAppPositionMenuOpen = false;
                                });
                              }
                            },
                          )
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Row(
                      children: [
                        for (int i = 5; i < 10; i++)
                          GestureDetector(
                            child: Container(
                              child: quickAppPlaceholder(context, 0.14, 0.07),
                              color: kcPrimaryColor,
                              margin: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.02),
                            ),
                            onTap: () {
                              debugPrint(i.toString());
                              if (currentPackageName != "") {
                                addQuickApp(currentPackageName, i);
                                setState(() {
                                  isquickAppPositionMenuOpen = false;
                                });
                              }
                            },
                          )
                      ],
                    ),
                  ],
                ),
              ))
          : Container()
    ]);
  }
}
