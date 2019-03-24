import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String, dynamic> parseJSON(String _unparsedJSON) {
  final _parsedJSON = json.decode(_unparsedJSON);
  return _parsedJSON;
}

Future<Map<String, dynamic>> loadJsonAsset(String filename) async {
  String _unparsedJson = await rootBundle.loadString(filename);
  return compute(parseJSON, _unparsedJson);
}