import 'dart:async';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import './BlocBase.dart';

enum NavigationOptions { ARTISTS, ALBUMS, SONGS, GENRES, PLAYLISTS }
enum SearchBarState { COLLAPSED, EXPANDED }

class ApplicationBloc extends BlocBase {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  static const List<String> _artistSortNames = [
    "DEFAULT",
    "MORE ALBUMS NUMBER FIRST",
    "LESS ALBUMS NUMBER FIRST",
    "MORE TRACKS NUMBER FIRST",
    "LESS TRACKS NUMBER FIRST"
  ];

  static const List<String> _albumsSortNames = [
    "DEFAULT",
    "ALPHABETIC ARTIST NAME",
    "MORE SONGS NUMBER FIRST",
    "LESS SONGS NUMBER FIRST",
    "MOST RECENT YEAR",
    "OLDEST YEAR"
  ];

  static const List<String> _songsSortNames = [
    "DEFAULT",
    "ALPHABETIC COMPOSER",
    "GREATER DURATION",
    "SMALLER DURATION",
    "RECENT YEAR",
    "OLDEST YEAR",
    "ALPHABETIC ARTIST",
    "ALPHABETIC ALBUM",
    "GREATER TRACK NUMBER",
    "SMALLER TRACK NUMBER",
    "DISPLAY NAME"
  ];

  static const List<String> _genreSortNames = ["DEFAULT"];

  static const List<String> _playlistSortNames = [
    "DEFAULT",
    "NEWEST_FRIST",
    "OLDEST_FIRST"
  ];

  static const Map<NavigationOptions, List<String>> sortOptionsMap = {
    NavigationOptions.SONGS: _songsSortNames
  };

  SongSortType _songSortTypeSelected = SongSortType.DEFAULT;

  // Navigation Stream controler
  final StreamController<NavigationOptions> _navigationController =
      StreamController
          .broadcast(); // BehaviorSubject.seeded(NavigationOptions.ARTISTS);
  Stream<NavigationOptions> get currentNavigationOption =>
      _navigationController.stream;

  //DATA QUERY STREAMS

  final StreamController<SearchBarState> _searchBarController =
      StreamController.broadcast();
  Stream<SearchBarState> get searchBarState => _searchBarController.stream;

  final StreamController<List<SongInfo>> _songController =
      StreamController.broadcast();
  Stream<List<SongInfo>> get songStream => _songController.stream;

  ApplicationBloc() {
    _navigationController.stream.listen(onDataNavigationChangeCallback);
    _navigationController.sink.add(NavigationOptions.SONGS);
  }

  int getLastSortSelectionChooseBasedInNavigation(NavigationOptions option) {
    switch (option) {
      case NavigationOptions.SONGS:
        return _songSortTypeSelected.index;

      default:
        return 0;
    }
  }

  void changeSongSortType(SongSortType type) {
    _songSortTypeSelected = type;
    _fetchSongData();
  }

  void changeNavigation(final NavigationOptions option) =>
      _navigationController.sink.add(option);

  void _fetchSongData({String query}) {
    if (query == null)
      audioQuery
          .getSongs(sortType: _songSortTypeSelected)
          .then((songList) => _songController.sink.add(songList))
          .catchError((error) => _songController.sink.addError(error));
    else
      audioQuery
          .searchSongs(query: query)
          .then((songList) => _songController.sink.add(songList))
          .catchError((error) => _songController.sink.addError(error));
  }

  onDataNavigationChangeCallback(final NavigationOptions option) {
    switch (option) {
      case NavigationOptions.SONGS:
        _fetchSongData();
        break;
    }
  }

  void search({NavigationOptions option, final String query}) {
    switch (option) {
      case NavigationOptions.SONGS:
        _fetchSongData(query: query);
        break;
    }
  }

  void changeSearchBarState(final SearchBarState newState) =>
      _searchBarController.sink.add(newState);

  @override
  void dispose() {
    _navigationController?.close();
    _songController?.close();
    _searchBarController?.close();
  }
}
