import 'dart:convert';

CallLogs callLogsFromJson(jsonData) {
  return CallLogs.fromMap(jsonData);
}

String callLogsToJson(CallLogs data) {
  var dyn = data.toMap();
  dyn.forEach((key, value) {
    if (value is DateTime) {
      dyn[key] = value.toString();
    }
  });
  return json.encode(dyn);
}

class CallLogs {
  String id;
  String dialedNumber;
  String formatedDialedNumber;
  bool isSynced;
  int duration;
  String roNumber;
  DateTime callingTime;
  DateTime createdAt;

  CallLogs(
      {this.id,
      this.dialedNumber,
      this.formatedDialedNumber,
      this.isSynced,
      this.duration,
      this.roNumber,
      this.callingTime,
      this.createdAt});

  factory CallLogs.fromMap(Map<String, dynamic> json) => new CallLogs(
      id: json["id"],
      dialedNumber: json["dialedNumber"],
      formatedDialedNumber: json['formatedDialedNumber'],
      isSynced: json["isSynced"] == 1,
      duration: json["duration"],
      roNumber: json["roNumber"],
      callingTime: DateTime.parse(json["callingTime"].toString()),
      createdAt: DateTime.parse(json["createdAt"].toString()));

  Map<String, dynamic> toMap() => {
        "id": id,
        "dialedNumber": dialedNumber,
        "formatedDialedNumber": formatedDialedNumber,
        "isSynced": isSynced,
        "duration": duration,
        "roNumber": roNumber,
        "callingTime": callingTime,
        "createdAt": createdAt
      };
}
