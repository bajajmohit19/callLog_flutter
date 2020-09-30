import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/database/CallLogsModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  final uuid = Uuid();
  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "recordings.db");
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE recordings ("
          "id TEXT PRIMARY KEY,"
          "title TEXT UNIQUE,"
          "path TEXT UNIQUE,"
          "isSynced BOOLEAN,"
          "size TEXT,"
          "formatedTime TEXT,"
          "createdAt CURRENT_TIMESTAMP"
          ")");
      await db.execute("CREATE TABLE callLogs ("
          "id TEXT PRIMARY KEY,"
          "dialedNumber TEXT,"
          "formatedDialedNumber TEXT,"
          "isSynced BOOLEAN,"
          "duration INT,"
          "roNumber TEXT,"
          "callingTime TEXT,"
          "createdAt CURRENT_TIMESTAMP,"
          "UNIQUE(dialedNumber, callingTime, duration)"
          ")");
    });
  }

  addRecordings(List<Recordings> recordings) async {
    final db = await database;
    recordings.forEach((recording) async {
      var buffer = new StringBuffer();
      buffer.write("('");
      buffer.write(uuid.v4());
      buffer.write("', '");
      buffer.write(recording.title);
      buffer.write("', '");
      buffer.write(recording.path);
      buffer.write("', '");
      buffer.write(0);
      buffer.write("', '");
      buffer.write(recording.size);
      buffer.write("', '");
      buffer.write(recording.formatedTime);
      buffer.write("', '");
      buffer.write(recording.createdAt);
      buffer.write("')");

      try {
        await db.rawInsert(
            "INSERT Into recordings (id,title,path,isSynced,size,formatedTime,createdAt)"
            " VALUES ${buffer.toString()}");
      } catch (ext) {}
    });
    // if (buffer.length > 0) {
    // var raw = await db.rawInsert(
    // "INSERT Into recordings (id,title,path,isSynced,size,formatedTime,createdAt)"
    // " VALUES ${buffer.toString()}");
    // return raw;
    // }
    return 0;
  }

  listRecordings({bool unsynced = false}) async {
    final db = await database;
    String query = "SELECT * FROM recordings";
    if (unsynced == true) {
      query += " WHERE isSynced=0";
    }
    var res = await db.rawQuery(query);
    List<Recordings> list =
        res.isNotEmpty ? res.map((c) => Recordings.fromMap(c)).toList() : [];
    print(list);
    return list;
  }

  setRecordingsSync(List<dynamic> recordings) async {
    final db = await database;
    List arr = [];
    List ids = [];
    recordings.forEach((recording) {
      // if (buffer.isNotEmpty) {
      //   buffer.write(",\n");
      // }
      arr.add('?');
      ids.add(recording.id);
    });
    var raw = await db.rawUpdate(
        "UPDATE recordings SET isSynced = ?  WHERE id IN (${arr.join(',')})",
        [true, ...ids]);
    return raw;
  }

  addCallLogs(List<CallLogs> callLogs) async {
    final db = await database;
    callLogs.forEach((callLog) async {
      var buffer = new StringBuffer();
      buffer.write("('");
      buffer.write(uuid.v4());
      buffer.write("', '");
      buffer.write(callLog.dialedNumber);
      buffer.write("', '");
      buffer.write(callLog.formatedDialedNumber);
      buffer.write("', '");
      buffer.write(0);
      buffer.write("', '");
      buffer.write(callLog.duration);
      buffer.write("', '");
      buffer.write(callLog.roNumber);
      buffer.write("', '");
      buffer.write(callLog.callingTime);
      buffer.write("', '");
      buffer.write(DateTime.now());
      buffer.write("')");
      await db.rawInsert(
          "INSERT Into callLogs (id,dialedNumber,formatedDialedNumber,isSynced,duration,roNumber,callingTime,createdAt)"
          " VALUES ${buffer.toString()}");
    });
    // if (buffer.length > 0) {
    //   var raw = await db.rawInsert(
    //       "INSERT Into callLogs (id,dialedNumber,formatedDialedNumber,isSynced,duration,callerNumber,callingTime,createdAt)"
    //       " VALUES ${buffer.toString()}");
    //   return raw;
    // }
    return 0;
  }

  setCallLogsSync(List<dynamic> callLogs) async {
    final db = await database;
    List arr = [];
    List ids = [];
    callLogs.forEach((callLog) {
      // if (buffer.isNotEmpty) {
      //   buffer.write(",\n");
      // }
      arr.add('?');
      ids.add(callLog.id);
    });
    var raw = await db.rawUpdate(
        "UPDATE callLogs SET isSynced = ?  WHERE id IN (${arr.join(',')})",
        [true, ...ids]);
    return raw;
  }

  listCallLogs({bool unsynced = false}) async {
    final db = await database;
    String query = "SELECT * FROM callLogs";
    if (unsynced == true) {
      query += " WHERE isSynced=0 LIMIT 5";
    }
    var res = await db.rawQuery(query);
    List<CallLogs> list =
        res.isNotEmpty ? res.map((c) => CallLogs.fromMap(c)).toList() : [];
    return list;
  }

  getlatestDateCallLog() async {
    final db = await database;
    String query = "SELECT * FROM callLogs ORDER BY createdAt DESC LIMIT 1";
    var res = await db.rawQuery(query);
    var resp = res.length > 0 ? CallLogs.fromMap(res.first) : null;
    return resp;
  }

  reset() async {
    final db = await database;
    await db.rawQuery("DELETE FROM callLogs");
    await db.rawQuery("DELETE FROM recordings");
  }
}
