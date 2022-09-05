// ignore_for_file: always_specify_types, must_be_immutable, use_key_in_widget_constructors, always_declare_return_types, prefer_const_constructors, prefer_single_quotes, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_player_by_ercan/colors.dart';
import 'package:music_player_by_ercan/models/playlist_model.dart';
import 'package:music_player_by_ercan/prefrences/playlist_pref.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongSelectionScreen extends StatefulWidget {
  String? playListName;

  SongSelectionScreen({this.playListName});

  @override
  State<SongSelectionScreen> createState() => _SongSelectionScreenState();
}

class _SongSelectionScreenState extends State<SongSelectionScreen> {
  List<SongModel>? songs;
  List<SongModel>? selectedSongs = [];
  var isLoading = true;

  getSongs() async {
    songs = await OnAudioQuery().querySongs();
    isLoading = false;
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSongs();
  }

  @override
  Widget build(BuildContext context) {
    // selectedSongs!.clear();
    // print(songs![4].id);
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text("Select Songs"),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                          itemCount: songs!.length,
                          shrinkWrap: true,
                          itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: AppBarTheme.of(context)
                                          .backgroundColor,
                                      borderRadius: BorderRadius.circular(15)),
                                  // color: Colors./,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedSongs!.contains(songs![i])) {
                                        selectedSongs!.remove(songs![i]);
                                      } else {
                                        selectedSongs!.add(songs![i]);
                                      }
                                      print(selectedSongs!.length);
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListTile(
                                        trailing:
                                            !selectedSongs!.contains(songs![i])
                                                ? Icon(
                                                    Icons.add_circle_outline,
                                                    color: Colors.grey,
                                                  )
                                                : Icon(
                                                    Icons.check_circle,
                                                    color: MyColors.accentColor,
                                                  ),
                                        title: Text(songs![i].title),
                                        subtitle: Text(songs![i].artist!),
                                        leading: QueryArtworkWidget(
                                            type: ArtworkType.AUDIO,
                                            id: songs![i].id,
                                            size: 40,
                                            nullArtworkWidget: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(400),
                                              child: Image.asset(
                                                  "assets/music.png"),
                                            )),
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        try {
                          List<PlayListDataModel> playListdata = [];
                          var prefData = await PlaylistPref().getString();
                          print(prefData);
                        if(prefData != null ){
                          var data = jsonDecode(jsonDecode(prefData));
                          if (data.isNotEmpty || data != null) {
                            for (var i = 0; i < data.length; i++) {
                              PlayListDataModel songs =
                              PlayListDataModel.fromJson(data[i]);
                              playListdata.add(songs);
                            }
                          }
                        }
                          playListdata.add(PlayListDataModel(
                              name: widget.playListName,
                              dateCreated: DateTime.now().toString(),
                              songs: selectedSongs),);
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
                      },
                      padding: EdgeInsets.all(15),
                      color: MyColors.darkColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Text("Create playList"),
                    )
                  ],
                ),
              ));
  }
}
