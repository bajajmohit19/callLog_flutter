import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:call_log/call_log.dart';
import 'package:crm/database/database.dart';
import 'package:crm/database/CallLogsModel.dart';

class CallLogsList extends StatefulWidget {
  @override
  _CallLogsListState createState() => _CallLogsListState();
}

class _CallLogsListState extends State<CallLogsList> {
  Iterable<CallLogEntry> _callLogEntries = [];

  @override
  Widget build(BuildContext context) {
    var mono = TextStyle(fontFamily: 'monospace');
    var children = <Widget>[];
    _callLogEntries.forEach((entry) {
      children.add(
        Column(
          children: <Widget>[
            Divider(),
            Text('F. NUMBER  : ${entry.formattedNumber}', style: mono),
            Text('C.M. NUMBER: ${entry.cachedMatchedNumber}', style: mono),
            Text('NUMBER     : ${entry.number}', style: mono),
            Text('NAME       : ${entry.name}', style: mono),
            Text('TYPE       : ${entry.callType}', style: mono),
            Text(
                'DATE       : ${DateTime.fromMillisecondsSinceEpoch(entry.timestamp)}',
                style: mono),
            Text('DURATION   :  ${entry.duration}', style: mono),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
        ),
      );
    });

    var now = DateTime.now();
    int from = now.subtract(Duration(days: 7)).millisecondsSinceEpoch;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                onPressed: () async {
                  var result = await CallLog.query(dateFrom: from);
                  List<CallLogs> logs = List();
                  result.forEach((element) {
                    logs.add(callLogsFromJson({
                      'dialedNumber': element.number,
                      'formatedDialedNumber': element.formattedNumber,
                      'isSynced': false,
                      'duration': element.duration,
                      'callingTime': new DateTime.fromMillisecondsSinceEpoch(
                          element.timestamp),
                      'createdAt': new DateTime.now()
                    }));
                  });
                  DBProvider.db.addCallLogs(logs);
                  setState(() {
                    _callLogEntries = result;
                  });
                },
                child: Text("Get all"),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
