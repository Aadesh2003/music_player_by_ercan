// ignore_for_file: use_key_in_widget_constructors, always_specify_types, sort_child_properties_last, prefer_final_fields, prefer_single_quotes, avoid_print, always_declare_return_types, unnecessary_string_interpolations, no_duplicate_case_values, prefer_const_constructors
// ignore_for_file: must_be_immutable
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:music_player_by_ercan/artist_page.dart';
import 'package:music_player_by_ercan/album_page.dart';
import 'package:music_player_by_ercan/screens/favorite_screen.dart';
import 'package:music_player_by_ercan/models/playlist_model.dart';
import 'package:music_player_by_ercan/prefrences/playlist_pref.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_by_ercan/now_playing_builder.dart';

import '../prefrences/favorite_pref.dart';

class PlayListInnerScreen extends StatefulWidget {
  late List<SongModel> _songs = <SongModel>[];
  final List<ArtistModel> _artists;
  final List<AlbumModel> _albums;
  List<PlayListDataModel> playListsData;

  String title;

  PlayListInnerScreen(this._songs, this._artists, this._albums, this.title,this.playListsData);

  static int currentSongIndex = 0;

  @override
  _PlayListInnerScreenState createState() => _PlayListInnerScreenState();
}

class _PlayListInnerScreenState extends State<PlayListInnerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<SongModel> _originalSongs = <SongModel>[];
  late List<bool> _isPlaying = <bool>[], _originalIsPlaying = <bool>[];
  late List<AnimationController> _controllers = <AnimationController>[],
      _originalControllers = <AnimationController>[];
  late PageController _songPageController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioManager audioPlayer = AudioManager.instance;
  final FocusNode _searchFocusNode = FocusNode();
  Duration _duration =Duration(seconds: 0);
  Duration _position =Duration(seconds: 0);
  double _slider =0;
  late int _currentIndex = 0,
      _artistIndex = 0,
      _albumIndex = 0,
      _screenIndex = 0;
  late bool _searchError = false, _isSearching = false, _noSongs = false;

  final ValueNotifier<String> _currentScreen = ValueNotifier<String>('Home');
  final ValueNotifier<bool> _currentlyPlaying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // OnAudioQuery().
    if (widget._songs.isEmpty == true) {
      setState(() {
        _noSongs = true;
      });
      print(
          "=-=-=-=-=-=-=-= length of song = ${widget._songs.length}=-=-=-=-=-=-=");
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        _noSongsAlert();
      });
    } else {
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        if (sp.getBool('clearThumbnailDontShowAgain') != true) {
          WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
            // _clearThumbnails();
          });
        }
      });

      for (int i = 0; i < widget._songs.length; i++) {
        _isPlaying.add(false);
        _controllers.add(AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
            reverseDuration: const Duration(milliseconds: 600)));
      }
      _originalSongs = widget._songs;
      _originalControllers = _controllers;
      _originalIsPlaying = _isPlaying;
      _textController.addListener(() {
        _searchSong(_textController.text);
      });
      audioPlayer.onEvents((event,arg) {
        switch (event) {
          case AudioManagerEvents.start:
            print(
                "start load data callback, curIndex is ${AudioManager.instance.curIndex}");
            _position = AudioManager.instance.position;
            _duration = AudioManager.instance.duration;
            _slider = 0;
            setState(() {});
            AudioManager.instance.updateLrc("audio resource loading....");
            break;
          case AudioManagerEvents.ready:
            print("ready to play");
            _position = AudioManager.instance.position;
            _duration = AudioManager.instance.duration;
            setState(() {});
            // if you need to seek times, must after AudioManagerEvents.ready event invoked
            // AudioManager.instance.seekTo(Duration(seconds: 10));
            break;
          case AudioManagerEvents.seekComplete:
            _position = AudioManager.instance.position;
            _slider = _position.inMilliseconds / _duration.inMilliseconds;
            setState(() {});
            // print("seek event is completed. position is [$ard]/ms");
            break;
          case AudioManagerEvents.buffering:
            // print("buffering $args");
            break;
          case AudioManagerEvents.playstatus:
            setState(() {});
            break;
          case AudioManagerEvents.timeupdate:
            _position = AudioManager.instance.position;
            _slider = _position.inMilliseconds / _duration.inMilliseconds;
            setState(() {});
            AudioManager.instance.updateLrc(arg["position"].toString());
            break;
          case AudioManagerEvents.error:
            setState(() {});
            break;
          case AudioManagerEvents.ended:
            AudioManager.instance.next();
            break;
          case AudioManagerEvents.volumeChange:
            setState(() {});
            break;
          default:
            break;
        }
       if(event == AudioManagerEvents.ended){
         if (_songPageController.hasClients == true) {
           _changeSong(1);
         } else {
           if (_currentIndex == (widget._songs.length - 1)) {
             _handleTap(0, false, true);
           } else {
             _handleTap(_currentIndex + 1, false, true);
           }
         }
       }
      });
      audioPlayer.onEvents((event,arg) {
        if (audioPlayer.isPlaying) {
          _currentlyPlaying.value = true;
        } else {
          _currentlyPlaying.value = false;
        }
      });
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        if (sp.getInt('currentIndex') != null) {
          _currentIndex = sp.getInt('currentIndex')!;
          PlayListInnerScreen.currentSongIndex = sp.getInt('currentIndex')!;
        }
        setState(() {});
      });
      WidgetsBinding.instance.addObserver(this);
    }
  }

  initMethod() {
    if (favSongs.isEmpty == true) {
      setState(() {
        _noSongs = true;
      });
      print("=-=-=-=-=-=-=-= length of song = ${favSongs.length}=-=-=-=-=-=-=");
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        _noSongsAlert();
      });
    } else {
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        if (sp.getBool('clearThumbnailDontShowAgain') != true) {
          WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
            // _clearThumbnails();
          });
        }
      });

      for (int i = 0; i < favSongs.length; i++) {
        _isPlaying.add(false);
        _controllers.add(AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
            reverseDuration: const Duration(milliseconds: 600)));
      }
      _originalSongs = favSongs;
      _originalControllers = _controllers;
      _originalIsPlaying = _isPlaying;
      _textController.addListener(() {
        _searchSong(_textController.text);
      });
      audioPlayer.onEvents((event,arg) {
        if(event == AudioManagerEvents.ended){
          if (_songPageController.hasClients == true) {
            _changeSong(1);
          } else {
            if (_currentIndex == (widget._songs.length - 1)) {
              _handleTap(0, false, true);
            } else {
              _handleTap(_currentIndex + 1, false, true);
            }
          }
        }
      });
      audioPlayer.onEvents((event,arg) {
        if (audioPlayer.isPlaying) {
          _currentlyPlaying.value = true;
        } else {
          _currentlyPlaying.value = false;
        }
      });
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        if (sp.getInt('currentIndex') != null) {
          _currentIndex = sp.getInt('currentIndex')!;
          FavoriteScreen.currentSongIndex = sp.getInt('currentIndex')!;
        }
        setState(() {});
      });
      WidgetsBinding.instance.addObserver(this);
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _songPageController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].dispose();
    }
    for (int i = 0; i < _originalControllers.length; i++) {
      _originalControllers[i].dispose();
    }
    // _currentScreen.dispose();
    // _currentlyPlaying.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  List<SongModel> favSongs = [];

  var preference = FavoritePref();

  getFavData() async {
    if (_currentScreen.value.toLowerCase() == "favorite") {
      await initMethod();
    }
    favSongs.clear();
    var pref = await preference.getString();
    if (pref == null || pref == "null" || pref.isEmpty) {
    } else {
      var decodedJson = jsonDecode(pref);
      favSongs.add(SongModel(decodedJson));
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    getFavData();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final double _value = WidgetsBinding.instance.window.viewInsets.bottom;
    if (_value == 0.0) {
      if (_textController.text.isEmpty) {
        _textController.clear();
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        sp.setInt('currentIndex', _currentIndex);
      });
    }
  }

  void _changeSong(int _index) {
    if (_index == 1) {
      _songPageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    } else {
      _songPageController.previousPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _deleteSong(String _path, int _index) async {
    final Directory dir = Directory(_path);
    await dir.delete(recursive: true);
    widget._songs.removeAt(_index);
    _originalSongs.removeAt(_index);
    _controllers.removeAt(_index);
    _originalControllers.removeAt(_index);
    _isPlaying.removeAt(_index);
    _originalIsPlaying.removeAt(_index);
    setState(() {});
  }

  void _searchSong(String _search) {
    if (_search.isEmpty) {
      setState(() {
        widget._songs = _originalSongs;
        _controllers = _originalControllers;
        _isPlaying = _originalIsPlaying;
        _searchError = false;
        if (_currentlyPlaying.value == true) {
          _controllers[_currentIndex].forward();
          _isPlaying[_currentIndex] = true;
        }
      });
      _scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn);
    } else {
      List<SongModel> _searchSongs = <SongModel>[];
      List<AnimationController> _searchControllers = <AnimationController>[];
      List<bool> _searchIsPlaying = <bool>[];
      for (int i = 0; i < _originalSongs.length; i++) {
        if (_originalSongs[i]
                .displayName
                .toLowerCase()
                .contains(_search.toLowerCase()) ==
            true) {
          _searchSongs.add(_originalSongs[i]);
          _searchIsPlaying.add(_originalIsPlaying[i]);
          _searchControllers.add(_originalControllers[i]);
        }
      }
      if (_searchSongs.isNotEmpty) {
        setState(() {
          widget._songs = _searchSongs;
          _isPlaying = _searchIsPlaying;
          _controllers = _searchControllers;
          _searchError = false;
        });
        _scrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn);
      } else {
        setState(() {
          _searchError = true;
        });
      }
    }
  }

  void _handleTap(int _index, bool _shouldRestart, bool _shouldPlay) {
    print("in Handle tap");
    if (_index != _currentIndex && _currentlyPlaying.value == true) {
      print("=-=-=-=-=-      1    =-=-=-=-=-");

      _controllers[_index].reverse();
      _originalControllers[_currentIndex].reverse();
      _isPlaying[_index] = false;
      _originalIsPlaying[_currentIndex] = false;
    }
    for (int i = 0; i < _originalSongs.length; i++) {
      if (widget._songs[_index] == _originalSongs[i]) {
        _currentIndex = i;
        PlayListInnerScreen.currentSongIndex = i;
        break;
      }
    }
    if (_isPlaying[_index] == false) {
      if (_shouldRestart == true) {
        print("=-=-=-=-=-      2    =-=-=-=-=-");
        audioPlayer.stop();
      }
      if (_shouldPlay == true) {
        print("=-=-=-=-=-      3    =-=-=-=-=-");
        audioPlayer.stop();
      }
      if (_shouldPlay == true) {
        print("=-=-=-=-=-      3    =-=-=-=-=-");
        audioPlayer.stop();
        audioPlayer
            .start(
            "file://${widget._songs[_index].data}",
            // "network format resource"
            // "local resource (file://${file.path})"
            "${widget._songs[_index].title}",
            desc: "desc",
            // cover: "network cover image resource"
            cover: "assets/music.png")
            .then((err) {
          audioPlayer.play();
        });
        _controllers[_index].forward();
        _originalControllers[_currentIndex].forward();
        _currentlyPlaying.value = true;
        _isPlaying[_index] = true;
        _originalIsPlaying[_currentIndex] = true;
      }
    } else {
      print("=-=-=-=-=-      4    =-=-=-=-=-");

      audioPlayer.toPause();
      _controllers[_index].reverse();
      _originalControllers[_currentIndex].reverse();
      _currentlyPlaying.value = false;
      _isPlaying[_index] = false;
      _originalIsPlaying[_currentIndex] = false;
    }
    setState(() {});
  }

  void _goToAlbum(int _index, int _a) {
    int _indexx = _index;
    if (_a == 1) {
      for (int i = 0; i < widget._songs.length; i++) {
        if (widget._albums[_index].album == widget._songs[i].album) {
          _indexx = i;
          break;
        }
      }
    }
    if (_currentScreen.value == 'AlbumPage') {
      if (_index != _albumIndex) {
        _albumIndex = _indexx;
        _currentScreen.value = 'Home';
        Timer(const Duration(milliseconds: 16), () {
          _currentScreen.value = 'AlbumPage';
        });
      }
    } else {
      _albumIndex = _indexx;
      _currentScreen.value = 'AlbumPage';
    }
    _scrollController.jumpTo(0.0);
  }

  void _goToArtist(int _index, int _a) {
    int _indexx = _index;
    if (_a == 1) {
      for (int i = 0; i < widget._songs.length; i++) {
        if (widget._artists[_index].artist == widget._songs[i].artist) {
          _indexx = i;
          break;
        }
      }
    }
    if (_currentScreen.value == 'ArtistPage') {
      if (_index != _artistIndex) {
        _artistIndex = _indexx;
        _currentScreen.value = 'Home';
        Timer(const Duration(milliseconds: 16), () {
          _currentScreen.value = 'ArtistPage';
        });
      }
    } else {
      _artistIndex = _indexx;
      _currentScreen.value = 'ArtistPage';
    }
    _scrollController.jumpTo(0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.darkColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.darkColor,
        foregroundColor: MyColors.accentColor,
        centerTitle: true,
        title: Text('${widget.title}'),
      ),
      body: (_noSongs == true)
            ? Container()
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  (_searchError == true)
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: const <Widget>[
                              SizedBox(height: 12.0),
                              Icon(
                                Icons.search_off,
                                size: 72.0,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12.0),
                              Text('No songs found.')
                            ],
                          ))
                      : ValueListenableBuilder<String>(
                          valueListenable: _currentScreen,
                          builder: (BuildContext context, String value,
                              Widget? child) {
                            return AnimatedSwitcher(
                              key: const ValueKey<String>('theBody'),
                              duration: const Duration(milliseconds: 800),
                              reverseDuration:
                                  const Duration(milliseconds: 600),
                              switchInCurve: Curves.easeInOutCubicEmphasized,
                              switchOutCurve: Curves.easeInOutCubic,
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) =>
                                      SlideTransition(
                                position: animation.drive(Tween<Offset>(
                                    begin: const Offset(0.0, 1.0),
                                    end: Offset.zero)),
                                child: FadeTransition(
                                    opacity: animation.drive(
                                        Tween<double>(begin: 0.1, end: 1.0)),
                                    child: child),
                              ),
                              child: (value == 'AlbumPage')
                                  ? Align(
                                      key: const Key('albums'),
                                      alignment: Alignment.topCenter,
                                      child: WillPopScope(
                                        key: const Key('albums_1'),
                                        onWillPop: () async {
                                          switch (_screenIndex) {
                                            case 0:
                                              _currentScreen.value = 'Home';
                                              break;
                                            case 1:
                                              _currentScreen.value = 'artists';
                                              break;
                                            case 2:
                                              _currentScreen.value = 'albums';
                                              break;
                                            case 3:
                                              _currentScreen.value = 'favorite';
                                              break;
                                            case 4:
                                              _currentScreen.value = 'playlist';
                                              break;
                                          }
                                          return false;
                                        },
                                        child: AlbumPage(
                                            widget._songs,
                                            _isPlaying,
                                            widget._songs[_albumIndex].album!,
                                            _handleTap,
                                            audioPlayer,
                                            _showBottomSheet),
                                      ),
                                    )
                                  : (value == 'ArtistPage')
                                      ? Align(
                                          key: const Key('artists'),
                                          alignment: Alignment.topCenter,
                                          child: WillPopScope(
                                            key: const Key('artists_1'),
                                            onWillPop: () async {
                                              switch (_screenIndex) {
                                                case 0:
                                                  _currentScreen.value = 'Home';
                                                  break;
                                                case 1:
                                                  _currentScreen.value =
                                                      'artists';
                                                  break;
                                                case 2:
                                                  _currentScreen.value =
                                                      'albums';
                                                  break;
                                                case 3:
                                                  _currentScreen.value =
                                                      'favorite';
                                                  break;
                                                case 3:
                                                  _currentScreen.value =
                                                      'playlist';
                                                  break;
                                              }
                                              return false;
                                            },
                                            child: ArtistPage(
                                                widget._songs,
                                                _isPlaying,
                                                widget._songs[_artistIndex]
                                                    .artist!,
                                                _handleTap,
                                                audioPlayer,
                                                _showBottomSheet),
                                          ),
                                        )
                                      : Align(
                                          key: const Key('songs'),
                                          alignment: Alignment.topCenter,
                                          child: NotificationListener<
                                              OverscrollIndicatorNotification>(
                                            onNotification:
                                                (OverscrollIndicatorNotification
                                                    _notification) {
                                              _notification.disallowIndicator();
                                              return false;
                                            },
                                            child: Column(
                                              children: [
                                                TextButton(onPressed: (){
                                                  widget._songs.shuffle();
                                                  _handleTap(
                                                      0,
                                                      true,
                                                      true);
                                                  setState(() {

                                                  });
                                                }, child: Text("Shuffle")),
                                                Expanded(
                                                  child: ReorderableListView(
                                                    physics: AlwaysScrollableScrollPhysics(),
                                                    onReorder: (int oldIndex,
                                                        int newIndex) {
                                                      setState(() {
                                                        if (oldIndex < newIndex) {
                                                          newIndex -= 1;
                                                        }
                                                        var temp = widget._songs
                                                            .removeAt(oldIndex);
                                                        widget._songs.insert(
                                                            newIndex, temp);
                                                        setState(() {});
                                                      });
                                                    },
                                                    children: [
                                                      for (var index = 0;
                                                          index <
                                                              widget
                                                                  ._songs.length;
                                                          index++)
                                                        Padding(
                                                          key: Key("$index"),
                                                          padding:
                                                              const EdgeInsets
                                                                      .fromLTRB(
                                                                  5.0,
                                                                  7.5,
                                                                  5.0,
                                                                  0.0),
                                                          child:
                                                          Slidable(
                                                            key:  ValueKey(0),
                                                            endActionPane: ActionPane(
                                                              extentRatio: 0.4,
                                                              // extentRatio: 0.5,
                                                              dragDismissible: false,
                                                              motion:  ScrollMotion(),
                                                              dismissible: DismissiblePane(onDismissed: () {}),
                                                              children:  [
                                                                SlidableAction(
                                                                  onPressed: (context) async {
                                                                    await showDialog(context: context, builder: (context) => AlertDialog(
                                                                      title: Text("Are you sure?"),
                                                                      content: Text("Do you really wan't to remove this song from playlist ?"),
                                                                      actions: [
                                                                        MaterialButton(onPressed: (){
                                                                          Navigator.pop(context);
                                                                        },child: Text("No"),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),),
                                                                        MaterialButton(onPressed: () async {
                                                                          PlayListDataModel currentPlaylist = widget.playListsData.firstWhere((element) => element.name == widget.title);
                                                                          currentPlaylist.songs!.remove(widget._songs[index]);
                                                                          widget._songs.remove(widget._songs[index]);
                                                                          widget.playListsData.removeWhere((element) => element.name == widget.title);
                                                                          widget.playListsData.add(currentPlaylist);
                                                                          var encodedResult = jsonEncode(widget.playListsData);
                                                                          var tmp = jsonEncode(encodedResult);
                                                                          await PlaylistPref().addString(tmp);
                                                                          Navigator.pop(context);
                                                                        },child: Text("Yes"),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))
                                                                      ],
                                                                    ));
                                                                    setState(() {
                                                                    });
                                                                  },
                                                                  // flex: 5,
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  // padding: EdgeInsets.only(left: 5),
                                                                  backgroundColor: Color(0xFFFE4A49),
                                                                  foregroundColor: Colors.white,
                                                                  icon: Icons.delete,
                                                                  label: 'Delete',

                                                                ),
                                                              ],
                                                            ),
                                                            child: AnimatedContainer(
                                                            duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          600),
                                                            curve: Curves
                                                                  .easeInOutCubic,
                                                            decoration:
                                                                  ShapeDecoration(
                                                                shape: (_isPlaying[
                                                                            index] ==
                                                                        true)
                                                                    ? const RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.all(Radius.circular(
                                                                                20.0)))
                                                                    : const RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.all(
                                                                                Radius.circular(12.0))),
                                                                color: (_isPlaying[
                                                                            index] ==
                                                                        true)
                                                                    ? MyColors
                                                                        .accentColor
                                                                    : Colors.grey
                                                                        .shade900,
                                                            ),
                                                            child: ListTile(
                                                                title: Text(
                                                                  widget
                                                                      ._songs[index]
                                                                      .title,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .fade,
                                                                  softWrap: false,
                                                                  style: TextStyle(
                                                                    fontSize: 18.0,
                                                                    shadows: (_isPlaying[
                                                                                index] ==
                                                                            true)
                                                                        ? <Shadow>[
                                                                            const Shadow(
                                                                              offset: Offset(
                                                                                  0.0,
                                                                                  0.84),
                                                                              blurRadius:
                                                                                  2.8,
                                                                              color:
                                                                                  Colors.black38,
                                                                            ),
                                                                          ]
                                                                        : null,
                                                                  ),
                                                                ),
                                                                subtitle: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .only(
                                                                          top: 2.0),
                                                                  child: Text(
                                                                    '${widget._songs[index].artist} ・ ${widget._songs[index].album}',
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: TextStyle(
                                                                        color: (_isPlaying[index] ==
                                                                                true)
                                                                            ? MyColors
                                                                                .darkColor
                                                                            : Colors
                                                                                .grey),
                                                                  ),
                                                                ),
                                                                onTap: () =>
                                                                    _handleTap(
                                                                        index,
                                                                        true,
                                                                        true),
                                                                leading:
                                                                    QueryArtworkWidget(
                                                                  id: widget
                                                                      ._songs[index]
                                                                      .id,
                                                                  type: ArtworkType
                                                                      .AUDIO,
                                                                  size: 50,
                                                                  nullArtworkWidget:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                500),
                                                                    child:
                                                                        Image.asset(
                                                                      'assets/music.png',
                                                                      height: 50,
                                                                      width: 50,
                                                                    ),
                                                                  ),
                                                                ),
                                                                trailing: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .only(
                                                                          bottom:
                                                                              4.0),
                                                                  child:
                                                                      AnimatedIcon(
                                                                    icon: AnimatedIcons
                                                                        .play_pause,
                                                                    progress:
                                                                        _controllers[
                                                                            index],
                                                                    color: (_isPlaying[
                                                                                index] ==
                                                                            true)
                                                                        ? MyColors
                                                                            .darkColor
                                                                        : MyColors
                                                                            .accentColor,
                                                                    size: 30.0,
                                                                  ),
                                                                ),
                                                                // onLongPress: () {
                                                                //   if (_isSearching !=
                                                                //       false) {
                                                                //     setState(() {
                                                                //       _isSearching =
                                                                //           false;
                                                                //     });
                                                                //   }
                                                                //   _showBottomSheet(
                                                                //       index, 0);
                                                                // },
                                                                minLeadingWidth:
                                                                    0.0,
                                                                contentPadding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        left: 8.0,
                                                                        right: 16.0,
                                                                        top: 4.0),
                                                                horizontalTitleGap:
                                                                    8.0,
                                                                dense: true,
                                                                visualDensity:
                                                                    const VisualDensity(
                                                                        horizontal:
                                                                            1.0,
                                                                        vertical:
                                                                            1.0),
                                                            ),
                                                          ),
                                                              ),
                                                        ),
                                                      // Container(
                                                      //   key: Key("asdvavsd"),
                                                      //   height: 100,
                                                      //   width: double.infinity,
                                                      // )
                                                    ],
                                                    key: const PageStorageKey<
                                                        String>('songsscreen'),
                                                    restorationId: 'songsscreen',
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 68.0),
                                                    shrinkWrap: true,
                                                    // physics:
                                                    //     const BouncingScrollPhysics(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                            );
                          },
                        ),
                  if (_noSongs != true)
                    Positioned.fill(
                      bottom: 6.0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            _songPageController = PageController(
                                initialPage: _currentIndex, keepPage: false);
                            if (_isSearching != false) {
                              setState(() {
                                _isSearching = false;
                              });
                            }
                            Navigator.of(context).push(MyRoute<dynamic>(
                                builder: (_) => NowPlaying(
                                    _songPageController,
                                    _originalSongs,
                                    audioPlayer,
                                    _handleTap,
                                    _deleteDialog,
                                    _changeSong,
                                    _goToArtist,
                                    _goToAlbum)));
                          },
                          onHorizontalDragEnd: (DragEndDetails details) {
                            if (details.primaryVelocity! > 0.0) {
                              if (_currentIndex == 0) {
                                _handleTap(
                                    widget._songs.length - 1, false, true);
                              } else {
                                _handleTap(_currentIndex - 1, false, true);
                              }
                            } else if (details.primaryVelocity! < 0.0) {
                              if (_currentIndex == (widget._songs.length - 1)) {
                                _handleTap(0, false, true);
                              } else {
                                _handleTap(_currentIndex + 1, false, true);
                              }
                            }
                          },
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _currentlyPlaying,
                            builder: (BuildContext context, bool value,
                                Widget? child) {
                              return AnimatedContainer(
                                clipBehavior: Clip.hardEdge,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                                width: MediaQuery.of(context).size.width - 12.0,
                                height: 60.0,
                                decoration: BoxDecoration(
                                  color: (value == false)
                                      ? Colors.grey
                                      : MyColors.accentColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black45,
                                      offset: Offset(0.0, 6.0),
                                      blurRadius: 20.0,
                                      spreadRadius: 2.0,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4.0, top: 4.0, bottom: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Hero(
                                            tag: 'albumartwork',
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(8.0)),
                                              child: QueryArtworkWidget(
                                                id: _originalSongs[
                                                        _currentIndex]
                                                    .id,
                                                type: ArtworkType.AUDIO,
                                                nullArtworkWidget: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            500),
                                                    child: Container(
                                                      child: Image.asset(
                                                        "assets/music.png",
                                                        height: 40,
                                                        width: 40,
                                                      ),
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle),
                                                    )),

                                                // nullArtworkWidget: Container(
                                                //
                                                // ),
                                              ),
                                              // child: (_originalSongs[_currentIndex].albumArtwork != null &&
                                              //         File(_originalSongs[_currentIndex].albumArtwork).existsSync() == true)
                                              //     ? Image.file(
                                              //         File(_originalSongs[_currentIndex].albumArtwork),
                                              //         fit: BoxFit.contain,
                                              //       )
                                              //     : Image.asset('assets/neon_headset.jpg'),
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Expanded(
                                            flex: 17,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                AnimatedDefaultTextStyle(
                                                  duration: const Duration(
                                                      milliseconds: 600),
                                                  curve: Curves.easeInOutCubic,
                                                  style: TextStyle(
                                                    color: (value == false)
                                                        ? MyColors.darkColor
                                                        : Colors.white,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Manrope',
                                                    shadows: (value == true)
                                                        ? const <Shadow>[
                                                            Shadow(
                                                              offset: Offset(
                                                                  0.0, 0.84),
                                                              blurRadius: 2.8,
                                                              color: Colors
                                                                  .black38,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  child: Text(
                                                    _originalSongs[
                                                            _currentIndex]
                                                        .title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.left,
                                                  ),
                                                ),
                                                AnimatedDefaultTextStyle(
                                                  duration: const Duration(
                                                      milliseconds: 600),
                                                  curve: Curves.easeInOutCubic,
                                                  style: TextStyle(
                                                    color: (value == false)
                                                        ? MyColors.darkColor
                                                        : Colors.white,
                                                    fontSize: 12.0,
                                                    fontFamily: 'Manrope',
                                                    shadows: (value == true)
                                                        ? const <Shadow>[
                                                            Shadow(
                                                              offset: Offset(
                                                                  0.0, 0.84),
                                                              blurRadius: 2.8,
                                                              color: Colors
                                                                  .black38,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  child: Text(
                                                    _originalSongs[_currentIndex]
                                                                .artist ==
                                                            null
                                                        ? "Unknown"
                                                        : _originalSongs[
                                                                _currentIndex]
                                                            .artist!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.left,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 10,
                                            child: Material(
                                              type: MaterialType.transparency,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: -4.0),
                                                    onPressed: () {
                                                      if (_currentIndex == 0) {
                                                        _handleTap(
                                                            widget._songs
                                                                    .length -
                                                                1,
                                                            false,
                                                            true);
                                                      } else {
                                                        _handleTap(
                                                            _currentIndex - 1,
                                                            false,
                                                            true);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.skip_previous,
                                                      color: MyColors.darkColor,
                                                      size: 30.0,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: -4.0),
                                                    onPressed: () => _handleTap(
                                                        _currentIndex,
                                                        false,
                                                        true),
                                                    icon: (value == false)
                                                        ? Icon(Icons.play_arrow,size: 40,color: MyColors.darkColor,)
                                                        : Icon(Icons.pause,size: 40,color: MyColors.darkColor)
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: -4.0),
                                                    onPressed: () {
                                                      if (_currentIndex ==
                                                          (widget._songs
                                                                  .length -
                                                              1)) {
                                                        _handleTap(
                                                            0, false, true);
                                                      } else {
                                                        _handleTap(
                                                            _currentIndex + 1,
                                                            false,
                                                            true);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.skip_next,
                                                      color: MyColors.darkColor,
                                                      size: 30.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Positioned.fill(
                                    //   bottom: 0.0,
                                    //   child: Align(
                                    //     alignment: Alignment.bottomCenter,
                                    //     child:SliderTheme(
                                    //         data: SliderTheme.of(context).copyWith(
                                    //           trackHeight: 2,
                                    //           thumbColor: Colors.blueAccent,
                                    //           overlayColor: Colors.blue,
                                    //           thumbShape: RoundSliderThumbShape(
                                    //             disabledThumbRadius: 5,
                                    //             enabledThumbRadius: 5,
                                    //           ),
                                    //           overlayShape: RoundSliderOverlayShape(
                                    //             overlayRadius: 10,
                                    //           ),
                                    //           activeTrackColor: Colors.blueAccent,
                                    //           inactiveTrackColor: Colors.grey,
                                    //         ),
                                    //         child: Slider(
                                    //           value: _slider ?? 0,
                                    //           onChanged: (value) {
                                    //             setState(() {
                                    //               _slider = value;
                                    //             });
                                    //           },
                                    //           onChangeEnd: (value) {
                                    //             if (_duration != null) {
                                    //               Duration msec = Duration(
                                    //                   milliseconds:
                                    //                   (_duration.inMilliseconds * value).round());
                                    //               AudioManager.instance.seekTo(msec);
                                    //             }
                                    //           },
                                    //         )),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),

    );
  }

  void _showBottomSheet(int _index, int _a) {
    showModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      enableDrag: false,
      backgroundColor: Colors.grey.shade900,
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
      context: context,
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_a != 1)
              ListTile(
                horizontalTitleGap: 8.0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                leading: const Icon(
                  Icons.person,
                  size: 32.0,
                  color: MyColors.accentColor,
                ),
                title: const Text(
                  'Go To Artist',
                  style: TextStyle(
                    color: MyColors.accentColor,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  widget._songs[_index].artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _goToArtist(_index, 0);
                },
              ),
            if (_a != 1)
              const Divider(
                height: 0.0,
                thickness: 0.5,
                color: MyColors.darkColor,
              ),
            if (_a != 2)
              ListTile(
                horizontalTitleGap: 8.0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                leading: const Icon(
                  Icons.album,
                  size: 32.0,
                  color: MyColors.accentColor,
                ),
                title: const Text(
                  'Go To Album',
                  style: TextStyle(
                    color: MyColors.accentColor,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  widget._songs[_index].album!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _goToAlbum(_index, 0);
                },
              ),
            if (_a != 2)
              const Divider(
                height: 0.0,
                thickness: 0.5,
                color: MyColors.darkColor,
              ),
            ListTile(
              horizontalTitleGap: 8.0,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              leading: const Icon(
                Icons.delete,
                size: 32.0,
                color: MyColors.accentColor,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(
                  color: MyColors.accentColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                widget._songs[_index].displayName
                    .substring(0, widget._songs[_index].displayName.length - 4),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteDialog(_index);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Object?> _deleteDialog(int _index) {
    return showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.63),
      barrierLabel: '',
      barrierDismissible: true,
      useRootNavigator: true,
      context: context,
      pageBuilder: (BuildContext context, Animation<double> anim1,
          Animation<double> anim2) {
        return AlertDialog(
          title: const Text(
            'Delete Song',
            textAlign: TextAlign.center,
          ),
          content: RichText(
            text: TextSpan(
                style: const TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Manrope',
                ),
                children: <TextSpan>[
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                      text: widget._songs[_index].displayName.substring(
                          0, widget._songs[_index].displayName.length - 4),
                      style: const TextStyle(color: MyColors.accentColor)),
                  const TextSpan(text: '?'),
                ]),
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateColor.resolveWith(
                      (Set<MaterialState> states) => Colors.white)),
              onPressed: () {
                _deleteSong(widget._songs[_index].data, _index);
                Navigator.of(context).pop();
              },
              child: const Text('DELETE'),
            ),
            TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateColor.resolveWith(
                      (Set<MaterialState> states) => Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
      transitionBuilder: (BuildContext context, Animation<double> anim1,
          Animation<double> anim2, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)
              .drive(Tween<double>(begin: 0.0, end: 1.0)),
          child: ScaleTransition(
            scale: CurvedAnimation(
                    parent: anim1, curve: Curves.easeInOutCubicEmphasized)
                .drive(Tween<double>(begin: 0.0, end: 1.0)),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  void _noSongsAlert() {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.63),
      barrierLabel: '',
      useRootNavigator: true,
      context: context,
      pageBuilder: (BuildContext context, Animation<double> anim1,
          Animation<double> anim2) {
        return WillPopScope(
          onWillPop: () async {
            Timer(const Duration(milliseconds: 350), () {
              Navigator.of(context).pushReplacement(MyRoute<dynamic>(
                  builder: (_) => PlayListInnerScreen(widget._songs,
                      widget._artists, widget._albums, widget.title,widget.playListsData)));
            });
            return false;
          },
          child: AlertDialog(
            title: const Text(
              'No Songs Found',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const <Widget>[
                Icon(
                  Icons.search_off,
                  size: 72.0,
                  color: MyColors.accentColor,
                ),
                Text(
                  'No songs found on the device.',
                  style: TextStyle(color: MyColors.accentColor),
                )
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: ButtonStyle(
                    foregroundColor: MaterialStateColor.resolveWith(
                        (Set<MaterialState> states) => Colors.white)),
                onPressed: () {
                  Navigator.of(context).pushReplacement(MyRoute<dynamic>(
                      builder: (_) => PlayListInnerScreen(widget._songs,
                          widget._artists, widget._albums, widget.title,widget.playListsData)));
                },
                child: const Text('TRY AGAIN'),
              ),
              TextButton(
                style: ButtonStyle(
                    foregroundColor: MaterialStateColor.resolveWith(
                        (Set<MaterialState> states) => Colors.white)),
                onPressed: () {
                  SystemNavigator.pop(animated: true);
                },
                child: const Text('EXIT'),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (BuildContext context, Animation<double> anim1,
          Animation<double> anim2, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)
              .drive(Tween<double>(begin: 0.0, end: 1.0)),
          child: ScaleTransition(
            scale: CurvedAnimation(
                    parent: anim1, curve: Curves.easeInOutCubicEmphasized)
                .drive(Tween<double>(begin: 0.0, end: 1.0)),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // void _clearThumbnails() {
  //   ValueNotifier<bool> _clearThumbnailDontShowAgain =
  //       ValueNotifier<bool>(false);
  //   showGeneralDialog(
  //     barrierColor: Colors.black.withOpacity(0.63),
  //     barrierLabel: '',
  //     useRootNavigator: true,
  //     context: context,
  //     pageBuilder: (BuildContext context, Animation<double> anim1,
  //         Animation<double> anim2) {
  //       return ValueListenableBuilder<bool>(
  //           valueListenable: _clearThumbnailDontShowAgain,
  //           builder: (BuildContext context, bool value, Widget? child) {
  //             return WillPopScope(
  //               onWillPop: () async {
  //                 if (value == true) {
  //                   SharedPreferences.getInstance()
  //                       .then((SharedPreferences sp) {
  //                     sp.setBool('clearThumbnailDontShowAgain', true);
  //                   });
  //                 }
  //                 Navigator.of(context).pop();
  //                 return false;
  //               },
  //               child: AlertDialog(
  //                 title: const Text(
  //                   'Reset Thumbnails',
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //                 content: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: <Widget>[
  //                     RichText(
  //                       text: const TextSpan(
  //                           style: TextStyle(
  //                             fontSize: 16.0,
  //                             fontFamily: 'Manrope',
  //                           ),
  //                           children: <TextSpan>[
  //                             TextSpan(
  //                                 text:
  //                                     'If some thumbnails / album arts are missing, click '),
  //                             TextSpan(
  //                                 text: 'GO TO SETTINGS > Storage > Clear Data',
  //                                 style:
  //                                     TextStyle(color: MyColors.accentColor)),
  //                             TextSpan(
  //                                 text:
  //                                     '.\nThis will remove all media thumbnails on the device.\nI recommend restarting the device after this procedure.\n'),
  //                           ]),
  //                     ),
  //                     Row(
  //                       children: <Widget>[
  //                         Checkbox(
  //                             value: value,
  //                             fillColor: MaterialStateColor.resolveWith(
  //                                 (Set<MaterialState> states) =>
  //                                     MyColors.accentColor),
  //                             visualDensity:
  //                                 const VisualDensity(horizontal: -4.0),
  //                             onChanged: (bool? _choice) {
  //                               _clearThumbnailDontShowAgain.value =
  //                                   !_clearThumbnailDontShowAgain.value;
  //                             }),
  //                         const SizedBox(width: 8.0),
  //                         InkWell(
  //                           onTap: () {
  //                             _clearThumbnailDontShowAgain.value =
  //                                 !_clearThumbnailDontShowAgain.value;
  //                           },
  //                           child: const Text("Don't Show Again",
  //                               style: TextStyle(color: MyColors.accentColor)),
  //                         ),
  //                       ],
  //                     ),
  //                     const Text(
  //                         'You can access this dialog anytime by pressing the header on All Songs page.',
  //                         style: TextStyle(
  //                             fontSize: 12.0, fontStyle: FontStyle.italic)),
  //                   ],
  //                 ),
  //                 actions: <Widget>[
  //                   TextButton(
  //                     style: ButtonStyle(
  //                         foregroundColor: MaterialStateColor.resolveWith(
  //                             (Set<MaterialState> states) => Colors.white)),
  //                     onPressed: () async {
  //                       // AndroidIntent intent = const AndroidIntent(
  //                       //   action:
  //                       //       'android.settings.APPLICATION_DETAILS_SETTINGS',
  //                       //   data: 'package:com.android.providers.media',
  //                       //   flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  //                       // );
  //                       if (value == true) {
  //                         SharedPreferences.getInstance()
  //                             .then((SharedPreferences sp) {
  //                           sp.setBool('clearThumbnailDontShowAgain', true);
  //                         });
  //                       }
  //                       Navigator.of(context).pop();
  //                       // await intent.launch();
  //                     },
  //                     child: const Text('GO TO SETTINGS'),
  //                   ),
  //                   TextButton(
  //                     style: ButtonStyle(
  //                         foregroundColor: MaterialStateColor.resolveWith(
  //                             (Set<MaterialState> states) => Colors.white)),
  //                     onPressed: () {
  //                       if (value == true) {
  //                         SharedPreferences.getInstance()
  //                             .then((SharedPreferences sp) {
  //                           sp.setBool('clearThumbnailDontShowAgain', true);
  //                         });
  //                       }
  //                       Navigator.of(context).pop();
  //                     },
  //                     child: const Text('CANCEL'),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           });
  //     },
  //     transitionBuilder: (BuildContext context, Animation<double> anim1,
  //         Animation<double> anim2, Widget child) {
  //       return FadeTransition(
  //         opacity: CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)
  //             .drive(Tween<double>(begin: 0.0, end: 1.0)),
  //         child: ScaleTransition(
  //           scale: CurvedAnimation(
  //                   parent: anim1, curve: Curves.easeInOutCubicEmphasized)
  //               .drive(Tween<double>(begin: 0.0, end: 1.0)),
  //           alignment: Alignment.bottomCenter,
  //           child: child,
  //         ),
  //       );
  //     },
  //     transitionDuration: const Duration(milliseconds: 350),
  //   );
  // }
}

class MyRoute<T> extends CupertinoPageRoute<T> {
  MyRoute({dynamic builder}) : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);
}
