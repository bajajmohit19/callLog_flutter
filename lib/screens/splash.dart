import 'dart:async';
import 'package:crm/screens/syncScreen.dart';
import 'package:crm/util/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:crm/screens/login.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:crm/providers/core_provider.dart';
import 'package:provider/provider.dart';

// class UserObj {
//   String user_id;
//   String mobileNo;
//   String token;

//   UserObj({this.user_id, this.mobileNo, this.token});

//   toJSONEncodable() {
//     Map<String, dynamic> m = new Map();
//     m['user_id'] = user_id;
//     m['mobileNo'] = mobileNo;
//     m['token'] = token;
//     return jsonEncode(m);
//   }
// }

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  startTimeout() {
    return Timer(Duration(seconds: 2), handleTimeout);
  }

  void handleTimeout() {
    changeScreen();
  }

  changeScreen() async {
    final prefs = await SharedPreferences.getInstance();

    //  UserObj user = UserObj()
    //   ..mobileNo = "8607771366"
    //   ..token = "asdfjkhsdajkfh kajshdfjkasdh fjkhasddjkfh asjkdhffjksadhdfjkhsadjkfhasjkdfhjksadh fjkashfdjk"
    //   ..user_id = "asdfjhsafdjhsajkfh";

    //   prefs.setString('currentUser', user.toJSONEncodable());

    String xx = prefs.getString('currentUser');
    if (xx == null) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: Login(),
        ),
      );
    }
    // Map<String, dynamic> user2 = jsonDecode(xx);

    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permission != PermissionStatus.granted) {
      PermissionHandler()
          .requestPermissions([PermissionGroup.storage, PermissionGroup.phone])
          .then((v) {})
          .then((v) async {
            PermissionStatus permission1 = await PermissionHandler()
                .checkPermissionStatus(PermissionGroup.storage);
            if (permission1 == PermissionStatus.granted) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: SyncScreen(),
                  ),
                );
              }
            }
          });
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            child: SyncScreen(),
          ),
        );
      }
    }

    return;
  }

  @override
  void initState() {
    super.initState();
    // startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    changeScreen();
    return Consumer<CoreProvider>(
      builder: (BuildContext context, CoreProvider coreProvider, Widget child) {
        return Scaffold(
          body: LoadingOverlay(
              child: Center(
                child: Column(
                  // mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Feather.folder,
                      color: Theme.of(context).accentColor,
                      size: 70,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "${Constants.appName}",
                      style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              isLoading: coreProvider.syncGlobalLoader),
        );
      },
    );
  }
}
