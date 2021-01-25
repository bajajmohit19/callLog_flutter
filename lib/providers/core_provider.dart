import 'package:crm/util/consts.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crm/database/CallLogsModel.dart';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/database/database.dart';
import 'package:http/http.dart' as http;
import 'package:crm/util/file_utils.dart';
import 'package:path/path.dart' as pathlib;
import 'package:call_log/call_log.dart';
import 'package:http_parser/http_parser.dart';

import 'dart:io';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

class CoreProvider extends ChangeNotifier {
  int asyncLimit = 1;
  bool loading = false;
  bool recordLoading = false;
  bool syncGlobalLoader = false;

  // check sync status
  bool _recordingFileSyncing = false;
  bool _recordingSyncing = false;
  bool _callsSyncing = false;

  //recording var
  List<FileSystemEntity> audio = List();
  List<Recordings> dbFiles = List();
  List<CallLogs> dbLogs = List();
  List _syncingFiles = List();
  int _syncedRecord = 0;
  int _unsyncedRecord = 0;

  // Utils

  int get syncedRecord => _syncedRecord;
  int get unsyncedRecord => _unsyncedRecord;
  bool get recordingSyncing => _recordingSyncing;
  bool get callsSyncing => _callsSyncing;
  List get sycingRecord => _syncingFiles;
  DateTime _fromDate = new DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _toDate = new DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;

  void setSyncedcount(value) {
    _syncedRecord = value;
    notifyListeners();
  }

  void setUnsyncedcount(value) {
    _unsyncedRecord = value;
    notifyListeners();
  }

  void setFromDate(value) {
    _fromDate = value;
    notifyListeners();
  }

  void setToDate(value) {
    _toDate = value;
    notifyListeners();
  }

  void setLoading(value) {
    loading = value;
    notifyListeners();
  }

  void setGlobalLoading(value) {
    syncGlobalLoader = value;
    notifyListeners();
  }

  void setRecordingLoading(value) {
    _recordingSyncing = value;
    notifyListeners();
  }

  void setSyncedRecord(value) {
    _syncingFiles = value;
    notifyListeners();
  }

  void setCallLoading(value) {
    _callsSyncing = value;
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

  // Local methods for this component

  List chunk(List list, int chunkSize) {
    List chunks = [];
    int len = list.length;
    for (var i = 0; i < len; i += chunkSize) {
      int size = i + chunkSize;
      chunks.add(list.sublist(i, size > len ? len : size));
    }
    return chunks;
  }

  convertToJsonRec(file) {
    var jsonFile = jsonDecode(recordingsToJson(file));
    String filePath = jsonFile['path'];
    String mimeType = filePath.split('.').last;
    jsonFile['mimeType'] = mimeType;
    return jsonFile;
  }

  Future<dynamic> isCurrentUser() async {
    Map<String, dynamic> userData = new Map();

    final prefs = await SharedPreferences.getInstance();
    var user = prefs.getString('currentUser');
    if (user == null) {
      return false;
    } else {
      userData = jsonDecode(user);
      asyncLimit = userData['asyncLimit'] == null ? 1 : userData['asyncLimit'];
      return userData;
    }
  }

  Future convertAudios(String type, user) async {
    List<String> allowed = ["m4a"];

    setLoading(true);

    List<Directory> storages = await FileUtils.getStorageList();
    for (var dir in storages) {
      String path = dir.path +
          (user['recordingPath'] == null ? "Call" : user['recordingPath']);
      if (Directory(path).existsSync()) {
        List<FileSystemEntity> files =
            FileUtils.getAllFilesInPath(path, showHidden: false);

        for (var file in files) {
          try {
            String ext = file.path.split("/")[file.path.split("/").length - 1];
            ext = ext.split('.')[ext.split(".").length - 1];
            if (allowed.contains(ext)) {
              try {
                await _flutterFFmpeg.execute('-y -i "' +
                    file.path +
                    '" -ar 8000 -ac 1 "' +
                    file.path.split('.').first +
                    '.amr"');
                if (File(file.path).existsSync()) file.delete();
              } catch (e) {}
            }
          } catch (e) {}
        }
      } else {
        print(user['recordingPath'] + " folder doesnt exists");
      }
    }
    setLoading(false);
  }

  getAudios(String type, user) async {
    // await convertAudios(type, user);
    List<String> Allowed = ["mp3", "amr", "mp4", "m4a", "acc"];

    setLoading(true);

    audio.clear();
    List<Directory> storages = await FileUtils.getStorageList();
    storages.forEach((dir) {
      String path = dir.path +
          (user['recordingPath'] == null ? "Call" : user['recordingPath']);
      if (Directory(path).existsSync()) {
        List<FileSystemEntity> files =
            FileUtils.getAllFilesInPath(path, showHidden: false);

        files.forEach((file) {
          try {
            String ext = file.path.split("/")[file.path.split("/").length - 1];
            ext = ext.split('.')[ext.split(".").length - 1];

            if (Allowed.contains(ext)) {
              print(File(file.path).existsSync());
              if (File(file.path).existsSync()) audio.add(file);
            }
          } catch (e) {}
        });
      } else {
        print(user['recordingPath'] + " folder doesnt exists");
      }
    });
    setLoading(false);
  }

  getNewFiles() async {
    // Directory dir = Directory('${path}/Download');
    // setLoading(true);
    dbFiles.clear();
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    await getAudios('audio', user);
    return;
  }

  getLogs() async {
    var latestRecord = await DBProvider.db.getlatestDateCallLog();
    // dynamic tt = DateTime.parse(latestRecord.createAt);
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userData = new Map();

    var user = prefs.getString('currentUser');
    if (user == null) {
      return false;
    } else {
      userData = jsonDecode(user);
    }
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
        'roNumber': userData['mobileNo'],
        'callType': element.callType.toString().split('.')[1],
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

  Stream<dynamic> getAllRecording(unsynced) async* {
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    // if (recordLoading == true) {
    //   return;
    // }
    recordLoading = true;
    await getNewFiles();
    List chunksArr = chunk(audio, 10);
    for (List files in chunksArr) {
      // print(file);
      dbFiles.clear();
      files.forEach((file) {
        var title = pathlib.basename(file.path);
        var time = new File(file.path).lastModifiedSync();
        dbFiles.add(recordingsFromJson({
          'title': title,
          'path': file.path,
          'isSynced': false,
          'createdAt': time,
          'size': FileUtils.formatBytes(
              file == null ? 678476 : File(file.path).lengthSync(), 2),
          'formatedTime': file == null
              ? "Test"
              : FileUtils.formatTime(
                  File(file.path).lastModifiedSync().toIso8601String()),
          'roNumber': user['mobileNo']
        }));
      });
      try {
        await DBProvider.db.addRecordings(dbFiles);
      } catch (e) {}
      List<Recordings> recordings = await DBProvider.db.listRecordings(
          unsynced: unsynced, fromDate: _fromDate, toDate: _toDate);
      if (unsynced == true) {
        setUnsyncedcount(recordings.length);
      } else {
        setSyncedcount(recordings.length);
      }
      yield recordings;
    }
    recordLoading = false;
    return;
  }

  // getAllRecording(unsynced) async {
  //   var user = await isCurrentUser();
  //   if (user == false) {
  //     return;
  //   }
  //   await getNewFiles();
  //   List<Recordings> recordings = await DBProvider.db.listRecordings(
  //       unsynced: unsynced, fromDate: _fromDate, toDate: _toDate);
  //   return recordings;
  // }

  getAllCallLogs(unsynced) async {
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    await getLogs();
    List<CallLogs> callLogs = await DBProvider.db
        .listCallLogs(unsynced: unsynced, fromDate: _fromDate, toDate: _toDate);
    return callLogs;
  }

  //Sync Recording Files Methods

  syncSingleRecording(file, user) async {
    if (_recordingFileSyncing == true || _recordingSyncing == true) {
      return;
    }
    // user = jsonDecode(user)["token"];

    var item = jsonDecode(recordingsToJson(file));
    String filePath = item['path'];
    String mimeType = filePath.split('.').last;
    setSyncedRecord(List.filled(1, item['id']));
    _recordingFileSyncing = true;
    var request = http.MultipartRequest(
        "POST", new Uri.https(Constants.apiUrl, "/sync/audio"));

    request.headers['Content-Encoding'] = "audio/mpeg";
    request.headers['Authorization'] = 'Bearer ${user["token"]}';
    request.files.add(http.MultipartFile.fromBytes(
        'file', new File(item['path']).readAsBytesSync(),
        contentType: MediaType('audio', mimeType), filename: item['id']));
    var response = await request.send();
    // print(response);
    if (response.statusCode == 200) {
      print('Uploaded!');
      item['mimeType'] = mimeType;
      var dataResponse = await http.post(
          new Uri.https(Constants.apiUrl, "/sync/recordings"),
          body: jsonEncode({'arr': List.filled(1, item).toList()}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": 'Bearer ${user['token']}'
          });

      if (dataResponse.statusCode == 200) {
        var data = jsonDecode(dataResponse.body)['data'] as List;
        List<Recordings> ids =
            data.map((json) => new Recordings(id: json['id'])).toList();

        await DBProvider.db.setRecordingsSync(ids);
        setSyncedRecord(List());
        _recordingFileSyncing = false;
        return true;
      } else {
        setSyncedRecord(List());
        _recordingFileSyncing = false;
        return false;
      }
    } else {
      setSyncedRecord(List());
      _recordingFileSyncing = false;
      return false;
    }
  }

  syncMultipleRecording(files, user) async {
    // user = jsonDecode(user)["token"];
    var request = http.MultipartRequest(
        "POST", new Uri.https(Constants.apiUrl, "/sync/audios"));

    request.headers['Content-Encoding'] = "audio/mpeg";
    request.headers['Authorization'] = 'Bearer ${user["token"]}';
    // request.fields["data"] = jsonEncode(item);
    for (var file in files) {
      request.files.add(http.MultipartFile.fromBytes(
          'file', new File(file['path']).readAsBytesSync(),
          contentType: MediaType('audio', file['mimeType']),
          filename: file['id']));
    }

    var response = await request.send();
    // print(response);
    if (response.statusCode == 200) {
      print('Files chunk uploaded!');

      var dataResponse = await http.post(
          new Uri.https(Constants.apiUrl, "/sync/recordings"),
          body: jsonEncode({'arr': files.toList()}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": 'Bearer ${user['token']}'
          });

      if (dataResponse.statusCode == 200) {
        var data = jsonDecode(dataResponse.body)['data'] as List;
        List<Recordings> ids =
            data.map((json) => new Recordings(id: json['id'])).toList();

        await DBProvider.db.setRecordingsSync(ids);
        return true;
      } else
        return false;
    } else
      return false;
  }

  // Methods for states

  Stream<dynamic> syncRecordings() async* {
    if (_recordingSyncing == true) {
      return;
    }
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    setRecordingLoading(true);
    await getNewFiles();
    List<Recordings> recordings = await DBProvider.db
        .listRecordings(unsynced: true, fromDate: _fromDate, toDate: _toDate);

    print('are we here');
    List chunksArr = chunk(recordings, asyncLimit);
    var index = 0;
    for (List files in chunksArr) {
      // print(file);
      var filesJson = files.map((file) => convertToJsonRec(file));
      setSyncedRecord(filesJson.map((file) => file['id']).toList());
      await syncMultipleRecording(filesJson, user);
      yield index;
      index++;
    }
    setRecordingLoading(false);
    setSyncedRecord(List());
    yield false;
  }

  syncCallLogs() async {
    if (_callsSyncing == true) {
      return;
    }
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    setCallLoading(true);
    await getLogs();
    List<CallLogs> callLogs = List();
    List list = List();
    var isEmpty = false;
    while (isEmpty == false) {
      callLogs = await DBProvider.db
          .listCallLogs(unsynced: true, fromDate: _fromDate, toDate: _toDate);
      if (callLogs.isEmpty == true) {
        isEmpty = true;
      }
      list.clear();
      callLogs.forEach((e) {
        list.add(callLogsToJson(e));
      });
      var body = jsonEncode({"arr": list});

      var response = await http.post(
          new Uri.https(Constants.apiUrl, "/sync/callLogs"),
          body: body,
          headers: {
            "Content-Type": "application/json",
            "Authorization": 'Bearer ${user['token']}'
          });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['data'] as List;
        List<CallLogs> ids =
            data.map((json) => new CallLogs(id: json['id'])).toList();

        DBProvider.db.setCallLogsSync(ids);
        setCallLoading(false);
        return true;
      } else {
        setCallLoading(false);
        return false;
      }
    }

    return true;
  }
}
