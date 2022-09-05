// ignore_for_file: use_key_in_widget_constructors, always_specify_types, prefer_single_quotes, always_declare_return_types, avoid_function_literals_in_foreach_calls, avoid_print, prefer_const_constructors, unused_local_variable, unnecessary_string_interpolations
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audio_manager/audio_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:music_player_by_ercan/models/playlist_model.dart';
import 'package:music_player_by_ercan/prefrences/favorite_pref.dart';
import 'package:music_player_by_ercan/prefrences/playlist_pref.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../colors.dart';
import 'package:auto_size_text/auto_size_text.dart';

class NowPlayingScreen extends StatefulWidget {
  final List<SongModel> _songs;
  final AudioManager audioPlayer;
  final Function _deleteDialog,
      _changeSong,
      _handleTap,
      _goToArtist,
      _goToAlbum;
  final int _songIndex;

  const NowPlayingScreen(
      this._songs,
      this.audioPlayer,
      this._deleteDialog,
      this._changeSong,
      this._songIndex,
      this._handleTap,
      this._goToArtist,
      this._goToAlbum);

  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late double _sliderValue = 0.0;
  late String _currentPosition = '00:00', _songDuration;
  final ValueNotifier<bool> _currentlyPlaying = ValueNotifier<bool>(true);
  final ScrollController _textScroll = ScrollController();
  Duration _duration = Duration(seconds: 1);
  Duration _position = Duration(seconds: 0);
  double _slider = 0;
  @override
  void initState() {
    super.initState();
    getFavData();
    getplayLists();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600), value: 1.0);
    _songDuration =
    '${(int.parse(widget._songs[widget._songIndex].duration.toString()) ~/ 60000).toString().padLeft(2, '0')}:${((int.parse(widget._songs[widget._songIndex].duration.toString()) ~/ 1000) % 60).toString().padLeft(2, '0')}';
    _initialCorrectPosition();
    if ('${widget._songs[widget._songIndex].artist} ・ ${widget._songs[widget._songIndex].album}'
        .length >
        43) {
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        _textScroll.jumpTo(0.0);
        _scrollText();
      });
    }
    widget.audioPlayer.onEvents((event, arg) {
      print("==-=-==-=-=-=-=-=-=-= $event =-==-= $arg =-=-=-=-");

      if(onEventCall){
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
            // print("seek event is completed. position is [$args]/ms");
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
            // AudioManager.instance.updateLrc(args["position"].toString());
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
        if (widget.audioPlayer.isPlaying) {
          _currentlyPlaying.value = true;
          _controller.forward();
        } else {
          _currentlyPlaying.value = false;
          _controller.reverse();
        }
      }
    });
    // PlayerState _a = widget.audioPlayer.state;
    // if (widget.audioPlayer.isPlaying) {
    //   _currentlyPlaying.value = false;
    //   _controller.value = 0.0;
    // }
  }

  void _scrollText() {
    Timer.periodic(const Duration(milliseconds: 3800), (Timer timer) {
      if (_textScroll.hasClients == true) {
        _textScroll.animateTo(
            (_textScroll.position.pixels ==
                _textScroll.position.maxScrollExtent)
                ? 0.0
                : _textScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 1400),
            curve: Curves.fastOutSlowIn);
      }
    });
  }

  var onEventCall = true;

  void _initialCorrectPosition() async {
    // var t = AudioPlayer().get
    _position = AudioManager.instance.position;
    _duration = AudioManager.instance.duration;
    _slider = 0;
    setState(() {});
    _sliderValue = ((int.parse(widget.audioPlayer.position.toString())) / 1000);
    _currentPosition =
    '${(_sliderValue ~/ 60).toString().padLeft(2, '0')}:${((_sliderValue % 60).toInt()).toString().padLeft(2, '0')}';
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    onEventCall = false;
    setState((){});
    _controller.dispose();
    _textScroll.dispose();
    _currentlyPlaying.dispose();
  }

  List<SongModel> favSongs = [];

  var preference = FavoritePref();
  String _formatDuration(Duration d) {
    if (d == null) return "--:--";
    int minute = d.inMinutes;
    int second = (d.inSeconds > 60) ? (d.inSeconds % 60) : d.inSeconds;
    String format = ((minute < 10) ? "0$minute" : "$minute") +
        ":" +
        ((second < 10) ? "0$second" : "$second");
    return format;
  }

  getFavData() async {
    favSongs.clear();
    var pref = await preference.getString();
    if (pref == null || pref == "null" || pref.isEmpty) {
    } else {
      var decodedJson = jsonDecode(pref);
      // for (var i = 0; i < pref.length; i++) {
      favSongs.add(SongModel(decodedJson));
      // }
      favSongs.forEach((element) {
        if (element.data == widget._songs[widget._songIndex].data) {
          isFavorite = true;
        } else {
          isFavorite = false;
        }
      });
      // favSongs.contains(widget._songs[widget._songIndex]) ? isFavorite = true : isFavorite= false;
      // print(favSongs);
      setState(() {});
      // print(decodedJson);
    }
  }

  var isFavorite = false;

  favClick() async {
    if (isFavorite) {
      // var pref = await preference.getString();
      // var decodedJson = jsonDecode(pref);
      // // for (var i = 0; i < pref.length; i++) {
      //   favSongs.add(SongModel(decodedJson));
      // }
      favSongs.removeWhere(
              (element) => element.data == widget._songs[widget._songIndex].data);
      if (favSongs.isEmpty) {
        preference.addString("");
      } else {
        favSongs.forEach((element) async {
          var song = element;
          var info = song.info;
          var encodedString = jsonEncode(info);
          await preference.addString(encodedString);
        });
      }
      isFavorite = false;
      setState(() {});
    } else {
      var song = widget._songs[widget._songIndex];
      var info = song.info;
      var encodedString = jsonEncode(info);
      await preference.addString(encodedString);
    }
  }

  List<PlayListDataModel> playListdata = [];

  getplayLists() async {
    var prefData = await PlaylistPref().getString();
    print(prefData);
    if (prefData != null) {
      var data = jsonDecode(jsonDecode(prefData));
      if (data.isNotEmpty || data != null) {
        for (var i = 0; i < data.length; i++) {
          PlayListDataModel songs = PlayListDataModel.fromJson(data[i]);
          playListdata.add(songs);
        }
      }
    }
  }

  buildDialog() async {
    var playListName = "";
    // var pref = await PlaylistPref().getString();
    // List<PlayListDatmodel> playList = jsonDecode(pref);
    TextEditingController playListNameController = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("PlayLists"),
          content: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: 1,
                maxHeight: MediaQuery.of(context).size.height / 2,
                maxWidth: double.infinity,
                minWidth: 1),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: playListNameController,
                    onFieldSubmitted: (e) {},
                  ),
                  MaterialButton(
                    onPressed: () async {
                      playListName = playListNameController.text;
                      try {
                        List<PlayListDataModel> playListdata = [];
                        var prefData = await PlaylistPref().getString();
                        print(prefData);
                        if (prefData != null) {
                          var data = jsonDecode(jsonDecode(prefData));
                          if (data.isNotEmpty || data != null) {
                            for (var i = 0; i < data.length; i++) {
                              PlayListDataModel songs =
                              PlayListDataModel.fromJson(data[i]);
                              playListdata.add(songs);
                            }
                          }
                        }
                        playListdata.add(
                          PlayListDataModel(
                              name: playListName,
                              dateCreated: DateTime.now().toString(),
                              songs: [widget._songs[widget._songIndex]]),
                        );
                        var encodedResult = jsonEncode(playListdata);
                        var tmp = jsonEncode(encodedResult);
                        await PlaylistPref().addString(tmp);
                        var getPref = await PlaylistPref().getString();
                        var decodedData = jsonDecode(jsonDecode(getPref));
                        List<PlayListDataModel> prefPlayList = [];
                        if (decodedData.isNotEmpty || decodedData != null) {
                          for (var i = 0; i < decodedData.length; i++) {
                            PlayListDataModel songs =
                            PlayListDataModel.fromJson(decodedData[i]);
                            prefPlayList.add(songs);
                          }
                        }
                        print(prefPlayList);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text("PlayList created successfully")));
                        Navigator.pop(context);
                      } catch (e) {
                        print(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                      // Navigator.pop(context);
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => SongSelectionScreen(playListName: playListName,)));
                    },
                    child: Text("Done"),
                  ),
                  ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 3,
                          minHeight: 1),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: playListdata
                              .map(
                                (e) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(15),
                                    color: ThemeData.dark().cardColor),
                                child: ListTile(
                                  onTap: () async {
                                    try {
                                      PlayListDataModel temp =
                                      playListdata.firstWhere(
                                              (element) =>
                                          element == e);
                                      var changedPlaylist = temp.songs!
                                          .add(widget._songs[
                                      widget._songIndex]);
                                      playListdata.remove(e);
                                      playListdata.add(temp);
                                      var encodedResult =
                                      jsonEncode(playListdata);
                                      var tmp =
                                      jsonEncode(encodedResult);
                                      await PlaylistPref()
                                          .addString(tmp);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(
                                              "Song added to ${e.name}")));
                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(
                                              "${e.toString()}")));
                                    }
                                  },
                                  minVerticalPadding: 0,
                                  title: Text(e.name!),
                                  subtitle:
                                  Text(e.songs!.length.toString()),
                                  trailing:
                                  Icon(Icons.navigate_next_rounded),
                                ),
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      )),
                ]),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white60),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          toolbarHeight: kToolbarHeight - 8.0,
          centerTitle: true,
          title: const Text('Now Playing'),
          titleTextStyle: const TextStyle(
            fontSize: 20.0,
            color: Colors.white60,
            fontFamily: 'Manrope',
          ),
          actions: <Widget>[
            IconButton(
                onPressed: () async {
                  await favClick();
                  await getFavData();
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? MyColors.accentColor : Colors.grey,
                )),
            IconButton(
                onPressed: () async {
                  // add playlist logic here
                  buildDialog();
                },
                icon: Icon(
                  Icons.playlist_play_rounded,
                  color: Colors.grey,
                )),
            PopupMenuButton<int>(
              padding: EdgeInsets.zero,
              offset: const Offset(-14.0, 42.0),
              color: Colors.grey.shade900,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                PopupMenuItem<int>(
                  padding: EdgeInsets.zero,
                  value: 1,
                  textStyle: const TextStyle(
                    color: MyColors.accentColor,
                    fontSize: 16.0,
                    fontFamily: 'Manrope',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(
                        Icons.person,
                        color: MyColors.accentColor,
                      ),
                      SizedBox(width: 6.0),
                      Text('Go To Artist'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  padding: EdgeInsets.zero,
                  value: 2,
                  textStyle: const TextStyle(
                    color: MyColors.accentColor,
                    fontSize: 16.0,
                    fontFamily: 'Manrope',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(
                        Icons.album,
                        color: MyColors.accentColor,
                      ),
                      SizedBox(width: 6.0),
                      Text('Go To Album'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  padding: EdgeInsets.zero,
                  value: 3,
                  textStyle: const TextStyle(
                    color: MyColors.accentColor,
                    fontSize: 16.0,
                    fontFamily: 'Manrope',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(
                        Icons.delete,
                        color: MyColors.accentColor,
                      ),
                      SizedBox(width: 6.0),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (Object? value) async {
                if (value == 1) {
                  Navigator.of(context).pop();
                  widget._goToArtist(widget._songIndex, 0);
                } else if (value == 2) {
                  Navigator.of(context).pop();
                  widget._goToAlbum(widget._songIndex, 0);
                } else if (value == 3) {
                  widget._deleteDialog(widget._songIndex);
                }
              },
            ),
          ],
        ),
        body: ValueListenableBuilder<bool>(
            valueListenable: _currentlyPlaying,
            builder: (BuildContext context, bool value, Widget? child) {
              return Stack(
                children: [
                  QueryArtworkWidget(
                    // size: 200,
                    artworkHeight: MediaQuery.of(context).size.height,
                    artworkWidth: MediaQuery.of(context).size.width,
                    id: widget._songs[widget._songIndex].id,
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.zero,
                    nullArtworkWidget: Image.asset(
                      "assets/music.png",
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                  BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.2, sigmaY: 10.2),
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        // child:
                      )
                    // child: (widget._songs[widget._songIndex].albumArtwork != null && File(widget._songs[widget._songIndex].albumArtwork).existsSync() == true)
                    //     ? Image.file(
                    //         File(widget._songs[widget._songIndex].albumArtwork),
                    //         height: MediaQuery.of(context).size.height,
                    //         width: MediaQuery.of(context).size.width,
                    //         fit: BoxFit.fitHeight,
                    //         color: (value == true) ? Colors.black12 : Colors.black54,
                    //         colorBlendMode: BlendMode.darken,
                    //       )
                    //     : Image.asset(
                    //         'assets/neon_headset.jpg',
                    //         height: MediaQuery.of(context).size.height,
                    //         width: MediaQuery.of(context).size.width,
                    //         fit: BoxFit.fitHeight,
                    //         color: (value == true) ? Colors.black12 : Colors.black54,
                    //         colorBlendMode: BlendMode.darken,
                    //       ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                        child: Hero(
                          tag: 'albumartwork',
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 12.0),
                            child: ClipRRect(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(12.0)),
                                child: QueryArtworkWidget(
                                  id: widget._songs[widget._songIndex].id,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: Image.asset(
                                    "assets/music.png",
                                    height:
                                    MediaQuery.of(context).size.height / 3,
                                    width:
                                    MediaQuery.of(context).size.height / 3,
                                  ),
                                  artworkBorder: BorderRadius.circular(0),
                                  artworkHeight:
                                  MediaQuery.of(context).size.height / 3,
                                  artworkWidth:
                                  MediaQuery.of(context).size.height / 3,
                                )
                              // child: (widget._songs[widget._songIndex].albumArtwork != null &&
                              //         File(widget._songs[widget._songIndex].albumArtwork).existsSync() == true)
                              //     ? Image.file(
                              //         File(widget._songs[widget._songIndex].albumArtwork),
                              //         width: MediaQuery.of(context).size.width - 24,
                              //       )
                              //     : Image.asset(
                              //         'assets/neon_headset.jpg',
                              //         width: MediaQuery.of(context).size.width - 24,
                              //       ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 24.0,
                                child: AutoSizeText(
                                  widget._songs[widget._songIndex].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: (value == true)
                                        ? MyColors.accentColor
                                        : Colors.white24,
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w600,
                                    shadows: (value == true)
                                        ? const <Shadow>[
                                      Shadow(
                                        offset: Offset(0.0, 0.84),
                                        blurRadius: 4.2,
                                        color: Colors.black38,
                                      ),
                                    ]
                                        : null,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 24.0,
                                child: Center(
                                  child: SingleChildScrollView(
                                    controller: _textScroll,
                                    scrollDirection: Axis.horizontal,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    child: Text(
                                      '${widget._songs[widget._songIndex].artist} ・ ${widget._songs[widget._songIndex].album}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: (value == true)
                                            ? MyColors.accentColor
                                            : Colors.white24,
                                        fontSize: 16.0,
                                        shadows: (value == true)
                                            ? const <Shadow>[
                                          Shadow(
                                            offset: Offset(0.0, 0.84),
                                            blurRadius: 2.8,
                                            color: Colors.black38,
                                          ),
                                        ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                height: 28.0,
                                child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2,
                                      thumbColor: Colors.blueAccent,
                                      overlayColor: Colors.blue,
                                      thumbShape: RoundSliderThumbShape(
                                        disabledThumbRadius: 5,
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 10,
                                      ),
                                      activeTrackColor: Colors.blueAccent,
                                      inactiveTrackColor: Colors.grey,
                                    ),
                                    child: Slider(
                                      value: _slider ?? 0,
                                      onChanged: (value) {
                                        setState(() {
                                          _slider = value;
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        if (_duration != null) {
                                          Duration msec = Duration(
                                              milliseconds:
                                              (_duration.inMilliseconds *
                                                  value)
                                                  .round());
                                          AudioManager.instance.seekTo(msec);
                                        }
                                      },
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      _formatDuration(_position),
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: Offset(0.0, 0.84),
                                            blurRadius: 2.8,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: Offset(0.0, 0.84),
                                            blurRadius: 2.8,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Material(
                                type: MaterialType.transparency,
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 60.0,
                                      height: 60.0,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          widget._changeSong(0);
                                        },
                                        icon: Icon(
                                          Icons.skip_previous,
                                          color: (value == true)
                                              ? MyColors.accentColor
                                              : Colors.white24,
                                          size: 48.0,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          widget._handleTap(
                                              widget._songIndex, false, true);
                                        },
                                        icon: AnimatedIcon(
                                          icon: AnimatedIcons.play_pause,
                                          color: (value == true)
                                              ? MyColors.accentColor
                                              : Colors.white,
                                          progress: Tween<double>(
                                              begin: 0.0, end: 1.0)
                                              .animate(CurvedAnimation(
                                              parent: _controller,
                                              curve:
                                              Curves.easeInOutCubic)),
                                          // color: Colors.white,
                                          size: 60.0,
                                        ),
                                      ),
                                    ),
                                    // Material(
                                    //   color: Colors.transparent,
                                    //   elevation: 6.3,
                                    //   animationDuration: const Duration(milliseconds: 650),
                                    //   shape: (value == true)
                                    //       ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))
                                    //       : const CircleBorder(),
                                    //   child: AnimatedContainer(
                                    //     duration: const Duration(milliseconds: 600),
                                    //     curve: Curves.easeInOutCubic,
                                    //     width: 75.0,
                                    //     height: 75.0,
                                    //     decoration: ShapeDecoration(
                                    //       color: (value == true) ? MyColors.accentColor : Colors.grey.shade900,
                                    //       shape: (value == true)
                                    //           ? const RoundedRectangleBorder(
                                    //           borderRadius: BorderRadius.all(Radius.circular(12.0)), side: BorderSide(color: MyColors.accentColor))
                                    //           : const CircleBorder(side: BorderSide(color: MyColors.accentColor)),
                                    //     ),
                                    //     child:
                                    //   ),
                                    // ),
                                    SizedBox(
                                      width: 60.0,
                                      height: 60.0,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          widget._changeSong(1);
                                        },
                                        icon: Icon(
                                          Icons.skip_next,
                                          color: (value == true)
                                              ? MyColors.accentColor
                                              : Colors.white24,
                                          size: 48.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }),
      ),
    );
  }
}
