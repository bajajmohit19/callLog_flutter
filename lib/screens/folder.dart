import 'dart:io';
import 'dart:core';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/providers/category_provider.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:crm/util/file_utils.dart';
import 'package:crm/widgets/file_item.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathlib;
import 'package:provider/provider.dart';
import 'package:crm/database/database.dart';
import 'package:crm/screens/call_logs.dart';

class SyncLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            flexibleSpace: new Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TabBar(
              indicator: BoxDecoration(color: Constants.lightPrimary),
              labelStyle: TextStyle(color: Colors.white),
              unselectedLabelColor: Constants.lightAccent,
              tabs: [
                Tab(icon: Icon(Icons.directions_car)),
                Tab(icon: Icon(Icons.directions_transit)),
              ],
            )
          ],
        )),
        body: TabBarView(
          children: [
            Folder(title: "Calls"),
            CallLogsList(),
          ],
        ),
      ),
    );
  }
}

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
    files.clear();
    Provider.of<CoreProvider>(context, listen: false).getLogs();

    // await Provider.of<CoreProvider>(context, listen: false).getNewFiles();
    // files = Provider.of<CoreProvider>(context, listen: false).dbFiles;
    // setState(() {});
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
        backgroundColor: Theme.of(context).backgroundColor,
        body: Provider.of<CoreProvider>(context, listen: true).loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : files.isEmpty
                ? Center(
                    child: Text("There's nothing here"),
                  )
                : ListView.separated(
                    itemCount: files.length,
                    itemBuilder: (BuildContext context, int index) {
                      dynamic file = files[index];
                      return FileItem(file: file);
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
