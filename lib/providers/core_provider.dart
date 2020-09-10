import 'package:crm/util/consts.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crm/database/CallLogsModel.dart';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/database/database.dart';
import 'package:http/http.dart' as http;
import 'package:crm/util/file_utils.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as pathlib;
import 'package:call_log/call_log.dart';

import 'dart:io';
import 'dart:convert';

class CoreProvider extends ChangeNotifier {
  bool loading = false;
  bool globalLoader = false;
  // check sync status
  bool recordingSyncing = false;
  bool callsSyncing = false;
  //recording var
  List<FileSystemEntity> audio = List();
  List<Recordings> dbFiles = List();
  // call logs var
  // Iterable<CallLogEntry> _callLogEntries = [];
  List<CallLogs> dbLogs = List();

  void setLoading(value) {
    loading = value;
    notifyListeners();
  }

  void setGlobalLoading(value) {
    globalLoader = value;
    notifyListeners();
  }

  void showToast(value) {
    Fluttertoast.showToast(
      msg: value,
      toastLength: Toast.LENGTH_SHORT,
      timeInSecForIos: 1,
    );
    notifyListeners();
  }

  syncRecordings() async {
    if (recordingSyncing == true) {
      return;
    }
    recordingSyncing = true;
    await getNewFiles();
    List<Recordings> recordings =
        await DBProvider.db.listRecordings(unsynced: true);

    List list = List();

    recordings.forEach((e) {
      list.add(recordingsToJson(e));
    });

    // http request
    var body = jsonEncode({"arr": list});

    var response = await http.post(
        new Uri.http(Constants.apiUrl, "/sync/recordings"),
        body: body,
        headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'] as List;
      List<Recordings> ids =
          data.map((json) => new Recordings(id: json['id'])).toList();

      DBProvider.db.setRecordingsSync(ids);
    }
    recordingSyncing = false;
  }

  syncCallLogs() async {
    if (callsSyncing == true) {
      return;
    }
    callsSyncing = true;
    await getLogs();
    List<CallLogs> callLogs = await DBProvider.db.listCallLogs(unsynced: true);
    List list = List();
    callLogs.forEach((e) {
      list.add(callLogsToJson(e));
    });
    var body = jsonEncode({"arr": list});

    var response = await http.post(
        new Uri.http(Constants.apiUrl, "/sync/callLogs"),
        body: body,
        headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'] as List;
      List<CallLogs> ids =
          data.map((json) => new CallLogs(id: json['id'])).toList();

      DBProvider.db.setCallLogsSync(ids);
    } else {}
    callsSyncing = false;
  }

  getAudios(String type) async {
    // setLoading(true);
    audio.clear();
    List<Directory> storages = await FileUtils.getStorageList();
    storages.forEach((dir) {
      String path = dir.path + "Download";
      if (Directory(path).existsSync()) {
        List<FileSystemEntity> files =
            FileUtils.getAllFilesInPath(path, showHidden: false);
        files.forEach((file) {
          String mimeType = mime(file.path);
          if (mimeType != null) {
            if (mimeType.split("/")[0] == type) {
              audio.add(file);
            }
          }
        });
      }
    });
    setLoading(false);
  }

  getNewFiles() async {
    // Directory dir = Directory('${path}/Download');
    // setLoading(true);
    dbFiles.clear();
    await getAudios('audio');
    for (FileSystemEntity file in audio) {
      var title = pathlib.basename(file.path);

      dbFiles.add(recordingsFromJson({
        'title': title,
        'path': file.path,
        'isSynced': false,
        'createdAt': new DateTime.now(),
        'size': FileUtils.formatBytes(
            file == null ? 678476 : File(file.path).lengthSync(), 2),
        'formatedTime': file == null
            ? "Test"
            : FileUtils.formatTime(
                File(file.path).lastModifiedSync().toIso8601String()),
      }));
    }
    try {
      await DBProvider.db.addRecordings(dbFiles);
    } catch (exception) {}
  }

  getLogs() async {
    var latestRecord = await DBProvider.db.getlatestDateCallLog();
    // dynamic tt = DateTime.parse(latestRecord.createAt);
    dbLogs.clear();
    var now = latestRecord == null
        ? DateTime.now().subtract(Duration(days: 7))
        : latestRecord.createdAt;
    // tt = tt.millisecondsSinceEpoch;
    int from = now.millisecondsSinceEpoch;
    var result = await CallLog.query(dateFrom: from);
    result.forEach((element) {
      dbLogs.add(callLogsFromJson({
        'dialedNumber': element.number,
        'formatedDialedNumber': element.formattedNumber,
        'isSynced': false,
        'duration': element.duration,
        'callingTime':
            new DateTime.fromMillisecondsSinceEpoch(element.timestamp),
        'createdAt': new DateTime.now()
      }));
    });
    try {
      await DBProvider.db.addCallLogs(dbLogs);
    } catch (e) {}

    return 0;
  }
}
