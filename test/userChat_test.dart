import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/screens/userChat.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'dart:io';

void main() {

  DataHandler dataHandler = new DataHandler();
  dataHandler.firestore = mockFirestore;
  dataHandler.connectionStatus.online = true;
  dataHandler.offlineData = false;

  setUpAll(() async {
    // Create a temporary directory.
    final directory = await Directory.systemTemp.createTemp();

    // Mock out the MethodChannel for the path_provider plugin.
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

  group('User Chat Tests', () {
    //Tests start from here
    testWidgets('Test User Chat', (WidgetTester _tester) async {
      dataHandler.generalData = GeneralData.fromMap({'gendering': genderingMockData, 
      'erlebnisse': erlebnisseMap});
      dataHandler.stories = {'Raja': Geschichte.fromFirebaseMap(adventure)};
      dataHandler.stories['Raja'].setStory(adventure['screens']);
      dataHandler.hero = Held.initial();

      await _tester.pumpWidget(StaticTestWidget(returnWidget: UserChat(dataHandler: dataHandler)));
      await _tester.pumpAndSettle(Duration(minutes: 3));

      expect(find.byKey(Key('Poste Message')), findsNWidgets(3));
      expect(find.byKey(Key('Poste Image')), findsOneWidget);

      //Send a response
      expect(find.byKey(Key('Chat Text Field')), findsOneWidget);
      await _tester.enterText(find.byKey(Key('Chat Text Field')), 'Test');
      await _tester.tap(find.byKey(Key('Send Message')));
      
      await _tester.pumpAndSettle(Duration(minutes: 10));
      expect(find.byKey(Key('Poste Message')), findsNWidgets(4));

      expect(find.byKey(Key('Kein Bild')), findsOneWidget);
      await _tester.tap(find.byKey(Key('Kein Bild')));
      await _tester.pumpAndSettle(Duration(minutes: 10));
      expect(find.byKey(Key('Boy-Girl Selection')), findsOneWidget);
      expect(find.byKey(Key('Button_m')), findsOneWidget);
      expect(find.byKey(Key('Button_w')), findsOneWidget);
      await _tester.tap(find.byKey(Key('Button_m')));
      await _tester.pumpAndSettle(Duration(minutes: 10));
      await _tester.enterText(find.byKey(Key('Chat Text Field')), 'Test');
      await _tester.tap(find.byKey(Key('Send Message')));
      await _tester.pumpAndSettle(Duration(minutes: 10));
    });

  });
}