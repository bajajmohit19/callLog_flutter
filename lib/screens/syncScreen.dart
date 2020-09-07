import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';

class SyncScreen extends StatefulWidget {
  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {

  // 15 minutes

  // call_logs phone calls sync -- database
  // call recording sync -- automatic .. Download -- Name
  // SMS sync

  @override
  Widget build(BuildContext context) {
    return Container(); // hello world // last sync
  }
}
