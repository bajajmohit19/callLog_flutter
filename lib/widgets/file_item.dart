import 'package:crm/widgets/file_icon.dart';
// import 'package:crm/widgets/file_popup.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class FileItem extends StatelessWidget {
  final dynamic file;
  final isSynced;

  FileItem({
    Key key,
    @required this.file,
    this.isSynced,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () => OpenFile.open(file.path),
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        leading: FileIcon(
          file: file,
        ),
        title: Text(
          "${file.title}",
          style: TextStyle(
            fontSize: 14,
          ),
          maxLines: 2,
        ),
        subtitle: Text(
          "${file.size},"
          " ${file.formatedTime}",
        ),
        trailing: file.isSynced
            ? Icon(
                Icons.sync,
                color: Colors.green,
              )
            : Icon(Icons.sync_problem));
  }
}
