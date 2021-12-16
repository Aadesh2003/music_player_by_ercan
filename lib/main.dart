// ignore_for_file: use_key_in_widget_constructors
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_player_by_ercan/songs_screen.dart';
import 'colors.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  PermissionStatus _status = await Permission.storage.status;
  List<SongInfo> _songs = <SongInfo>[];
  List<ArtistInfo> _artists = <ArtistInfo>[];
  List<AlbumInfo> _albums = <AlbumInfo>[];
  if (_status.isGranted == true) {
    _songs = await FlutterAudioQuery().getSongs();
    _artists = await FlutterAudioQuery().getArtists();
    _albums = await FlutterAudioQuery().getAlbums();
    for (int i = 0; i < _songs.length; i++) {
      if (_songs[i].filePath == null || File(_songs[i].filePath).existsSync() != true) {
        _songs.removeAt(i);
        i--;
      }
    }
  }
  runApp(MaterialApp(
    color: MyColors.darkColor,
    title: 'Music Player by Ercan',
    darkTheme: ThemeData(
      fontFamily: 'Manrope',
      brightness: Brightness.dark,
      primaryColor: MyColors.darkColor,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      dividerTheme: const DividerThemeData(color: Colors.grey),
      pageTransitionsTheme:
          const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{TargetPlatform.android: CupertinoPageTransitionsBuilder()}),
      textSelectionTheme: const TextSelectionThemeData(selectionHandleColor: MyColors.accentColor),
      sliderTheme: const SliderThemeData(
        trackHeight: 6.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
      ),
      textTheme: const TextTheme(
          button: TextStyle(fontFamily: 'Manrope'),
          bodyText1: TextStyle(fontFamily: 'Manrope'),
          bodyText2: TextStyle(fontFamily: 'Manrope'),
          subtitle1: TextStyle(fontFamily: 'Manrope'),
          subtitle2: TextStyle(fontFamily: 'Manrope'),
          headline3: TextStyle(fontFamily: 'Manrope'),
          headline4: TextStyle(fontFamily: 'Manrope'),
          headline5: TextStyle(fontFamily: 'Manrope'),
          headline6: TextStyle(fontFamily: 'Manrope'),
          caption: TextStyle(fontFamily: 'Manrope'),
          overline: TextStyle(fontFamily: 'Manrope')),
      dialogTheme: DialogTheme(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
        backgroundColor: Colors.grey.shade900,
        elevation: 12.0,
      ),
    ),
    themeMode: ThemeMode.dark,
    home: MyApp(_songs, _artists, _albums, _status),
  ));
}

class MyApp extends StatelessWidget {
  final List<SongInfo> _songs;
  final List<ArtistInfo> _artists;
  final List<AlbumInfo> _albums;
  final PermissionStatus _status;

  const MyApp(this._songs, this._artists, this._albums, this._status);

  @override
  Widget build(BuildContext context) {
    if (_status.isGranted == true) {
      return SongsScreen(_songs, _artists, _albums);
    } else {
      return Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            height: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text(
                  'Storage Access Permission',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20.0),
                ),
                const Icon(
                  Icons.error_outline,
                  size: 72.0,
                  color: MyColors.accentColor,
                ),
                const Text(
                  'You need to grant storage access permission for the app to work.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MyColors.accentColor, fontSize: 16.0),
                ),
                TextButton(
                  style: ButtonStyle(foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) => Colors.white)),
                  onPressed: () async {
                    AndroidIntent intent = const AndroidIntent(
                      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                      data: 'package:com.musicplayerbyercan.music_player_by_ercan',
                      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                    );
                    await intent.launch();
                    //openAppSettings();
                  },
                  child: const Text('GRANT PERMISSION'),
                ),
                const Text(
                  '\nYou should restart the app after granting the permission.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MyColors.accentColor, fontSize: 16.0),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
