import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../Utility.dart';
import '../../bloc/ApplicationBloc.dart';
import '../../bloc/BlocProvider.dart';
import '../widgets/NoDataWidget.dart';
import '../widgets/SongListWidget.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  NavigationOptions _currentNavigationOption;
  SearchBarState _currentSearchBarState;
  TextEditingController _searchController;
  ApplicationBloc bloc;

  static final Map<NavigationOptions, String> _titles = {
    NavigationOptions.ARTISTS: "Artists",
    NavigationOptions.ALBUMS: "Albums",
    NavigationOptions.SONGS: "Songs",
    NavigationOptions.GENRES: "Genres",
    NavigationOptions.PLAYLISTS: "Playlist",
  };

  @override
  void initState() {
    super.initState();
    _currentNavigationOption = NavigationOptions.SONGS;
    _currentSearchBarState = SearchBarState.COLLAPSED;
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    bloc ??= BlocProvider.of<ApplicationBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<SearchBarState>(
            initialData: _currentSearchBarState,
            stream: bloc.searchBarState,
            builder: (context, snapshot) {
              if (snapshot.data == SearchBarState.EXPANDED)
                return TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (typed) {
                    print("make search for: ${_searchController.text}");
                    bloc.search(
                        option: _currentNavigationOption,
                        query: _searchController.text);
                  },
                  style: new TextStyle(
                    color: Colors.white,
                  ),
                  decoration: new InputDecoration(
                      prefixIcon: new Icon(Icons.search, color: Colors.white),
                      hintText: "Search...",
                      hintStyle: new TextStyle(color: Colors.grey)),
                );

              return Text('Sales CRM');
            }),
        actions: <Widget>[
          StreamBuilder<SearchBarState>(
              initialData: _currentSearchBarState,
              stream: bloc.searchBarState,
              builder: (context, snapshot) {
                switch (snapshot.data) {
                  case SearchBarState.EXPANDED:
                    return IconButton(
                        icon: Icon(
                          Icons.close,
                        ),
                        tooltip:
                            "Search for ${_titles[_currentNavigationOption]}",
                        onPressed: () => bloc
                            .changeSearchBarState(SearchBarState.COLLAPSED));
                  default:
                    //case SearchBarState.COLLAPSED:
                    return IconButton(
                        icon: Icon(
                          Icons.search,
                        ),
                        tooltip:
                            "Search for ${_titles[_currentNavigationOption]}",
                        onPressed: () =>
                            bloc.changeSearchBarState(SearchBarState.EXPANDED));
                }
              }),
          StreamBuilder<NavigationOptions>(
              initialData: _currentNavigationOption,
              stream: bloc.currentNavigationOption,
              builder: (context, snapshot) {
                return IconButton(
                  icon: Icon(
                    Icons.sort,
                  ),
                  tooltip: "${_titles[snapshot.data]} Sort Type"
                );
              }),
        ],
      ),
      body: StreamBuilder<NavigationOptions>(
        initialData: _currentNavigationOption,
        stream: bloc.currentNavigationOption,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _currentNavigationOption = snapshot.data;

            return StreamBuilder<List<SongInfo>>(
                stream: bloc.songStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Utility.createDefaultInfoWidget(
                        Text("${snapshot.error}"));

                  if (!snapshot.hasData)
                    return Utility.createDefaultInfoWidget(
                        CircularProgressIndicator());

                  return (snapshot.data.isEmpty)
                      ? NoDataWidget(
                          title: "There is no Songs",
                        )
                      : SongListWidget(songList: snapshot.data);
                });
          }

          return NoDataWidget(
            title: "Something goes wrong!",
          );
        },
      ),
    );
  }

  /// this method returns bottom bar navigator widget layout
}
