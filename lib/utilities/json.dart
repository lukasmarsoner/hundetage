import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:path_provider/path_provider.dart';

Future<File> saveImageToFile({String url, String filename}) async{
  var response = await http.get(url);
  List<int> bytes = response.bodyBytes.toList();
  File file = await localFile(filename, 'jpg');
  return file.writeAsBytes(bytes);
}

Future<Image> loadImageFromFile(String filename) async{
  File file = await localFile(filename, 'jpg');
  if(await fileExists(file)){
    List<int> bytes = await file.readAsBytes();
    return Image.memory(bytes, fit: BoxFit.cover);
  }
  else{return null;}
}

Future<String> get localPath async {
  final Directory directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> localFile(String filename, [String type]) async {
  final String path = await localPath;
  //Most used are for JSON so we default to it
  if(type==null){type='json';}
  return File('$path/'+filename+'.'+type);
}

Future<bool> fileExists(File file) async{
  return file.exists();
}

//Write and read functions for user data
Future<File> writeLocalUserData(Held hero) async {
  final File file = await localFile('hero');
  final String _jsonString = json.encode(hero.values);

  return file.writeAsString(_jsonString);
}

Future<Held> loadLocalUserData() async {
  final File file = await localFile('hero');

  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _heroMap = json.decode(contents);
    _heroMap['erlebnisse'] = List<String>.from(_heroMap['erlebnisse']);
    _heroMap['screens'] = List<int>.from(_heroMap['screens']);

  return Held.fromMap(_heroMap);
  }
  else {
    return Held.initial();
  }
}

Future<void> deleteLocalUserData() async{
  final File file = await localFile('hero');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Write and read functions for story data
Future<void> writeAllLocalStoriesData(Map<String,Geschichte> stories) async {
  //Loop through stories and write them to file
  List<String> _keys = stories.keys.toList();
  for(int i=0; i<_keys.length; i++){
    writeLocalStoryData(stories[_keys[i]]);
  }
}

//Write and read functions for story data
Future<File> writeLocalStoryData(Geschichte story) async {
  final File file = await localFile('stories');

  //If the file is already there update or add the story
  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _map = json.decode(contents);
    Map<String,dynamic> _newStory = Map<String,dynamic>();
    _newStory['screens'] = story.allKeysToString();
    _newStory['zusammenfassung'] = story.zusammenfassung;
    _map[story.storyname] = _newStory;
    final String _jsonString = json.encode(_map);
    //Writing the image to file is done at loading from firebase so we don't
    //need to do it here
    return file.writeAsString(_jsonString);
  }
  //If no file is there yet - create a new one from scratch
  else{
    Map<String,dynamic> _map = Map<String,dynamic>();
    _map[story.storyname] = Map<String,dynamic>();
    _map[story.storyname]['screens'] = story.screensJSON;
    _map[story.storyname]['zusammenfassung'] = story.zusammenfassung;
    final String _jsonString = json.encode(_map);
    return file.writeAsString(_jsonString);
  }
}

//Load data for all stories from file
Future<Map<String,Geschichte>> loadAllLocalStoryData() async {
  final File file = await localFile('stories');

  if(!(await fileExists(file))){
    return null;
  }
  else {
    //Create list for output
    Map<String,Geschichte> stories = Map<String,Geschichte>();

    //Load json file into memory
    String contents = await file.readAsString();
    Map<String, dynamic> jsonFile = json.decode(contents);

    //Variable for looping through the file
    List<String> _keys = jsonFile.keys.toList();
    for (int i = 0; i < _keys.length; i++) {
      String storyname = _keys[i];
      stories[storyname] = await loadLocalStoryData(jsonFile: jsonFile, storyname: storyname);
    }
    return stories;
  }
}

//Load one single story from JSON
Future<Geschichte> loadLocalStoryData({Map<String, dynamic> jsonFile, String storyname}) async {
  Image _image = await loadImageFromFile(storyname);

  Geschichte _story = Geschichte(storyname: storyname);
  _story.setFromJSON(imageIn: _image, screensJSON: jsonFile[storyname]['screens'],
      summary: jsonFile[storyname]['zusammenfassung']);
  return _story;
}

Future<void> deleteLocalStoryData() async {
  final File file = await localFile('stories');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Write and read functions for general data
Future<void> writeLocalGeneralData(GeneralData generalData) async {
  writeLocalErlebnisseData(generalData);
  writeLocalGenderingData(generalData);
}

Future<GeneralData> loadLocalGeneralData() async {
  //Initialize an empty instance
  GeneralData generalData = new GeneralData(erlebnisse: null, gendering: null);
  //Load needed data from local files
  generalData = await loadLocalErlebnisseData(generalData);
  generalData = await loadLocalGenderingData(generalData);

  return generalData;
}

Future<void> deleteLocalGeneralData() async{
  await deleteLocalGenderingData();
  await deleteLocalErlebnisseData();
  await deleteLocalErlebnisseData();
}

Future<File> writeLocalGenderingData(GeneralData generalData) async {
  final File file = await localFile('gendering_data');
  final String _jsonString = json.encode(generalData.values['gendering']);

  return file.writeAsString(_jsonString);
}

Future<GeneralData> loadLocalGenderingData(GeneralData generalData) async {
  final File file = await localFile('gendering_data');

  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _map = json.decode(contents);

    generalData.setGendering = _map;
    return generalData;
  }
  else {
    return null;
  }
}

Future<void> deleteLocalGenderingData() async{
  final File file = await localFile('gendering_data');

  if(await fileExists(file)){
    await file.delete();
  }
}

Future<File> writeLocalErlebnisseData(GeneralData generalData) async {
  //Write images to file
  //TODO: load this during first loading as we do for story images
  List<String> _keys = generalData.erlebnisse.keys.toList();
  for(int i=0;i<_keys.length;i++){
    //First write image to disk - then write the data to JSON
    await saveImageToFile(url: generalData.erlebnisse[_keys[i]].url,
        filename: _keys[i]);
  }

  final File file = await localFile('erlebnisse_data');
  final String _jsonString = json.encode(generalData.values['erlebnisse']);
  return file.writeAsString(_jsonString);
}

Future<GeneralData> loadLocalErlebnisseData(GeneralData generalData) async {
  final File file = await localFile('erlebnisse_data');

  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _map = json.decode(contents);
    Map<String, Erlebniss> _mapOut = Map();

    //Load images associated with experiences
    List<String> _keys = _map.keys.toList();
    for(int i=0;i<_keys.length;i++){
      _mapOut[_keys[i]] = Erlebniss(image:await loadImageFromFile(_keys[i]),
      text: _map[_keys[i]]['text'], url: _map[_keys[i]]['image']);
    }
    generalData.setErlebnisse = _mapOut;
    return generalData;
  }
  else {
    return null;
  }
}

Future<void> deleteLocalErlebnisseData() async{
  final File file = await localFile('erlebnisse_data');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Write and read functions for general data
Future<File> writeLocalVersionData(VersionController versionController) async {
  final File file = await localFile('version_data');
  final String _jsonString = json.encode(versionController.values);

  return file.writeAsString(_jsonString);
}

Future<VersionController> loadLocalVersionData() async {
  final File file = await localFile('version_data');

  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _map = json.decode(contents);

    return VersionController.fromMap(_map);
  }
  else {
    return null;
  }
}

Future<void> deleteLocalVersionData() async{
  final File file = await localFile('version_data');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Helper function to see if we can work in offline mode
Future<bool> canWorkOffline() async {
  final File _versionData = await localFile('version_data');
  final File _genderingData = await localFile('gendering_data');
  final File _erlebnisseData = await localFile('erlebnisse_data');
  final File _storiesData = await localFile('stories');

  bool _canWorkOffline = await fileExists(_versionData)
      && await fileExists(_genderingData)
      && await fileExists(_storiesData)
      && await fileExists(_erlebnisseData);

  return _canWorkOffline;
}