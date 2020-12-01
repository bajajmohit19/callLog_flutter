import 'package:crm/providers/core_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:crm/screens/login.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TabsScreen extends StatefulWidget {
  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabsScreen> {
  String user;
  List<Map<String, dynamic>> recordings = [];
  List<bool> _isFileSyncing = List.filled(1, false);
  bool isSyncing = false;
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

  getRecordings(unsynced) async {
    recordings = await CoreProvider().getAllRecording(unsynced);
    _isFileSyncing = List.filled(recordings.length, false);
  }

  showMessage(str) {
    var snackBar;
    snackBar = SnackBar(
      content: Text(
        str,
        textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    );
    setState(() {
      _snackBar = snackBar;
    });
  }

  syncFile(file, index) async {
    var isFileSyncing = _isFileSyncing;
    isFileSyncing[index] = true;
    setState(() {
      _isFileSyncing = [...isFileSyncing];
    });
    var success =
        await CoreProvider().syncSingleRecording(file, jsonDecode(user));
    if (success == true) {
      showMessage('Recording synced!');
    } else {
      showMessage('Syncing failed');
    }
    isFileSyncing[index] = false;
    setState(() {
      _isFileSyncing = [...isFileSyncing];
    });
    return;
  }

  @override
  void initState() {
    super.initState();
    getUser();
    // CoreProvider().syncRecordings();
    // CoreProvider().syncCallLogs();
  }

  syncNow() {
    var isFileSyncing = _isFileSyncing;
    isFileSyncing[0] = true;
    setState(() {
      isSyncing = true;
      _isFileSyncing = [...isFileSyncing];
    });
    Stream<dynamic> recData = CoreProvider().syncRecordings();
    recData.listen((dynamic value) {
      if (value == false) {
        setState(() {
          isSyncing = false;
        });
      } else {
        isFileSyncing = _isFileSyncing;
        isFileSyncing[value] = false;
        isFileSyncing[value + 1] = true;
        setState(() {
          _isFileSyncing = [...isFileSyncing];
        });
      }
    });
    CoreProvider().syncCallLogs();
  }

  Widget recordingWidget(unsynced) {
    return FutureBuilder(
      future: CoreProvider().getAllRecording(unsynced),
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
                margin: EdgeInsets.only(top: 40),
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: userSnap.data == null ? 0 : userSnap.data.length,
                  itemBuilder: (context, index) {
                    if (userSnap.data.length != _isFileSyncing.length) {
                      var temp = List.filled(userSnap.data.length, false);
                      if (_isFileSyncing.length < userSnap.data.length) {
                        _isFileSyncing = temp;
                      } else if (isSyncing == true) {
                        temp.setRange(0, 1, [true]);
                      }
                      _isFileSyncing = temp;
                    }
                    // var project = userSnap.data[index];
                    return Column(
                      children: <Widget>[
                        Card(
                          child: ListTile(
                              isThreeLine: true,
                              leading: Icon(Icons.music_note),
                              // title: Text(userSnap.data[index].title,
                              //     style: TextStyle(fontSize: 20)),
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
                                          DateFormat('dd/MM/yyyy hh:mm').format(
                                              userSnap.data[index].createdAt),
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
                                            userSnap.data[index], index);
                                        Scaffold.of(buildContext)
                                            .showSnackBar(_snackBar);
                                      },
                                      child: _isFileSyncing[index] == false
                                          ? Icon(Icons.sync)
                                          : CircularProgressIndicator())
                                  : null),
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
    final List<String> _tabs = ['Unsynced', 'Synced'];
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
                        backgroundColor: Theme.of(context).primaryColor,
                        title: Text(
                          "Welcome! HT Sales CRM",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        bottom: TabBar(
                            tabs: _tabs
                                .map((String name) => Tab(
                                        child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    )))
                                .toList()),
                        actions: <Widget>[
                          RaisedButton(
                            padding: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            onPressed: () async => {await syncNow()},
                            child: Row(
                              children: [
                                isSyncing == true
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
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            elevation: 0,
                          ),
                        ],
                        pinned: true,
                        snap: true,
                        floating: true),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  recordingWidget(true),
                  recordingWidget(0),
                ],
              ))),
    );
  }
}
