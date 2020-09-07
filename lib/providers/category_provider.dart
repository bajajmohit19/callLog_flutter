import 'dart:io';

import 'package:crm/util/file_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:mime_type/mime_type.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider();

  bool loading = false;
  List<FileSystemEntity> audio = List();
  List<String> audioTabs = List();

  bool showHidden = false;
  int sort = 0;

  getAudios(String type) async {
    setLoading(true);
    audio.clear();
    List<Directory> storages = await FileUtils.getStorageList();
    storages.forEach((dir) {
      String path = dir.path + "Call";
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

  void setLoading(value) {
    loading = value;
    // notifyListeners();
  }
}
