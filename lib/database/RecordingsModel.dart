import 'dart:convert';

Recordings recordingsFromJson(jsonData) {
  return Recordings.fromMap(jsonData);
}

String recordingsToJson(Recordings data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Recordings {
  String id;
  String title;
  bool isSynced;
  DateTime createdAt;

  Recordings({this.id, this.title, this.isSynced, this.createdAt});

  factory Recordings.fromMap(Map<String, dynamic> json) => new Recordings(
        id: json["id"],
        title: json["title"],
        isSynced: json["isSynced"] == 0,
        createdAt: DateTime.parse(json["createdAt"].toString()),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "isSynced": isSynced,
        "createdAt": createdAt,
      };
}
