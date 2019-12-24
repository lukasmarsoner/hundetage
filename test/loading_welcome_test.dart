import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mockito/mockito.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/screens/welcome.dart';
import 'package:flutter/services.dart';
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

  group('Welcome Screen Tests', () {
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
    testWidgets('Test Welcome Screen', (WidgetTester _tester) async {
      dataHandler.generalData = GeneralData.fromMap({'gendering': genderingMockData, 
      'erlebnisse': erlebnisseMap});
      dataHandler.stories = {'Raja': Geschichte.fromFirebaseMap(adventure)};
      dataHandler.stories['Raja'].setStory(adventure['screens']);
      dataHandler.hero = Held.initial();
      dataHandler.hero.name = 'Maya';
      dataHandler.hero.username = 'Maya';
      dataHandler.hero.geschlecht = 'w';
      dataHandler.hero.addErlebniss = 'besteFreunde';
      dataHandler.hero.analytics = null;
      dataHandler.hero.userImage = Image.asset('assets/images/icon.png');
      dataHandler.updateSubstitutions();

      await _tester.pumpWidget(StaticTestWidget(returnWidget: WelcomeScreen(dataHandler: dataHandler)));
      await _tester.pumpAndSettle();

      expect(find.text('Willkommen zurück ${dataHandler.hero.username}!'), findsOneWidget);
      expect(find.text('Schön, dass du wieder da bist'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
    
    testWidgets('Test Loading Screen', (WidgetTester _tester) async {
      dataHandler.generalData = GeneralData.fromMap({'gendering': genderingMockData, 
      'erlebnisse': erlebnisseMap});
      dataHandler.stories = {'Raja': Geschichte.fromFirebaseMap(adventure)};
      dataHandler.stories['Raja'].setStory(adventure['screens']);
      dataHandler.hero = Held.initial();
      dataHandler.hero.name = 'Maya';
      dataHandler.hero.username = 'Maya';
      dataHandler.hero.geschlecht = 'w';
      dataHandler.hero.addErlebniss = 'besteFreunde';
      dataHandler.hero.analytics = null;
      dataHandler.hero.userImage = Image.asset('assets/images/icon.png');
      dataHandler.updateSubstitutions();

      await _tester.pumpWidget(StaticTestWidget(returnWidget: SplashScreen()));
      
      expect(find.byKey(Key('Loading...')), findsOneWidget);
    });
  });
}
