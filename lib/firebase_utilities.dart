import 'dart:async';
import 'main.dart';
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