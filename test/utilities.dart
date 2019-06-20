import 'package:flutter/material.dart';
import 'package:hundetage/utilities/dataHandling.dart';

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

//Mock class-instances needed in all tests involving classes initialized from Firebase
final Firestore mockFirestore = MockFirestore();

final CollectionReference mockCollectionReference = MockCollectionReference();

final DocumentSnapshot mockDocumentSnapshotGendering = MockDocumentSnapshot();
final DocumentSnapshot mockDocumentSnapshotErlebnisse = MockDocumentSnapshot();
final DocumentSnapshot mockDocumentSnapshotVersions = MockDocumentSnapshot();
final DocumentSnapshot mockDocumentSnapshotUser = MockDocumentSnapshot();
final DocumentSnapshot mockDocumentSnapshotAbenteuer = MockDocumentSnapshot();
final DocumentSnapshot mockDocumentSnapshotAbenteuerMetadata = MockDocumentSnapshot();

final DocumentReference mockDocumentReferenceGendering = MockDocumentReference();
final DocumentReference mockDocumentReferenceErlebnisse = MockDocumentReference();
final DocumentReference mockDocumentReferenceVersions = MockDocumentReference();
final DocumentReference mockDocumentReferenceUser = MockDocumentReference();
final DocumentReference mockDocumentReferenceAbenteuer = MockDocumentReference();
final QuerySnapshot mockQuerySnapshot = MockQuerySnapshot();

geschichten['Raja'].screens = screens;
geschichten['Raja'].url = 'http://test.de';
geschichten['Raja'].image = null;
//Mock data handler
final DataHandler dataHandler = DataHandler(firestore: mockFirestore);
dataHandler.hero = testHeld;
dataHandler.substitution = substitutions;
dataHandler.generalData = generalData;
dataHandler.stories = geschichten;

//Mock the collection
when(mockFirestore.collection('general_data')).thenReturn(mockCollectionReference);
//Mock both documents
when(mockCollectionReference.document('gendering')).thenReturn(mockDocumentReferenceGendering);
when(mockDocumentReferenceGendering.get()).thenAnswer((_) async => mockDocumentSnapshotGendering);
when(mockDocumentSnapshotGendering.data).thenReturn(genderingMockData);

when(mockCollectionReference.document('erlebnisse')).thenReturn(mockDocumentReferenceErlebnisse);
when(mockDocumentReferenceErlebnisse.get()).thenAnswer((_) async => mockDocumentSnapshotErlebnisse);
when(mockDocumentSnapshotErlebnisse.data).thenReturn(erlebnisseMockData);

when(mockCollectionReference.document('firebase_versions')).thenReturn(mockDocumentReferenceVersions);
when(mockDocumentReferenceVersions.get()).thenAnswer((_) async => mockDocumentSnapshotVersions);
when(mockDocumentSnapshotVersions.data).thenReturn(versionData);

when(mockFirestore.collection('user_data')).thenReturn(mockCollectionReference);
when(mockCollectionReference.document('hQtzTZdHkQde3dUxyZQ3EkzxYYn1')).thenReturn(mockDocumentReferenceUser);
when(mockDocumentReferenceUser.get()).thenAnswer((_) async => mockDocumentSnapshotUser);
when(mockDocumentSnapshotUser.data).thenReturn(testHeld.values);

when(mockFirestore.collection('abenteuer')).thenReturn(mockCollectionReference);
when(mockFirestore.collection('abenteuer_metadata')).thenReturn(mockCollectionReference);
when(mockCollectionReference.snapshots()).thenAnswer((_) => Stream.fromIterable([mockQuerySnapshot]));
when(mockQuerySnapshot.documents).thenReturn([mockDocumentSnapshotAbenteuerMetadata]);
when(mockCollectionReference.document('Raja')).thenReturn(mockDocumentReferenceAbenteuer);
when(mockDocumentReferenceAbenteuer.get()).thenAnswer((_) async => mockDocumentSnapshotAbenteuer);
when(mockDocumentSnapshotAbenteuer.data).thenReturn(screensFirebase);
when(mockDocumentSnapshotAbenteuerMetadata.data).thenReturn(adventureMetadata);


//Stuff needed by a number of tests
Map<String,Map<String,String>> genderingTestData = {'ErSie':{'m':'Er','w':'Sie'},
  'eineine':{'m':'ein','w':'eine'},
  'HeldHeldin':{'m':'Held','w':'Heldin'},
  'wahrerwahre':{'m':'wahrer','w':'wahre'}};

Map<String,Map<String,String>> erlebnisseTestData = {
  'besteFreunde':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'url': 'https://example.com/image.png'},
  'alteFrau':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'url': 'https://example.com/image.png'}};

//Data used for testing - we will return this in our mocked request to Firebase
//The data returnd from firebase is Map<dynamic,dynamic>, so the versions handed
//to the mock firebase should be of that same type. As tests seem to fail that
//way, we use the next-best thing
Map<String,dynamic> genderingMockData = {'ErSie':{'m':'Er','w':'Sie'},
  'eineine':{'m':'ein','w':'eine'},
  'HeldHeldin':{'m':'Held','w':'Heldin'},
  'wahrerwahre':{'m':'wahrer','w':'wahre'}};
Map<String,dynamic> erlebnisseMockData = {
  'besteFreunde':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'image': 'https://example.com/image.png'},
  'alteFrau':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'image': 'https://example.com/image.png'}};

Map<int,Map<String, dynamic>> screens = {
  0:
    {'conditions': {'0':'','1':''}, 'erlebnisse': {'0':'','1':''},
    'forwards': {'0':'1','1':'5'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'test0','1':'test1'}},
  1:{'conditions': {'0':''}, 'erlebnisse': {'0':'alteFrau'},
    'forwards': {'0':'0'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'new page'}}};

Map<String, dynamic> screensFirebase = {
  '0':
  {'conditions': {'0':'','1':''}, 'erlebnisse': {'0':'','1':''},
    'forwards': {'0':'1','1':'5'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'test0','1':'test1'}},
  '1':{'conditions': {'0':''}, 'erlebnisse': {'0':'alteFrau'},
    'forwards': {'0':'0'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'new page'}}};

Map<String, Geschichte> geschichten = {'Raja': Geschichte(storyname: 'Raja')};

Map<String, dynamic> adventureMetadata = {
  'name': 'Raja', 'image': 'https...'};

Map<String, double> versionData = {
  'gendering': 0.7, 'erlebnisse': 0.8, 'Raja': 0.8, 'GrosseFahrt': 0.0};

Map<String, dynamic> versionDataLower = {
  'gendering': 0.5, 'erlebnisse': 0.6, 'Raja': 0.8, 'GrosseFahrt': 0.0};

final testHeld = new Held.test();
final testGeschichte = new Geschichte.fromFirebaseMap(adventureMetadata);

final generalData = new GeneralData(erlebnisse: {'alteFrau':
Erlebniss(text: '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    image: Image.asset('images/icon.png'), title: 'Ein wahrer Held'),
'besteFreunde':
Erlebniss(text: '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    image: Image.asset('images/icon.png'), title: 'Ein wahrer Held')}
,gendering: genderingTestData);

final substitutions = new Substitution(hero: testHeld, generalData: generalData);
final versionController = new VersionController.fromMap(versionData);
