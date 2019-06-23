import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';

//Helper class to check online-offline status
class ConnectionStatus{
  bool online = false;

  //The test to actually see if there is a connection
  Future<void> checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    online = (connectivityResult == ConnectivityResult.mobile
        || connectivityResult == ConnectivityResult.wifi);
  }
}

//Loads current version information from firebase
Future<VersionController> loadVersionInformation({Firestore firestore}) async {
  CollectionReference _collectionReference = firestore.collection('general_data');
  DocumentReference _documentReference = _collectionReference.document('firebase_versions');
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  return new VersionController.fromMap(_documentSnapshot.data);
}

Map<String,Map<String,String>> generalDataFromDynamic(Map<dynamic, dynamic> mapIn) {
  Map<String, Map<String, String>> mapOut = {};

  for (String _outerKey in mapIn.keys) {
    List _innerKeys = mapIn[_outerKey].keys.toList();
    mapOut[_outerKey] = {};
    for (String _innerKey in _innerKeys) {
      mapOut[_outerKey][_innerKey] = mapIn[_outerKey][_innerKey];
    }
  }
  return mapOut;
}

//Loads data needed by all adventures from firestore
Future<GeneralData> loadGeneralData(Firestore firestore) async {
  Map<String,Map<String,String>> _gendering = await loadGendering(firestore);
  Map<String, Erlebniss> _erlebnisse = await loadErlebnisse(firestore);
  return new GeneralData(gendering: _gendering, erlebnisse: _erlebnisse);
}

Future<Map<String,Erlebniss>> loadErlebnisse(Firestore firestore) async {
  CollectionReference _collectionReference = firestore.collection('general_data');
  DocumentReference _documentReference = _collectionReference.document('erlebnisse');
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  return transformErlebnisse(_documentSnapshot.data);
}

Map<String,Erlebniss> transformErlebnisse(Map<String,dynamic> data){
  Map<String, Erlebniss> _erlebnisseOut = Map();
  Map<String,Map<String,String>> _erlebnisseIn = generalDataFromDynamic(data);

  for(String _key in _erlebnisseIn.keys){
    _erlebnisseOut[_key] = Erlebniss(text: _erlebnisseIn[_key]['text'],
        title: _erlebnisseIn[_key]['title'],
        image: Image.network(_erlebnisseIn[_key]['image']),
        url: _erlebnisseIn[_key]['image']);
  }
  return _erlebnisseOut;
}

Future<Map<String,Map<String,String>>> loadGendering(Firestore firestore) async {
  CollectionReference _collectionReference = firestore.collection('general_data');
  DocumentReference _documentReference = _collectionReference.document('gendering');
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  return generalDataFromDynamic(_documentSnapshot.data);
}

//Loads story from firestore
Future<Geschichte> loadGeschichte({Firestore firestore, Geschichte story}) async {
  CollectionReference _collection = firestore.collection('abenteuer');
  DocumentReference _documentReference = _collection.document(story.storyname);
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  story.setStory(_documentSnapshot.data['screens']);
  return story;
}

//Loads all stories data from firestore
Future<Map<String,Geschichte>> loadGeschichten({Firestore firestore}) async {
  CollectionReference _collection = firestore.collection('abenteuer');
  QuerySnapshot _queryReference = await _collection.getDocuments();
  List<DocumentSnapshot> allStories = _queryReference.documents;

  Map<String, Geschichte> _stories = Map<String, Geschichte>();
  for(DocumentSnapshot _story in allStories){
    String _storyname = _story.data['name'];
    _story.data['url'] = _story.data['image'];

    //Save image to local file - we do this here so we don't load stuff twice...
    await saveImageToFile(url: _story.data['url'],
        filename: _story.data['name']);

    Image _image = Image.network(_story.data['url'], fit: BoxFit.cover);
    _story.data['image'] = _image;

    _stories[_storyname] = Geschichte.fromFirebaseMap(_story.data);
    //Add actual data - make sure we have the right one
    _stories[_storyname].setStory(_story.data['screens']);
  }
  return _stories;
}