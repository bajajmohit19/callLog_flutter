import 'dart:io';
import 'dart:core';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/providers/category_provider.dart';
import 'package:crm/util/file_utils.dart';
import 'package:crm/widgets/file_item.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathlib;
import 'package:provider/provider.dart';
import 'package:crm/database/database.dart';

class Folder extends StatefulWidget {
  final String title;
  final String path;

  Folder({
    Key key,
    @required this.title,
    @required this.path,
  }) : super(key: key);

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<Folder> with WidgetsBindingObserver {
  String path;
  List<String> paths = List();
  List<Recordings> listDb = List();
  List<dynamic> files = List();
  bool showHidden = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getFiles();
    }
  }

  getFiles() async {
    // Directory dir = Directory('${path}/Download');
    await Provider.of<CategoryProvider>(context, listen: false)
        .getAudios('audio');
    List<FileSystemEntity> l =
        Provider.of<CategoryProvider>(context, listen: false).audio;
    files.clear();
    setState(() {
      showHidden = false;
    });
    for (FileSystemEntity file in l) {
      if (!showHidden) {
        if (!pathlib.basename(file.path).startsWith(".")) {
          setState(() {
            files.add(file);
          });
        }
      } else {
        setState(() {
          files.add(file);
        });
      }
    }
    List<Recordings> recordings = [];
    listDb = await DBProvider.db.listRecordings();
    files.forEach((element) {
      var title = pathlib.basename(element.path);
      recordings.add(recordingsFromJson({
        'title': title,
        'isSynced': false,
        'createdAt': new DateTime.now()
      }));
    });
    DBProvider.db.addRecordings(recordings);
    files = FileUtils.sortList(
        files, Provider.of<CategoryProvider>(context, listen: false).sort);
//    files.sort((f1, f2) => pathlib.basename(f1.path).toLowerCase().compareTo(pathlib.basename(f2.path).toLowerCase()));
//    files.sort((f1, f2) => f1.toString().split(":")[0].toLowerCase().compareTo(f2.toString().split(":")[0].toLowerCase()));
//    files.sort((f1, f2) => FileSystemEntity.isDirectorySync(f1.path) ==
//        FileSystemEntity.isDirectorySync(f2.path)
//        ? 0
//        : 1);
  }

  @override
  void initState() {
    super.initState();
    path = widget.path;
    getFiles();
    paths.add(widget.path);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (paths.length == 1) {
          return true;
        } else {
          paths.removeLast();
          setState(() {
            path = paths.last;
          });
          getFiles();
          return false;
        }
      },
      child: Scaffold(
        body: files.isEmpty
            ? Center(
                child: Text("There's nothing here"),
              )
            : ListView.separated(
                padding: EdgeInsets.only(left: 20),
                itemCount: files.length,
                itemBuilder: (BuildContext context, int index) {
                  FileSystemEntity file = files[index];
                  var dbElement = listDb.length > 0
                      ? listDb.firstWhere((dropdown) =>
                          dropdown.title == pathlib.basename(file.path))
                      : false;
                  return FileItem(
                      file: file, isSynced: dbElement == false ? false : true);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                          width: MediaQuery.of(context).size.width - 70,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
