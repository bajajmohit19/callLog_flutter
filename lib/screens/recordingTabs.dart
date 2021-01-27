import 'dart:async';

import 'package:crm/providers/core_provider.dart';
import 'package:crm/screens/recordingSingleTab.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:crm/screens/login.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

class RecordingTabScreen extends StatefulWidget {
  final bool isCalled;
  RecordingTabScreen({Key key, this.isCalled}) : super(key: key);

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<RecordingTabScreen> {
  String user;
  int syncedCount = 0;
  int unsyncedCount = 0;
  List recordings = [];
  bool isSyncing = false;
  bool getCalled = false;
  StreamController _recordingController = StreamController.broadcast();
  // int _currentIndex = 0;
  // final List<Widget> _children = [];
  Map<String, dynamic> userData = new Map();

  var _snackBar;
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

  getRecordings(unsynced, context) async {
    Provider.of<CoreProvider>(context, listen: false)
        .getAllRecording(unsynced)
        .listen((event) {
      if (event.length != 0) _recordingController.add(event);
    });
  }

  showMessage(str, error) {
    var snackBar;
    snackBar = SnackBar(
      content: Text(
        str,
        textAlign: TextAlign.center,
      ),
      backgroundColor: error == true ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    );
    setState(() {
      _snackBar = snackBar;
    });
  }

  syncFile(file, provider) async {
    var success = await provider.syncSingleRecording(file, jsonDecode(user));
    if (success == true) {
      showMessage('Recording synced!', false);
    } else {
      showMessage('Syncing failed', true);
    }
    return;
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
          length: 2, // This is the number of tabs.
          child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                // These are the slivers that show up in the "outer" scroll view.
                return <Widget>[
                  Consumer<CoreProvider>(builder: (context, provider, child) {
                    final List<dynamic> _tabs = [
                      'Unsynced (' + provider.unsyncedRecord.toString() + ')',
                      'Synced (' + provider.syncedRecord.toString() + ')'
                    ];
                    return SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context),
                      sliver: SliverAppBar(
                          backgroundColor: Color(0xff025dfa),
                          titleSpacing: 0,
                          toolbarHeight: 0,
                          flexibleSpace: TabBar(
                              tabs: _tabs
                                  .map((name) => Tab(
                                          child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      )))
                                  .toList()),
                          pinned: true,
                          expandedHeight: 0.1,
                          floating: true),
                    );
                  })
                ];
              },
              body: TabBarView(
                children: [
                  RecordingScreen(unsynced: true, context: context),
                  RecordingScreen(unsynced: 0, context: context)
                ],
              ))),
    );
  }
}
