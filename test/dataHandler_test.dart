import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:hundetage/utilities/dataHandling.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(dataHandler.connectionStatus.online, true);
      expect(dataHandler.offlineData, false);
      await dataHandler.loadData();
      expect(dataHandler.hero.values, Held.initial().values);
      dataHandler.generalData = await dataHandler.futureGeneralData;
      expect(dataHandler.generalData.gendering, genderingMockData);
      for(String _erlebniss in dataHandler.generalData.erlebnisse.keys) {
        for (String _key in dataHandler.generalData.erlebnisse[_erlebniss].toMap
            .keys) {
              expect(dataHandler.generalData.erlebnisse[_erlebniss].toMap[_key],
              erlebnisseMockData[_erlebniss][_key]);
      }}
      dataHandler.stories = await dataHandler.futureStories;
      for(String _storyTitle in dataHandler.stories.keys) {
        expect(dataHandler.stories[_storyTitle].zusammenfassung, adventure['zusammenfassung']);
        expect(_storyTitle, adventure['name']);
        Map<String,dynamic> _story = dataHandler.stories[_storyTitle].screensJSON;
        for (String _screen in _story.keys) {
          expect(_story[_screen]['text'], adventure['screens'][_screen]['text']);
          for(String _key in _story[_screen].keys){
            if(_key != 'text'){
              for(String _item in _story[_screen][_key].keys){
                expect(_story[_screen][_key][_item], adventure['screens'][_screen][_key][_item]);
              }
            }
          }
      }}

      //See if we can update data as well
      when(mockDocumentSnapshotGendering.data).thenReturn(genderingMockDataUpdate);
      when(mockDocumentSnapshotAbenteuer.data).thenReturn(adventureUpdate);
      dataHandler.firestore = mockFirestore;
      dataHandler.firebaseVersions = VersionController.fromMap(versionDataUpdate);
      expect((await dataHandler.updateGeneralDataFromTheWeb()).gendering, genderingMockDataUpdate);
      expect((await dataHandler.updateStoryDataFromTheWeb())['Raja'].zusammenfassung, adventureUpdate['zusammenfassung']);
    });

  test('Load Data from local File', () async {
    dataHandler.connectionStatus.online = false;
    dataHandler.offlineData = true;
    //Load Firestore data and write loaded data to disk
    expect(dataHandler.connectionStatus.online, false);
    expect(dataHandler.offlineData, true);
    //TODO: Add more tests here
  });

  });
}
