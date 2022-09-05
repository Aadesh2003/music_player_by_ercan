// To parse this JSON data, do
//
//     final stationData = stationDataFromJson(jsonString);

// ignore_for_file: prefer_single_quotes

import 'dart:convert';

import 'package:on_audio_query/on_audio_query.dart';
// List<PlayListDataModel> stationDataFromJson(String str) => List<PlayListDataModel>.from(json.decode(str).map((x) => PlayListDataModel.fromJson(x)));

String stationDataToJson(List<PlayListDataModel> data) => json.encode(List<dynamic>.from(data.map((PlayListDataModel x) => x.toJson())));
class PlayListDataModel {
  PlayListDataModel({
    this.name,
    this.dateCreated,
    this.songs,
  });

  String? name;
  String? dateCreated;
  List<SongModel>? songs;


  factory PlayListDataModel.fromJson(Map<String, dynamic> json) => PlayListDataModel(
    name: json["name"],
    dateCreated: json["dateCreated"],
    songs: List<SongModel>.from(json["songs"].map((x) => SongModel(x))),
  );



  Map<String, dynamic> toJson() => {
    "name": name,
    "dateCreated": dateCreated,
    "songs": songs!.map((e) => e.info).toList(),
  };
}



