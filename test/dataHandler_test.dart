import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:image_test_utils/image_test_utils.dart';
import 'package:hundetage/utilities/dataHandling.dart';

void main() {
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

  when(mockFirestore.collection('abenteuer')).thenReturn(mockCollectionReference);
  when(mockCollectionReference.getDocuments()).thenAnswer((_) async => mockQuerySnapshot);
  when(mockCollectionReference.document('Raja')).thenReturn(mockDocumentReferenceAbenteuer);
  when(mockDocumentReferenceAbenteuer.get()).thenAnswer((_) async => mockDocumentSnapshotAbenteuer);
  when(mockDocumentSnapshotAbenteuer.data).thenReturn(adventure);
  when(mockQuerySnapshot.documents).thenReturn([mockDocumentSnapshotAbenteuer]);

  DataHandler dataHandler = new DataHandler();
  dataHandler.firestore = mockFirestore;
  dataHandler.connectionStatus.online = true;
  dataHandler.offlineData = false;

  group('Main Classes Unit-Tests', () {
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
    
    //Tests start from here
    test('Load Data from Firebase', () async {
      provideMockedNetworkImages(() async {
      expect(dataHandler.connectionStatus.online, true);
      expect(dataHandler.offlineData, false);
      await dataHandler.loadData();
      expect(dataHandler.hero.values, Held.initial().values);
      expect(dataHandler.generalData.gendering, genderingMockData);
      for(String _erlebniss in dataHandler.generalData.erlebnisse.keys) {
        for (String _key in dataHandler.generalData.erlebnisse[_erlebniss].toMap
            .keys) {
          expect(dataHandler.generalData.erlebnisse[_erlebniss].toMap[_key],
              erlebnisseMockData[_erlebniss][_key]);
        }}
      });
    });

    test('Load Data from local File', () async {
      provideMockedNetworkImages(() async {
        dataHandler.connectionStatus.online = false;
        dataHandler.offlineData = true;
        //Load Firestore data and write loaded data to disk
        expect(dataHandler.connectionStatus.online, false);
        expect(dataHandler.offlineData, true);
        await dataHandler.loadData();
        expect(dataHandler.hero.values, Held
            .initial()
            .values);
        expect(dataHandler.generalData.gendering, genderingMockData);
        for (String _erlebniss in dataHandler.generalData.erlebnisse.keys) {
          for (String _key in dataHandler.generalData.erlebnisse[_erlebniss]
              .toMap.keys) {
            expect(dataHandler.generalData.erlebnisse[_erlebniss].toMap[_key],
                erlebnisseMockData[_erlebniss][_key]);
          }
        }
      });
    });

  });
}
