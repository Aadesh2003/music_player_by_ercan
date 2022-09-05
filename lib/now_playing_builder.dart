// ignore_for_file: use_key_in_widget_constructors
import 'dart:async';
import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:music_player_by_ercan/screens/now_playing_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlaying extends StatelessWidget {
  final PageController _pageController;
  final List<SongModel> _originalSongs;
  final AudioManager audioPlayer;
  final Function _handleTap, _deleteDialog, _changeSong, _goToArtist, _goToAlbum;
  const NowPlaying(
      this._pageController, this._originalSongs, this.audioPlayer, this._handleTap, this._deleteDialog, this._changeSong, this._goToArtist, this._goToAlbum);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (OverscrollIndicatorNotification overscroll) {
        overscroll.disallowIndicator();
        return false;
      },
      child: PageView.builder(
        key: const PageStorageKey<String>('NOW PLAYING'),
        controller: _pageController,
        itemCount: _originalSongs.length,
        itemBuilder: (BuildContext context, int index) {
          return NowPlayingScreen(_originalSongs, audioPlayer, _deleteDialog, _changeSong, index, _handleTap, _goToArtist, _goToAlbum);
        },
        onPageChanged: (int _index) {
          Timer(const Duration(milliseconds: 350), () {
            _handleTap(_index, false, ((audioPlayer.isPlaying) ? true : false));
          });
        },
      ),
    );
  }
}
