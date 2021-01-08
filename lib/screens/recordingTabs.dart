import 'package:crm/providers/core_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:crm/screens/login.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecordingTabScreen extends StatefulWidget {
  RecordingTabScreen({Key key}) : super(key: key);

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<RecordingTabScreen> {
  String user;
  int syncedCount = 0;
  int unsyncedCount = 0;
  List recordings = [];
  bool isSyncing = false;
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
    recordings = await Provider.of<CoreProvider>(context, listen: false)
        .getAllRecording(unsynced);

    if (unsynced == true
        ? unsyncedCount != recordings.length
        : syncedCount != recordings.length)
      setState(() {
        unsynced == true
            ? unsyncedCount = recordings.length
            : syncedCount = recordings.length;
      });
    return recordings;
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

  Widget recordingWidget(unsynced, context) {
    return FutureBuilder(
      future: getRecordings(unsynced, context),
      builder: (buildContext, userSnap) {
        switch (userSnap.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return new Container(
                margin: EdgeInsets.only(top: 20),
                child: Center(
                    child: new Text(
                  'loading...',
                  style: TextStyle(fontSize: 24, color: Colors.indigo),
                )));
          default:
            if (userSnap.hasError)
              return new Text('Error: ${userSnap.error}');
            else
              return new Container(
                // margin: EdgeInsets.only(top: 40),
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: userSnap.data == null ? 0 : userSnap.data.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: <Widget>[
                        Card(
                          child: Consumer<CoreProvider>(
                              builder: (context, provider, child) {
                            return ListTile(
                                isThreeLine: true,
                                leading: Icon(Icons.music_note),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(userSnap.data[index].title)
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Column(children: [
                                      Text(userSnap.data[index].path.toString(),
                                          style: TextStyle(fontSize: 12)),
                                    ]),
                                    Row(
                                      children: [
                                        Text(
                                            DateFormat('dd/MM/yyyy hh:mm')
                                                .format(userSnap
                                                    .data[index].createdAt),
                                            style: TextStyle(fontSize: 12)),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          child: Text(userSnap.data[index].size,
                                              style: TextStyle(fontSize: 12)),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                contentPadding: EdgeInsets.all(15),
                                dense: false,
                                trailing: unsynced != 0
                                    ? GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () async {
                                          await syncFile(
                                              userSnap.data[index], provider);
                                          Scaffold.of(buildContext)
                                              .showSnackBar(_snackBar);
                                        },
                                        child: provider.sycingRecord.contains(
                                                    userSnap.data[index].id) ==
                                                false
                                            ? Icon(Icons.sync)
                                            : CircularProgressIndicator())
                                    : null);
                          }),
                        ),
                      ],
                    );
                  },
                ),
              );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> _tabs = [
      'Unsynced (' + unsyncedCount.toString() + ')',
      'Synced (' + syncedCount.toString() + ')'
    ];
    return MaterialApp(
      home: DefaultTabController(
          length: _tabs.length, // This is the number of tabs.
          child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                // These are the slivers that show up in the "outer" scroll view.
                return <Widget>[
                  SliverOverlapAbsorber(
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
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  recordingWidget(true, context),
                  recordingWidget(0, context)
                ],
              ))),
    );
  }
}
