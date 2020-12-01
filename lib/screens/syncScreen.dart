import 'dart:convert';
import 'dart:async';
import 'package:crm/screens/login.dart';
import 'package:crm/screens/tabs.dart';
// import 'package:crm/screens/tabs.dart';
import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
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
  // 15 minutes
  String user;
  bool isSyncing = false;
  Map<String, dynamic> userData = new Map();

  // call_logs phone calls sync -- database
  // call recording sync -- automatic .. Download -- Name

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

  syncNow() async {
    // CoreProvider().syncRecordings();
    // CoreProvider().syncCallLogs();
  }

  @override
  void initState() {
    super.initState();
    getUser();
    // CoreProvider().syncRecordings();
    // CoreProvider().syncCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        body: TabsScreen(),
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
