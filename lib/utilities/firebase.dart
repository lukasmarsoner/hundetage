import 'dart:async';
import 'package:hundetage/main.dart';
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
  Map<String,Map<String,String>> _erlebnisse = await loadErlebnisse(firestore);
  return new GeneralData(gendering: _gendering, erlebnisse: _erlebnisse);
}

Future<Map<String,Map<String,String>>> loadErlebnisse(Firestore firestore) async {
  CollectionReference _collectionReference = firestore.collection('general_data');
  DocumentReference _documentReference = _collectionReference.document('erlebnisse');
  DocumentSnapshot _documentSnapshot = await _documentReference.get();
  return generalDataFromDynamic(_documentSnapshot.data);
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

//Loads story data from firestore
Future<Geschichte> loadGeschichte({Firestore firestore, Geschichte geschichte}) async {
  CollectionReference _collectionReference = firestore.collection('abenteuer');
  DocumentReference _documentReference = _collectionReference.document(geschichte.storyname);
  DocumentSnapshot _documentSnapshot = await _documentReference.get();

  Map<String,dynamic> _screens = _documentSnapshot.data;
  geschichte.setStory(_screens);

  return geschichte;
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