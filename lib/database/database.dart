import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crm/database/RecordingsModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

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
          "id INTEGER PRIMARY KEY,"
          "title TEXT,"
          "syncTime CURRENT_TIMESTAMP,"
          "createdAt CURRENT_TIMESTAMP"
          ")");
    });
  }

  addRecordings(List<Recordings> recordings) async {
    final db = await database;
    var buffer = new StringBuffer();
    recordings.forEach((recording) {
      if (buffer.isNotEmpty) {
        buffer.write(",\n");
      }
      buffer.write("('");
      buffer.write(Uuid());
      buffer.write("', '");
      buffer.write(recording.title);
      buffer.write("', '");
      buffer.write(false);
      buffer.write("', '");
      buffer.write(DateTime.now());
      buffer.write("')");
    });
    var raw = await db
        .rawInsert("INSERT Into recordings (id,title,isSynced,createdAt)"
            " VALUES ${buffer.toString()}");
    return raw;
  }

  setRecordingsSync(List<Recordings> recordings) async {
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
}
