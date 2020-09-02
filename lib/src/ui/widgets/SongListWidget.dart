import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../Utility.dart';
import './ListItemWidget.dart';
import './NoDataWidget.dart';

class SongListWidget extends StatelessWidget {
  final List<SongInfo> songList;
  final String _dialogTitle = "Choose Playlist";
  final bool addToPlaylistAction;

  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  SongListWidget({@required this.songList, this.addToPlaylistAction = true});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: songList.length,
        itemBuilder: (context, songIndex) {
          SongInfo song = songList[songIndex];
          return ListItemWidget(
              title: Text("${song.title}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text("Artist: ${song.artist}"),
                  Text(
                    "Duration: ${Utility.parseToMinutesSeconds(int.parse(song.duration))}",
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              imagePath: song.albumArtwork,
              leading: (song.albumArtwork == null)
                  ? FutureBuilder<Uint8List>(
                      future: audioQuery.getArtwork(
                          type: ResourceType.SONG,
                          id: song.id,
                          size: Size(100, 100)),
                      builder: (_, snapshot) {
                        if (snapshot.data == null)
                          return CircleAvatar(
                            child: CircularProgressIndicator(),
                          );

                        if (snapshot.data.isEmpty)
                          return CircleAvatar(
                            backgroundImage: AssetImage("assets/no_cover.png"),
                          );

                        return CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: MemoryImage(
                            snapshot.data,
                          ),
                        );
                      })
                  : null);
        });
  }
}
