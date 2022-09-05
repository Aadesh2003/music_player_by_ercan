// ignore_for_file: use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumScreen extends StatefulWidget {
  final List<AlbumModel> _albums;
  final Function _goToAlbum;

  const AlbumScreen(this._albums, this._goToAlbum);

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {

  getSongs(AlbumModel album) async{
    List<SongModel> songs = [];
    List<SongModel> querySongs = await OnAudioQuery().querySongs();
    for(var i=0;i<querySongs.length;i++){
      if(querySongs[i].albumId == album.id){
        songs.add(querySongs[i]);
      }
    }
    return songs;
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
            itemCount: widget._albums.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 7.5, 5.0, 0.0),
                child: ListTile(
                  title: Text(
                    widget._albums[index].album,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${widget._albums[index].artist} ・ ${widget._albums[index].numOfSongs} songs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  onTap: () async {
                    // List<SongModel> songs = await getSongs(widget._albums[index]);
                    // Navigator.push(context, MaterialPageRoute(builder:(context) => AlbumInnerScreen(songs, [], widget._albums, "${widget._albums[index].album}",)));
                    widget._goToAlbum(index, 1);
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
              );
            }));
  }
}
