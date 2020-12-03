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
  List<bool> _isFileSyncing = List.filled(1, false);

  List<Widget> _children = [];
  // call_logs phone calls sync -- database
  // call recording sync -- automatic .. Download -- Name

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
    // syncNow();
  }

  syncNow() async {
    if (isSyncing == true) {
      return false;
    }
    var isFileSyncing = _isFileSyncing;
    setState(() {
      isSyncing = true;
    });
    await CoreProvider().syncCallLogs();
    isFileSyncing[0] = true;
    setState(() {
      _isFileSyncing = [...isFileSyncing];
    });
    Stream<dynamic> recData = CoreProvider().syncRecordings();
    recData.listen((dynamic value) {
      if (value == false) {
        setState(() {
          isSyncing = false;
          _isFileSyncing = List.filled(1, false);
        });
        Fluttertoast.showToast(
            msg: "Recording synced!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        isFileSyncing = _isFileSyncing;
        isFileSyncing[0] = true;
        setState(() {
          _isFileSyncing = [...isFileSyncing];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _children = [
      RecordingTabScreen(isFileSyncing: _isFileSyncing),
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
                  padding: EdgeInsets.only(left: 15, bottom: 15),
                  child: Text(
                    '${userData['mobileNo']}',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                preferredSize: Size.fromHeight(30)),
            actions: <Widget>[
              RaisedButton(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                onPressed: () async => {await syncNow()},
                child: Row(
                  children: [
                    isSyncing == true
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                elevation: 0,
              ),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              elevation: 5,
            ),
          )
        ],
      ),
    );
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
}
