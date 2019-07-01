import 'package:hundetage/utilities/dataHandling.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MockDocumentReference extends Mock implements DocumentReference {}
class MockFirestore extends Mock implements Firestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

//Mock class-instances needed in all tests involving classes initialized from Firebase
Firestore mockFirestore = MockFirestore();

CollectionReference mockCollectionReference = MockCollectionReference();

DocumentSnapshot mockDocumentSnapshotGendering = MockDocumentSnapshot();
DocumentSnapshot mockDocumentSnapshotErlebnisse = MockDocumentSnapshot();
DocumentSnapshot mockDocumentSnapshotVersions = MockDocumentSnapshot();
DocumentSnapshot mockDocumentSnapshotAbenteuer = MockDocumentSnapshot();
DocumentSnapshot mockDocumentSnapshotAbenteuerMetadata = MockDocumentSnapshot();

DocumentReference mockDocumentReferenceGendering = MockDocumentReference();
DocumentReference mockDocumentReferenceErlebnisse = MockDocumentReference();
DocumentReference mockDocumentReferenceVersions = MockDocumentReference();
DocumentReference mockDocumentReferenceAbenteuer = MockDocumentReference();
QuerySnapshot mockQuerySnapshot = MockQuerySnapshot();

Map<String,Map<String,String>> genderingMockData = {'ErSie':{'m':'Er','w':'Sie'}, 
'eineine':{'m':'ein','w':'eine'}, 'wahrerwahre':{'m':'wahrer','w':'wahre'}, 'HeldHeldin':{'m':'Held','w':'Heldin'}};

Map<String,Map<String,String>> genderingMockDataUpdate = {'ErSie':{'m':'Er','w':'Sie'}, 
'eineine':{'m':'ein','w':'eine'}, 'wahrerwahre':{'m':'wahrer','w':'wahre'}, 'HeldHeldin':{'m':'Held','w':'Heldin'},
'TesterTesterin':{'m':'Tester','w':'Testerin'}};

Map<String,dynamic> erlebnisseMockData = {
  'besteFreunde':{'title': 'Beste Freunde', 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'image': 'https://example.com/image.png', 'url': 'https://example.com/image.png'},
  'alteFrau':{'title': 'Alte Frau', 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'image': 'https://example.com/image.png', 'url': 'https://example.com/image.png'}};

Map<String,Erlebniss> erlebnisseMap = {
  'besteFreunde': Erlebniss(text: erlebnisseMockData['besteFreunde']['text'],
  title: erlebnisseMockData['besteFreunde']['title'], url: erlebnisseMockData['besteFreunde']['url'],
  image: Image.asset('assets/images/icon.png')),
  'alteFrau': Erlebniss(text: erlebnisseMockData['alteFrau']['text'],
  title: erlebnisseMockData['alteFrau']['title'], url: erlebnisseMockData['alteFrau']['url'],
  image: Image.asset('assets/images/icon.png')),
};

Map<String,double> versionData = {'Raja': 1.1, 'erlebnisse': 0.71, 'gendering': 0.9};
Map<String,double> versionDataUpdate = {'Raja': 1.11, 'erlebnisse': 0.71, 'gendering': 1.0};

Map<String, dynamic> adventure = {
  'zusammenfassung': 'Eine schöne Geschichte',
  'name': 'Raja',
  'screens': {
    '0': {'conditions': {'0':''}, 'erlebnisse': {'0':''},
      'forwards': {'0':'1'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
      'options': {'0':'test0'}},
    '1':{'conditions': {'0': '', '1': ''}, 'erlebnisse': {'0':'alteFrau', '1': ''},
      'forwards': {'0':'0', '1': '1'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
      'options': {'0':'new page', '1': 'test'}}}};

Map<String, dynamic> adventureUpdate = {
  'zusammenfassung': 'Eine neue schöne Geschichte',
  'name': 'Raja',
  'screens': {
    '0': {'conditions': {'0':''}, 'erlebnisse': {'0':''},
      'forwards': {'0':'1'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
      'options': {'0':'test0'}},
    '1':{'conditions': {'0': '', '1': ''}, 'erlebnisse': {'0':'alteFrau', '1': ''},
      'forwards': {'0':'0', '1': '1'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
      'options': {'0':'new page', '1': 'test'}}}};

class StaticTestWidget extends StatelessWidget{
  final Widget returnWidget;
  StaticTestWidget({this.returnWidget});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
        body: returnWidget));
  }
}
