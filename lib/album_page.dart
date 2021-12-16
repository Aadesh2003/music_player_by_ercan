// ignore_for_file: use_key_in_widget_constructors
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player_by_ercan/songs_screen.dart';
import 'colors.dart';

class AlbumPage extends StatefulWidget {
  final List<SongInfo> _songs;
  final List<bool> _isPlaying;
  final String _album;
  final Function _handleTap, _showBottomSheet;
  final AudioPlayer _player;
  const AlbumPage(this._songs, this._isPlaying, this._album, this._handleTap, this._player, this._showBottomSheet);

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with TickerProviderStateMixin {
  final List<SongInfo> _songs = <SongInfo>[];
  final List<bool> _isPlaying = <bool>[];
  final List<AnimationController> _controllers = <AnimationController>[];
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget._songs.length; i++) {
      if (widget._songs[i].album == widget._album) {
        _controllers.add(AnimationController(vsync: this, duration: const Duration(milliseconds: 600), reverseDuration: const Duration(milliseconds: 600)));
        if (widget._isPlaying[i] == true) {
          _currentIndex = _isPlaying.length;
          _controllers[_controllers.length - 1].value = 1.0;
        }
        _songs.add(widget._songs[i]);
        _isPlaying.add(widget._isPlaying[i]);
      }
    }
    widget._player.onPlayerStateChanged.listen((PlayerState s) {
      if (s != PlayerState.PLAYING) {
        _controllers[_currentIndex].reverse();
        setState(() {
          _isPlaying[_currentIndex] = false;
        });
      } else {
        for (int i = 0; i < _songs.length; i++) {
          if (widget._songs[SongsScreen.currentSongIndex].displayName == _songs[i].displayName) {
            setState(() {
              _currentIndex = i;
              _isPlaying[i] = true;
              _controllers[i].forward();
            });
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      key: const ValueKey<String>('albumpage_1'),
      scrollbarOrientation: ScrollbarOrientation.right,
      interactive: true,
      thumbColor: Colors.grey,
      minThumbLength: 36.0,
      thickness: 4.0,
      crossAxisMargin: 3.0,
      radius: const Radius.circular(24.0),
      child: ListView.builder(
          key: const ValueKey<String>('albumpage'),
          restorationId: 'albumpage',
          padding: const EdgeInsets.only(bottom: 68.0),
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: _songs.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 7.5, 5.0, 0.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                decoration: ShapeDecoration(
                  shape: (_isPlaying[index] == true)
                      ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0)))
                      : const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  color: (_isPlaying[index] == true) ? MyColors.accentColor : Colors.grey.shade900,
                ),
                child: ListTile(
                  title: Text(
                    _songs[index].title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 18.0,
                      shadows: (_isPlaying[index] == true)
                          ? <Shadow>[
                              const Shadow(
                                offset: Offset(0.0, 0.84),
                                blurRadius: 2.8,
                                color: Colors.black38,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${_songs[index].artist} ・ ${_songs[index].album}',
                      style: TextStyle(color: (_isPlaying[index] == true) ? MyColors.darkColor : Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    for (int i = 0; i < widget._songs.length; i++) {
                      if (widget._songs[i].displayName == _songs[index].displayName) {
                        widget._handleTap(i, true, true);
                        _controllers[_currentIndex].reverse();
                        setState(() {
                          _isPlaying[_currentIndex] = false;
                          if (index != _currentIndex) {
                            _currentIndex = index;
                            _isPlaying[index] = true;
                            _controllers[index].forward();
                          }
                        });
                        break;
                      }
                    }
                  },
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    width: (_isPlaying[index] == true) ? 24.0 : 0.0,
                    child: Icon(
                      Icons.music_note_outlined,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _controllers[index],
                      color: (_isPlaying[index] == true) ? MyColors.darkColor : MyColors.accentColor,
                      size: 30.0,
                    ),
                  ),
                  onLongPress: () {
                    for (int i = 0; i < widget._songs.length; i++) {
                      if (widget._songs[i].displayName == _songs[index].displayName) {
                        widget._showBottomSheet(i, 2);
                        break;
                      }
                    }
                  },
                  minLeadingWidth: 0.0,
                  contentPadding: const EdgeInsets.only(left: 8.0, right: 16.0, top: 4.0),
                  horizontalTitleGap: 8.0,
                  dense: true,
                  visualDensity: const VisualDensity(horizontal: 1.0, vertical: 1.0),
                ),
              ),
            );
          }),
    );
  }
}
