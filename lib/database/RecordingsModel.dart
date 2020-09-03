import 'dart:convert';

Recordings recordingsFromJson(String str) {
  final jsonData = json.decode(str);
  return Recordings.fromMap(jsonData);
}

String recordingsToJson(Recordings data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Recordings {
  int id;
  String title;
  bool isSynced;
  DateTime createdAt;

  Recordings({
    this.id,
    this.title,
    this.isSynced,
    this.createdAt
  });

  factory Recordings.fromMap(Map<String, dynamic> json) => new Recordings(
        id: json["id"],
        title: json["title"],
        isSynced: json["isSynced"] == 0,
        createdAt: json["createdAt"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "isSynced": isSynced,
        "createdAt": createdAt,
      };
}