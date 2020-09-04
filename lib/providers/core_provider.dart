import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CoreProvider extends ChangeNotifier {
  bool loading = false;

  void setLoading(value) {
    loading = value;
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
}
