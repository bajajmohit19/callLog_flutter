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
    this.path,
  }) : super(key: key);

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<Folder> with WidgetsBindingObserver {
  String path;
  List<String> paths = List();
  List<Recordings> files = List();
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
    files = await DBProvider.db.listRecordings();
    setState(() {});
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
                itemCount: files.length,
                itemBuilder: (BuildContext context, int index) {
                  dynamic file = files[index];

                  return Ink(
                      color: file.isSynced == true
                          ? Color.fromRGBO(217, 247, 190, 1)
                          : Color.fromRGBO(255, 204, 199, 1),
                      child: FileItem(file: file));
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
