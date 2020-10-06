import 'dart:convert';

Recordings recordingsFromJson(jsonData) {
  return Recordings.fromMap(jsonData);
}

String recordingsToJson(Recordings data) {
  var dyn = data.toMap();
  dyn.forEach((key, value) {
    if (value is DateTime) {
      dyn[key] = value.toString();
    }
  });
  return json.encode(dyn);
}

class Recordings {
  String id;
  String title;
  String path;
  bool isSynced;
  String size;
  String formatedTime;
  String roNumber;
  DateTime createdAt;

  Recordings(
      {this.id,
      this.title,
      this.path,
      this.isSynced,
      this.size,
      this.formatedTime,
      this.roNumber,
      this.createdAt});

  factory Recordings.fromMap(Map<String, dynamic> json) => new Recordings(
      id: json["id"],
      title: json["title"],
      path: json['path'],
      isSynced: json["isSynced"] == 1,
      size: json["size"],
      formatedTime: json["formatedTime"],
      roNumber: json["roNumber"],
      createdAt: DateTime.parse(json["createdAt"].toString()));

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "path": path,
        "isSynced": isSynced,
        "size": size,
        "formatedTime": formatedTime,
        "roNumber": roNumber,
        "createdAt": createdAt
      };
}
