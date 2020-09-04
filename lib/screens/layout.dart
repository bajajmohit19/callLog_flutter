import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm/screens/folder.dart';

class Browse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CoreProvider>(
      builder: (BuildContext context, CoreProvider coreProvider, Widget child) {
        return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              title: Text(
                "${Constants.appName}",
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  tooltip: "Sync",
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  onPressed: () {
                    // add sync method here for api suncing
                  },
                  icon: Icon(Icons.sync),
                )
              ],
            ),
            body: coreProvider.loading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Folder(title: 'Device'));
      },
    );
  }
}
