import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/services.dart';


//Stuff needed for mocking Firestore calls
class MockDocumentReference extends Mock implements DocumentReference {}
class MockFirestore extends Mock implements Firestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  //Mocks calls to the application directory
  setUpAll(() async {
    // Create a temporary directory to work with
    final directory = await Directory.systemTemp.createTemp();

    // Mock out the MethodChannel for the path_provider plugin
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      // If you're getting the apps documents directory, return the path to the
      // temp directory on the test environment instead.
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return directory.path;
      }
      return null;
    });
  });

  group('Tests involving Firebase', () {
    //Mocks calls to the application directory
    setUpAll(() async {
      // Create a temporary directory to work with
      final directory = await Directory.systemTemp.createTemp();

      // Mock out the MethodChannel for the path_provider plugin
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        // If you're getting the apps documents directory, return the path to the
        // temp directory on the test environment instead.
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return directory.path;
        }
        return null;
      });
    });

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

    //Group ends here
  });
}