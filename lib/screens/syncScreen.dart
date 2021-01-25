import 'dart:convert';
import 'dart:async';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/screens/login.dart';
import 'package:crm/screens/recordingTabs.dart';
import 'package:crm/screens/callLogTabs.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:crm/database/database.dart';
import 'package:provider/provider.dart';
import 'package:date_range_picker/date_range_picker.dart' as DateRagePicker;

DateTime currentBackPressTime;

class SyncScreen extends StatefulWidget {
  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  String user;
  bool isSyncing = false;
  Map<String, dynamic> userData = new Map();
  int _currentIndex = 0;
  List<Widget> _children = [];
  bool syncCalled = false;
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  getUser() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString('currentUser');
    if (user == null) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: Login(),
        ),
      );
    } else {
      setState(() {
        userData = jsonDecode(user);
      });
    }
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("No"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Logout"),
      onPressed: logout,
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirm Logout"),
      content: Text("Are you sure you want to Logout."),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  logout() async {
    final prefs = await SharedPreferences.getInstance();
    DBProvider.db.reset();
    prefs.clear();
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: SyncScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  syncNow(provider) async {
    await provider.syncCallLogs();
    Stream<dynamic> recData = provider.syncRecordings();
    recData.listen((dynamic value) {
      if (value == false) {
        setState(() {
          isSyncing = false;
        });
        Fluttertoast.showToast(
            msg: "Recording synced!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        setState(() {
          isSyncing = false;
        });
      }
    });
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: 'Tap back again to leave');
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoreProvider>(
      create: (context) => CoreProvider(),
      child: Builder(builder: (context) {
        _children = [
          RecordingTabScreen(
            isCalled: syncCalled,
          ),
          CallLogsTabScreen()
        ];
        return WillPopScope(
            onWillPop: onWillPop,
            child: Scaffold(
              appBar: AppBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  title: Text(
                    "Welcome! HT Sales CRM",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  bottom: PreferredSize(
                      child: Container(
                        alignment: Alignment.topLeft,
                        padding:
                            EdgeInsets.only(left: 15, bottom: 15, right: 15),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${userData['mobileNo']}',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800),
                              ),
                              Consumer<CoreProvider>(
                                  builder: (context, provider, child) {
                                return MaterialButton(
                                    color: Theme.of(context).primaryColorLight,
                                    onPressed: () async {
                                      final List<DateTime> picked =
                                          await DateRagePicker.showDatePicker(
                                              context: context,
                                              initialFirstDate:
                                                  provider.fromDate,
                                              initialLastDate: provider.toDate,
                                              firstDate: new DateTime(
                                                  new DateTime.now().year - 1),
                                              lastDate: new DateTime.now());
                                      if (picked != null &&
                                          picked.length == 2) {
                                        print(picked);
                                        provider.setFromDate(picked.first);
                                        provider.setToDate(picked.last);
                                        setState(() {
                                          syncCalled = false;
                                        });
                                      }
                                    },
                                    child: new Text(
                                        '${provider.fromDate.toString().split(' ').first} - ${provider.toDate.toString().split(' ').first}',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800)));
                              })
                            ]),
                      ),
                      preferredSize: Size.fromHeight(45)),
                  actions: <Widget>[
                    Consumer<CoreProvider>(builder: (context, provider, child) {
                      if (syncCalled == false) {
                        // syncNow(provider);
                        setState(() {
                          syncCalled = true;
                        });
                      }
                      return RaisedButton(
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async {
                          // provider.setRecordingLoading(true);
                          await syncNow(provider);
                        },
                        child: Row(
                          children: [
                            (provider.callsSyncing == true ||
                                    provider.recordingSyncing == true)
                                ? Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5),
                                    child: SizedBox(
                                      child: CircularProgressIndicator(
                                        backgroundColor: Colors.white,
                                      ),
                                      height: 20.0,
                                      width: 20.0,
                                    ),
                                  )
                                : Text(''),
                            Text(
                              'Sync Now',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        elevation: 0,
                      );
                    }),
                  ]),
              bottomNavigationBar: BottomNavigationBar(
                onTap: onTabTapped,
                currentIndex: _currentIndex,
                items: [
                  new BottomNavigationBarItem(
                    icon: Icon(Icons.record_voice_over),
                    title: Text('Recordings'),
                  ),
                  new BottomNavigationBarItem(
                    icon: Icon(Icons.call),
                    title: Text('Call Logs'),
                  )
                ],
              ),
              body: _children[_currentIndex],
              persistentFooterButtons: [
                SizedBox(
                  width: double.maxFinite,
                  child: RaisedButton(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: () => showAlertDialog(context),
                    child: Text(
                      'Logout',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    elevation: 5,
                  ),
                )
              ],
            ));
      }),
    );
  }
}
