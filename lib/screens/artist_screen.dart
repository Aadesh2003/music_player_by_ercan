// ignore_for_file: use_key_in_widget_constructors, non_constant_identifier_names, unrelated_type_equality_checks
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../colors.dart';


//Problem in this screen

class ArtistScreen extends StatelessWidget {
  final List<ArtistModel> _artists;
  final List<AlbumModel> _albums;
  final Function _goToArtist, _goToAlbum;

  const ArtistScreen(this._artists, this._albums, this._goToArtist, this._goToAlbum);

  void _showAlbums(int index, BuildContext _context) async {
    // getAlbumsFromArtist(artist: _artists[index].name)
    List<SongModel> _Albums = await OnAudioQuery().queryAudiosFrom(AudiosFromType.ARTIST, _artists[index]);
    showModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      isScrollControlled: true,
      backgroundColor: MyColors.accentColor,
      transitionAnimationController: AnimationController(
        vsync: Scaffold.of(_context),
        duration: const Duration(milliseconds: 500),
      ),
      context: _context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Albums by ${_artists[index].artist}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24.0,
                    color: MyColors.darkColor,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: _Albums.map(
                  (SongModel e) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                        leading: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          child: QueryArtworkWidget(
                            id: e.id,
                            type: ArtworkType.AUDIO,

                          ),
                          // child: (e. != null && File(e.albumArt).existsSync() == true)
                          //     ? Image.file(
                          //         File(e.albumArt),
                          //         fit: BoxFit.contain,
                          //       )
                          //     : Image.asset('assets/neon_headset.jpg'),
                        ),
                        title: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MyColors.darkColor,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          e.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          for (int i = 0; i < _albums.length; i++) {
                            if (_albums[i].album == e.album) {
                              _goToAlbum(i, 1);
                              break;
                            }
                          }
                        },
                      ),
                      if (_Albums.length > (_Albums.indexOf(e) + 1))
                        const Divider(
                          height: 0.0,
                          thickness: 0.5,
                          color: MyColors.darkColor,
                        ),
                    ],
                  ),
                ).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      key: const ValueKey<String>('artistscreen_1'),
      scrollbarOrientation: ScrollbarOrientation.right,
      interactive: true,
      thumbColor: Colors.grey,
      minThumbLength: 36.0,
      thickness: 4.0,
      crossAxisMargin: 3.0,
      radius: const Radius.circular(24.0),
      child: ListView.builder(
          key: const PageStorageKey<String>('artistscreen'),
          restorationId: 'artistscreen',
          padding: const EdgeInsets.only(bottom: 68.0),
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: _artists.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 7.5, 5.0, 0.0),
              child: ListTile(
                title: Text(
                  _artists[index].artist,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(fontSize: 18.0),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    '${_artists[index].numberOfTracks} songs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                onTap: () {
                  _goToArtist(index, 1);
                },
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        _showAlbums(index, context);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(
                              Icons.album,
                              color: MyColors.accentColor,
                              size: 24.0,
                            ),
                            Text('Albums', style: TextStyle(fontSize: 11.0, color: MyColors.accentColor))
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _goToArtist(index, 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(
                              Icons.music_note_outlined,
                              color: MyColors.accentColor,
                              size: 24.0,
                            ),
                            Text(' Songs ', style: TextStyle(fontSize: 11.0, color: MyColors.accentColor))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
                dense: true,
                visualDensity: const VisualDensity(horizontal: 1.0, vertical: 1.0),
              ),
            );
          }),
    );
  }
}
