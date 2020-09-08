import 'dart:convert';
import 'dart:async';

import 'package:crm/database/CallLogsModel.dart';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:crm/database/database.dart';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';

class SyncScreen extends StatefulWidget {
  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  // 15 minutes

  // call_logs phone calls sync -- database
  // call recording sync -- automatic .. Download -- Name
  // SMS sync
  syncRecordings() async {
    var check = Provider.of<CoreProvider>(context, listen: false).globalLoader;
    if (check == true) {
      return;
    }
    List<Recordings> recordings =
        await DBProvider.db.listRecordings(unsynced: true);
    List list = List();
    recordings.forEach((e) {
      list.add(recordingsToJson(e));
    });
    var body = jsonEncode({"arr": list});
    // Await the http get response, then decode the json-formatted response.
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(true);
    var response = await http.post(
        new Uri.http("192.168.43.97:8083", "/sync/recordings"),
        body: body,
        headers: {"Content-Type": "application/json"});
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(false);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'] as List;
      List<Recordings> ids =
          data.map((json) => new Recordings(id: json['id'])).toList();

      DBProvider.db.setRecordingsSync(ids);
    } else {}
  }

  syncCallLogs() async {
    var check = Provider.of<CoreProvider>(context, listen: false).globalLoader;
    if (check == true) {
      return;
    }
    List<CallLogs> callLogs = await DBProvider.db.listCallLogs(unsynced: true);
    List list = List();
    callLogs.forEach((e) {
      list.add(callLogsToJson(e));
    });
    var body = jsonEncode({"arr": list});
    // Await the http get response, then decode the json-formatted response.
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(true);
    var response = await http.post(
        new Uri.http("192.168.43.97:8083", "/sync/callLogs"),
        body: body,
        headers: {"Content-Type": "application/json"});
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(false);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'] as List;
      List<CallLogs> ids =
          data.map((json) => new CallLogs(id: json['id'])).toList();

      DBProvider.db.setCallLogsSync(ids);
    } else {}
  }

  @override
  void initState() {
    super.initState();
    // syncing timer
    Timer.periodic(new Duration(minutes: 1), (timer) {
      syncRecordings();
      syncCallLogs();
      debugPrint(timer.tick.toString());
    });

    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // hello world // last sync
  }
}
