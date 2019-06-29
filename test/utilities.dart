import 'package:mockito/mockito.dart';
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

Map<String,Map<String,String>> genderingMockData = {'ErSie':{'m':'Er','w':'Sie'}, 'eineine':{'m':'ein','w':'eine'}};
Map<String,dynamic> erlebnisseMockData = {
  'besteFreunde':{'title': 'Beste Freunde', 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'image': 'https://example.com/image.png', 'url': 'https://example.com/image.png'},
  'alteFrau':{'title': 'Alte Frau', 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'image': 'https://example.com/image.png', 'url': 'https://example.com/image.png'}};
Map<String,double> versionData = {'Raja': 1.1, 'erlebnisse': 0.71, 'gendering': 0.9};
Map<String, dynamic> adventure = {
  'zusammenfassung': 'Eine schöne Geschichte',
  'name': 'Raja',
  'screens': {'0': {'conditions': {'0':'','1':''}, 'erlebnisse': {'0':'','1':''},
    'forwards': {'0':'1','1':'5'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'test0','1':'test1'}},
  '1':{'conditions': {'0':''}, 'erlebnisse': {'0':'alteFrau'},
    'forwards': {'0':'0'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'new page'}}}};

