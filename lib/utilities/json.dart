import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:hundetage/main.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/hero.json');
}

Future<bool> fileExists(File file) async{
  return file.exists();
}

Future<File> writeLocalUserData(Held hero) async {
  final file = await _localFile;
  final _jsonString = json.encode(hero.values);

  return file.writeAsString(_jsonString);
}

Future<Held> loadLocalUserData() async {
  final file = await _localFile;

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
