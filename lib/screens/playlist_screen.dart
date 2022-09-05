// ignore_for_file: use_key_in_widget_constructors, unused_field, prefer_single_quotes, avoid_print, must_be_immutable, prefer_final_fields, always_specify_types, prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:music_player_by_ercan/screens/playlist_inner_screen.dart';
import 'package:music_player_by_ercan/models/playlist_model.dart';
import 'package:music_player_by_ercan/prefrences/playlist_pref.dart';


class PlayListScreen extends StatefulWidget {
   List<PlayListDataModel> _playLists;
  final Function _goToAlbum;
   List<PlayListDataModel> playListdata = [];


   PlayListScreen(this._playLists, this._goToAlbum,this.playListdata);

  @override
  State<PlayListScreen> createState() => _PlayListScreenState();
}

class _PlayListScreenState extends State<PlayListScreen> {




  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("something");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
        key: const ValueKey<String>('albumscreen_1'),
        scrollbarOrientation: ScrollbarOrientation.right,
        interactive: true,
        thumbColor: Colors.grey,
        minThumbLength: 36.0,
        thickness: 4.0,
        crossAxisMargin: 3.0,
        radius: const Radius.circular(24.0),
        child: ListView.builder(
            key: const PageStorageKey<String>('albumscreen'),
            restorationId: 'albumscreen',
            padding: const EdgeInsets.only(bottom: 68.0),
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.playListdata.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 7.5, 5.0, 0.0),
                child: Slidable(
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
                            content: Text("Do you really wan't to remove this playlist ?"),
                            actions: [
                              MaterialButton(onPressed: (){
                                Navigator.pop(context);
                              },child: Text("No"),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),),
                              MaterialButton(onPressed: () async {
                                widget.playListdata.remove(widget.playListdata[index]);
                                var encodedResult = jsonEncode(widget.playListdata);
                                var tmp = jsonEncode(encodedResult);
                                await PlaylistPref().addString(tmp);
                                setState(() {

                                });
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
                  child: Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(10),
                     color: (Colors.grey
                         .shade900),
                   ),
                    child: ListTile(
                      title: Text(
                        widget.playListdata[index].name!,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          '${widget.playListdata[index].songs!.length.toString()} songs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayListInnerScreen(widget.playListdata[index].songs!, [], [],widget.playListdata[index].name!,widget.playListdata)));
                        // widget._goToAlbum(index, 1);
                        List<PlayListDataModel> playListdata = [];
                        var prefData = await PlaylistPref().getString();
                        var data = jsonDecode(jsonDecode(prefData));
                        if (data.isNotEmpty || data != null) {
                          for (var i = 0; i < data.length; i++) {
                            PlayListDataModel songs =
                            PlayListDataModel.fromJson(data[i]);
                            playListdata.add(songs);
                          }
                        }
                        widget.playListdata = playListdata;
                      },
                      // leading: ClipRRect(
                      //   borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      //   child: QueryArtworkWidget(
                      //     id: _albums[index].id,
                      //     type: ArtworkType.AUDIO,
                      //   )
                      // ),
                      contentPadding: const EdgeInsets.only(left: 8.0, right: 16.0, top: 4.0),
                      dense: true,
                      visualDensity: const VisualDensity(horizontal: 1.0, vertical: 1.0),
                    ),
                  ),
                ),
              );
            }));
  }
}
