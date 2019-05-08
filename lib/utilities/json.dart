import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:hundetage/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hundetage/main_screen.dart';

Future<String> get _localPath async {
  final Directory directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> _localFile(String filename) async {
  final String path = await _localPath;
  return File('$path/'+filename+'.json');
}

Future<bool> fileExists(File file) async{
  return file.exists();
}

//Write and read functions for user data
Future<File> writeLocalUserData(Held hero) async {
  final File file = await _localFile('hero');
  final String _jsonString = json.encode(hero.values);

  return file.writeAsString(_jsonString);
}

Future<Held> loadLocalUserData() async {
  final File file = await _localFile('hero');

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
  final File file = await _localFile('hero');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Write and read functions for story data
Future<File> writeLocalStoryData(Geschichte abenteuer) async {
  final File file = await _localFile(abenteuer.storyname);
  final String _jsonString = json.encode(abenteuer.data);

  return file.writeAsString(_jsonString);
}

Future<Geschichte> loadLocalStoryData(Geschichte abenteuer) async {
  final File file = await _localFile(abenteuer.storyname);

  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _map = json.decode(contents);
    abenteuer.setStory(_map);

    return abenteuer;
  }
  else {
    return null;
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
}

Future<File> writeLocalGenderingData(GeneralData generalData) async {
  final File file = await _localFile('gendering_data');
  final String _jsonString = json.encode(generalData.values['gendering']);

  return file.writeAsString(_jsonString);
}

Future<GeneralData> loadLocalGenderingData(GeneralData generalData) async {
  final File file = await _localFile('gendering_data');

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
  final File file = await _localFile('gendering_data');

  if(await fileExists(file)){
    await file.delete();
  }
}

Future<File> writeLocalErlebnisseData(GeneralData generalData) async {
  final File file = await _localFile('erlebnisse_data');
  final String _jsonString = json.encode(generalData.values['erlebnisse']);
  return file.writeAsString(_jsonString);
}

Future<GeneralData> loadLocalErlebnisseData(GeneralData generalData) async {
  final File file = await _localFile('erlebnisse_data');

  if(await fileExists(file)){
    String contents = await file.readAsString();
    Map<String, dynamic> _map = json.decode(contents);

    generalData.setErlebnisse = _map;
    return generalData;
  }
  else {
    return null;
  }
}

Future<void> deleteLocalErlebnisseData() async{
  final File file = await _localFile('erlebnisse_data');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Write and read functions for general data
Future<File> writeLocalVersionData(VersionController versionController) async {
  final File file = await _localFile('version_data');
  final String _jsonString = json.encode(versionController.values);

  return file.writeAsString(_jsonString);
}

Future<VersionController> loadLocalVersionData() async {
  final File file = await _localFile('version_data');

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
  final File file = await _localFile('version_data');

  if(await fileExists(file)){
    await file.delete();
  }
}

//Helper function to see if we can work in offline mode
Future<bool> canWorkOffline() async {
  final File _storyData = await _localFile('version_data');
  final File _genderingData = await _localFile('gendering_data');
  final File _erlebnisseData = await _localFile('erlebnisse_data');
  return (await fileExists(_storyData)
   || await fileExists(_genderingData)
   || await fileExists(_erlebnisseData));
}

//TODO: Add image caching