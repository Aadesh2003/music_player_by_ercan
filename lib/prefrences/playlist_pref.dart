// ignore_for_file: always_declare_return_types

import 'package:shared_preferences/shared_preferences.dart';

class PlaylistPref{
  addString(String string) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('playlist', string);
  }

  getString() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString('playlist');
  }
}