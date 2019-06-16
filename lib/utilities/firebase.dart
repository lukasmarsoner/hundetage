import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Loads current version information from firebase
Future<VersionController> loadVersionInformation({Firestore firestore}) async {
  CollectionReference _collectionReference = firestore.collection('general_data');
  DocumentReference _documentReference = _collectionReference.document('firebase_versions');
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  return new VersionController.fromMap(_documentSnapshot.data);
}

Map<String,Map<String,String>> generalDataFromDynamic(Map<dynamic, dynamic> mapIn) {
  Map<String, Map<String, String>> mapOut = {};
  List<String> outerKeys = mapIn.keys.toList();

  for (int i = 0; i < outerKeys.length; i++) {
    List innerKeys = mapIn[outerKeys[i]].keys.toList();
    mapOut[outerKeys[i]] = {};
    for (int j = 0; j < innerKeys.length; j++) {
      mapOut[outerKeys[i]][innerKeys[j]] = mapIn[outerKeys[i]][innerKeys[j]];
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
  List<String> _keys = _erlebnisseIn.keys.toList();

  for(int i=0;i<_keys.length;i++){
    _erlebnisseOut[_keys[i]] = Erlebniss(text: _erlebnisseIn[_keys[i]]['text'],
        image: Image.network(_erlebnisseIn[_keys[i]]['image']),
        url: _erlebnisseIn[_keys[i]]['image']);
  }
  return _erlebnisseOut;
}

Future<Map<String,Map<String,String>>> loadGendering(Firestore firestore) async {
  CollectionReference _collectionReference = firestore.collection('general_data');
  DocumentReference _documentReference = _collectionReference.document('gendering');
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  return generalDataFromDynamic(_documentSnapshot.data);
}

//Loads user data from firestore
Future<Held> loadFirestoreUserData({Firestore firestore, Authenticator authenticator}) async {
  String uid = await authenticator.getUid();

  CollectionReference _collectionReference = firestore.collection('user_data');

  DocumentReference _documentReference = _collectionReference.document(uid);
  DocumentSnapshot _documentSnapshot = await _documentReference.get();

  if(_documentSnapshot == null)
  {return null;}
  else{
  Map<String,dynamic> _userData = _documentSnapshot.data;
  _userData['erlebnisse'] = List<String>.from(_userData['erlebnisse']);
  _userData['screens'] = List<int>.from(_userData['screens']);
  return new Held.fromMap(_userData);
  }
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
  for(int i=0;i<allStories.length;i++){
    String _storyname = allStories[i].data['name'];
    allStories[i].data['url'] = allStories[i].data['image'];

    //Save image to local file - we do this here so we don't load stuff twice...
    await saveImageToFile(url: allStories[i].data['url'],
        filename: allStories[i].data['name']);

    Image _image = Image.network(allStories[i].data['url'], fit: BoxFit.cover);
    allStories[i].data['image'] = _image;

    _stories[_storyname] = Geschichte.fromFirebaseMap(allStories[i].data);
    //Add actual data - make sure we have the right one
    _stories[_storyname].setStory(allStories[i].data['screens']);
  }
  return _stories;
}


//Updates user data in firestore
//If the file does not exist - create a new entry
void updateCreateFirestoreUserData({Firestore firestore, Authenticator authenticator,
Held hero, String uid}) async {
  if(uid==null){uid = await authenticator.getUid();}

  CollectionReference _collectionReference = firestore.collection('user_data');

  DocumentReference _documentReference = _collectionReference.document(uid);

  _documentReference.setData(hero.values);
}

//Deletes entry from firebase
void deleteFirestoreUserData({Firestore firestore, FirebaseUser user}) async {
  String uid = user.uid;

  CollectionReference _collectionReference = firestore.collection('user_data');

  DocumentReference _documentReference = _collectionReference.document(uid);
  await _documentReference.delete();
  await user.delete();
}