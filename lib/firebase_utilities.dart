import 'dart:async';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Loads data needed by all adventures from firestore
Future<GeneralData> loadGeneraldata(Firestore firestore) async {
  CollectionReference _collectionReference = firestore.collection('general_data');

  DocumentReference _genderingReference = _collectionReference.document('gendering');
  DocumentReference _erlebnisseReference = _collectionReference.document('erlebnisse');

  DocumentSnapshot _genderingSnapshot = await _genderingReference.get();
  DocumentSnapshot _erlebnisseSnapshot = await _erlebnisseReference.get();

  Map<String,Map<String,String>> _gendering = _genderingSnapshot.data;
  Map<String,Map<String,String>> _erlebnisse = _erlebnisseSnapshot.data;

  return new GeneralData(gendering: _gendering, erlebnisse: _erlebnisse);
}