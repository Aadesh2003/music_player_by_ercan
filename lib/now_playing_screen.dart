// ignore_for_file: use_key_in_widget_constructors
import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'dart:io';
import 'colors.dart';
import 'package:auto_size_text/auto_size_text.dart';

class NowPlayingScreen extends StatefulWidget {
  final List<SongInfo> _songs;
  final AudioPlayer _player;
  final Function _deleteDialog, _changeSong, _handleTap, _goToArtist, _goToAlbum;
  final int _songIndex;

  const NowPlayingScreen(this._songs, this._player, this._deleteDialog, this._changeSong, this._songIndex, this._handleTap, this._goToArtist, this._goToAlbum);

  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late double _sliderValue = 0.0;
  late String _currentPosition = '00:00', _songDuration;
  final ValueNotifier<bool> _currentlyPlaying = ValueNotifier<bool>(true);
  final ScrollController _textScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600), value: 1.0);
    _songDuration =
        '${(int.parse(widget._songs[widget._songIndex].duration) ~/ 60000).toString().padLeft(2, '0')}:${((int.parse(widget._songs[widget._songIndex].duration) ~/ 1000) % 60).toString().padLeft(2, '0')}';
    _initialCorrectPosition();
    if ('${widget._songs[widget._songIndex].artist} ・ ${widget._songs[widget._songIndex].album}'.length > 43) {
      WidgetsBinding.instance!.addPostFrameCallback((Duration timeStamp) {
        _textScroll.jumpTo(0.0);
        _scrollText();
      });
    }
    widget._player.onPlayerStateChanged.listen((PlayerState s) {
      if (s == PlayerState.PLAYING) {
        _currentlyPlaying.value = true;
        _controller.forward();
      } else {
        _currentlyPlaying.value = false;
        _controller.reverse();
      }
    });
    PlayerState _a = widget._player.state;
    if (_a != PlayerState.PLAYING) {
      _currentlyPlaying.value = false;
      _controller.value = 0.0;
    }
  }

  void _scrollText() {
    Timer.periodic(const Duration(milliseconds: 3800), (Timer timer) {
      if (_textScroll.hasClients == true) {
        _textScroll.animateTo((_textScroll.position.pixels == _textScroll.position.maxScrollExtent) ? 0.0 : _textScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 1400), curve: Curves.fastOutSlowIn);
      }
    });
  }

  void _initialCorrectPosition() async {
    _sliderValue = ((await widget._player.getCurrentPosition()) / 1000);
    _currentPosition = '${(_sliderValue ~/ 60).toString().padLeft(2, '0')}:${((_sliderValue % 60).toInt()).toString().padLeft(2, '0')}';
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _textScroll.dispose();
    _currentlyPlaying.dispose();
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
            PopupMenuButton<int>(
              padding: EdgeInsets.zero,
              offset: const Offset(-14.0, 42.0),
              color: Colors.grey.shade900,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
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
                //clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25.2, sigmaY: 25.2),
                    child: (widget._songs[widget._songIndex].albumArtwork != null && File(widget._songs[widget._songIndex].albumArtwork).existsSync() == true)
                        ? Image.file(
                            File(widget._songs[widget._songIndex].albumArtwork),
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            //fit: BoxFit.cover,
                            fit: BoxFit.fitHeight,
                            color: (value == true) ? Colors.black12 : Colors.black54,
                            colorBlendMode: BlendMode.darken,
                          )
                        : Image.asset(
                            'assets/neon_headset.jpg',
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            //fit: BoxFit.cover,
                            fit: BoxFit.fitHeight,
                            color: (value == true) ? Colors.black12 : Colors.black54,
                            colorBlendMode: BlendMode.darken,
                          ),
                  ),
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
                                color: (value == true) ? MyColors.accentColor : Colors.white24,
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
                                physics: const NeverScrollableScrollPhysics(),
                                child: Text(
                                  '${widget._songs[widget._songIndex].artist} ・ ${widget._songs[widget._songIndex].album}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: (value == true) ? MyColors.accentColor : Colors.white24,
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
                      Hero(
                        tag: 'albumartwork',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Material(
                            color: Colors.transparent,
                            elevation: 6.3,
                            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                              child: (widget._songs[widget._songIndex].albumArtwork != null &&
                                      File(widget._songs[widget._songIndex].albumArtwork).existsSync() == true)
                                  ? Image.file(
                                      File(widget._songs[widget._songIndex].albumArtwork),
                                      width: MediaQuery.of(context).size.width - 24,
                                    )
                                  : Image.asset(
                                      'assets/neon_headset.jpg',
                                      width: MediaQuery.of(context).size.width - 24,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            height: 28.0,
                            child: StreamBuilder<Duration>(
                              stream: widget._player.onAudioPositionChanged,
                              builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                                return Slider(
                                  activeColor: MyColors.accentColor,
                                  inactiveColor: Colors.white24,
                                  thumbColor: (value == true) ? MyColors.accentColor : Colors.grey,
                                  onChanged: (double a) {
                                    widget._player.seek(Duration(seconds: a.toInt()));
                                  },
                                  value: (snapshot.hasData) ? snapshot.data!.inSeconds.toDouble() : _sliderValue,
                                  max: (int.parse(widget._songs[widget._songIndex].duration) / 1000),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                StreamBuilder<Duration>(
                                  stream: widget._player.onAudioPositionChanged,
                                  builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                                    return Text(
                                      (snapshot.hasData)
                                          ? '${snapshot.data!.inMinutes.toString().padLeft(2, '0')}:${(snapshot.data!.inSeconds % 60).toString().padLeft(2, '0')}'
                                          : _currentPosition,
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
                                    );
                                  },
                                ),
                                Text(
                                  _songDuration,
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
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                      color: (value == true) ? MyColors.accentColor : Colors.white24,
                                      size: 48.0,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  elevation: 6.3,
                                  animationDuration: const Duration(milliseconds: 650),
                                  shape: (value == true)
                                      ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))
                                      : const CircleBorder(),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutCubic,
                                    width: 75.0,
                                    height: 75.0,
                                    decoration: ShapeDecoration(
                                      color: (value == true) ? MyColors.accentColor : Colors.grey.shade900,
                                      shape: (value == true)
                                          ? const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(12.0)), side: BorderSide(color: MyColors.accentColor))
                                          : const CircleBorder(side: BorderSide(color: MyColors.accentColor)),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        /*if (_controller.status == AnimationStatus.completed) {
                                          _controller.reverse();
                                        } else if (_controller.status == AnimationStatus.dismissed) {
                                          _controller.forward();
                                        }
                                        setState(() {});*/
                                        widget._handleTap(widget._songIndex, false, true);
                                      },
                                      icon: AnimatedIcon(
                                        icon: AnimatedIcons.play_pause,
                                        progress:
                                            Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic)),
                                        color: Colors.white,
                                        size: 60.0,
                                      ),
                                    ),
                                  ),
                                ),
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
                                      color: (value == true) ? MyColors.accentColor : Colors.white24,
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
              );
            }),
      ),
    );
  }
}
