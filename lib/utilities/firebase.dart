import 'dart:async';
import 'package:hundetage/main.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Loads data needed by all adventures from firestore
Future<GeneralData> loadGeneralData(Firestore firestore) async {
  Map<String,Map<String,String>> fromDynamic(Map<dynamic, dynamic> mapIn){
    Map<String,Map<String,String>> mapOut = {};
    List<String> outerKeys = mapIn.keys.toList();

    for(int i=0;i<outerKeys.length;i++){
      List innerKeys = mapIn[outerKeys[i]].keys.toList();
      mapOut[outerKeys[i]] = {};
      for(int j=0;j<innerKeys.length;j++){
        mapOut[outerKeys[i]][innerKeys[j]] =  mapIn[outerKeys[i]][innerKeys[j]];
      }
    }
    return mapOut;
  }

  CollectionReference _collectionReference = firestore.collection('general_data');

  DocumentReference _genderingReference = _collectionReference.document('gendering');
  DocumentReference _erlebnisseReference = _collectionReference.document('erlebnisse');

  DocumentSnapshot _genderingSnapshot = await _genderingReference.get();
  DocumentSnapshot _erlebnisseSnapshot = await _erlebnisseReference.get();

  Map<String,Map<String,String>> _gendering = fromDynamic(_genderingSnapshot.data);
  Map<String,Map<String,String>> _erlebnisse = fromDynamic(_erlebnisseSnapshot.data);

  return new GeneralData(gendering: _gendering, erlebnisse: _erlebnisse);
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
  Map<String,String> _userData = _documentSnapshot.data;
  return new Held.fromMap(_userData);
  }
}

//Updates user data in firestore
//If the file does not exist - create a new entry
void updateCreateFirestoreUserData({Firestore firestore, Authenticator authenticator,
Held hero}) async {
  String uid = await authenticator.getUid();

  CollectionReference _collectionReference = firestore.collection('user_data');

  DocumentReference _documentReference = _collectionReference.document(uid);
  _documentReference.setData(hero.values);
}

//Deletes entry from firebase
void deleteFirestoreUserData({Firestore firestore, Authenticator authenticator}) async {
  String uid = await authenticator.getUid();

  CollectionReference _collectionReference = firestore.collection('user_data');

  DocumentReference _documentReference = _collectionReference.document(uid);
  _documentReference.delete();
}