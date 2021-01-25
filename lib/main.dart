import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:crm/util/consts.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'package:crm/screens/splash.dart';
import 'package:wakelock/wakelock.dart';

const sync = 'sync';

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    switch (task) {
      case sync:
        debugPrint('Syncing Start...');
        // CoreProvider().syncRecordings();
        // CoreProvider().syncCallLogs();

        break;
    }
    return Future.value(true);

    //Return true when the task executed successfully or not
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager.initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager.registerPeriodicTask("1", sync, frequency: Duration(minutes: 15));
  Wakelock.enable();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => CoreProvider())
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // final ApplicationBloc bloc = ApplicationBloc();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (BuildContext context, AppProvider appProvider, Widget child) {
        return MaterialApp(
          key: appProvider.key,
          debugShowCheckedModeBanner: false,
          navigatorKey: appProvider.navigatorKey,
          title: Constants.appName,
          theme: appProvider.theme,
          home: Splash(),
        );
      },
    );
  }
}
