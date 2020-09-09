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

import 'dart:io';
import 'dart:convert';

class CoreProvider extends ChangeNotifier {
  bool loading = false;
  bool globalLoader = false;
  List<FileSystemEntity> audio = List();
  List<Recordings> files = List();

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
    if (globalLoader == true) {
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
    setGlobalLoading(true);
    var response = await http.post(
        new Uri.http(Constants.apiUrl, "/sync/recordings"),
        body: body,
        headers: {"Content-Type": "application/json"});
    setGlobalLoading(false);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'] as List;
      List<Recordings> ids =
          data.map((json) => new Recordings(id: json['id'])).toList();

      DBProvider.db.setRecordingsSync(ids);
    } else {}
  }

  syncCallLogs() async {
    if (globalLoader == true) {
      return;
    }
    List<CallLogs> callLogs = await DBProvider.db.listCallLogs(unsynced: true);
    List list = List();
    callLogs.forEach((e) {
      list.add(callLogsToJson(e));
    });
    var body = jsonEncode({"arr": list});
    // Await the http get response, then decode the json-formatted response.
    setGlobalLoading(true);
    var response = await http.post(
        new Uri.http(Constants.apiUrl, "/sync/callLogs"),
        body: body,
        headers: {"Content-Type": "application/json"});
    setGlobalLoading(false);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['data'] as List;
      List<CallLogs> ids =
          data.map((json) => new CallLogs(id: json['id'])).toList();

      DBProvider.db.setCallLogsSync(ids);
    } else {}
  }

  getAudios(String type) async {
    setLoading(true);
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
    setLoading(true);
    files.clear();
    await getAudios('audio');
    for (FileSystemEntity file in audio) {
      var title = pathlib.basename(file.path);

      files.add(recordingsFromJson({
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
      await DBProvider.db.addRecordings(files);
    } catch (exception) {}
    // files = await DBProvider.db.listRecordings();
    files = files.reversed.toList();
    // DBProvider.db.setRecordingsSync();
    // setState(() {});
    setLoading(false);
  }
}
