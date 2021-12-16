// ignore_for_file: use_key_in_widget_constructors
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

class AlbumScreen extends StatelessWidget {
  final List<AlbumInfo> _albums;
  final Function _goToAlbum;

  const AlbumScreen(this._albums, this._goToAlbum);

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
            itemCount: _albums.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 7.5, 5.0, 0.0),
                child: ListTile(
                  title: Text(
                    _albums[index].title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${_albums[index].artist} ・ ${_albums[index].numberOfSongs} songs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  onTap: () {
                    _goToAlbum(index, 1);
                  },
                  leading: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                    child: (_albums[index].albumArt != null && File(_albums[index].albumArt).existsSync() == true)
                        ? Image.file(
                            File(_albums[index].albumArt),
                            fit: BoxFit.contain,
                          )
                        : Image.asset('assets/neon_headset.jpg'),
                  ),
                  contentPadding: const EdgeInsets.only(left: 8.0, right: 16.0, top: 4.0),
                  dense: true,
                  visualDensity: const VisualDensity(horizontal: 1.0, vertical: 1.0),
                ),
              );
            }));
  }
}
