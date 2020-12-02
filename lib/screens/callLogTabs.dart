import 'package:crm/providers/core_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:crm/screens/login.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class CallLogsTabScreen extends StatefulWidget {
  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<CallLogsTabScreen> {
  String user;
  int syncedCount = 0;
  int unsyncedCount = 0;
  List callLogs = [];
  List<bool> _isFileSyncing = List.filled(1, false);
  bool isSyncing = false;
  // int _currentIndex = 0;
  // final List<Widget> _children = [];
  Map<String, dynamic> userData = new Map();

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

  getCallLogs(unsynced) async {
    callLogs = await CoreProvider().getAllCallLogs(unsynced);

    if (unsynced == true
        ? unsyncedCount != callLogs.length
        : syncedCount != callLogs.length)
      setState(() {
        unsynced == true
            ? unsyncedCount = callLogs.length
            : syncedCount = callLogs.length;
      });
    return callLogs;
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours) == '00' ? '' : twoDigits(duration.inHours) + ':'}$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget callLogWidget(unsynced) {
    return FutureBuilder(
      future: getCallLogs(unsynced),
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
                            leading: Icon(userSnap.data[index].callType ==
                                    'missed'
                                ? Icons.call_missed
                                : userSnap.data[index].callType == 'outgoing'
                                    ? Icons.call_made
                                    : userSnap.data[index].callType ==
                                            'incoming'
                                        ? Icons.call_received
                                        : userSnap.data[index].callType ==
                                                'blocked'
                                            ? Icons.block
                                            : Icons.call_end),
                            // title: Text(userSnap.data[index].title,
                            //     style: TextStyle(fontSize: 20)),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(userSnap.data[index].dialedNumber),
                                Text(
                                    DateFormat('dd/MM/yyyy hh:mm').format(
                                        userSnap.data[index].callingTime),
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(children: [
                                  Text(
                                      _printDuration(Duration(
                                          seconds:
                                              userSnap.data[index].duration)),
                                      style: TextStyle(fontSize: 12)),
                                ]),
                              ],
                            ),
                            contentPadding:
                                EdgeInsets.only(top: 15, left: 15, right: 15),
                            dense: false,
                          ),
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
                        expandedHeight: 0,
                        floating: true),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  callLogWidget(true),
                  callLogWidget(false),
                ],
              ))),
    );
  }
}
