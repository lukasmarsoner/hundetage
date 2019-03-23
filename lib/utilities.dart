import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String,dynamic> parseJSON(String _unparsedJSON) {
  final _parsedJSON = json.decode(_unparsedJSON).cast<Map<String, dynamic>>();
  return _parsedJSON;
}

//We probably don't need this but this keeps things consistent for when we
//want to load data from the web later
Future<Map<String,dynamic>> loadJsonAsset(String filename) async {
  String _unparsedJson = await rootBundle.loadString(filename);
  return compute(parseJSON, _unparsedJson);
}