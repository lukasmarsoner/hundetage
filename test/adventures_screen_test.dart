import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hundetage/screens/adventures.dart';
import 'package:hundetage/utilities/dataHandling.dart';

void main() {
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

    testWidgets('Test Profile-Row', (WidgetTester _tester) async {
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

      await _tester.pumpWidget(StaticTestWidget(returnWidget: GeschichteMainScreen(dataHandler: dataHandler)));

      expect(find.byKey(Key('Loading Story Screen')), findsOneWidget);
      expect(find.byKey(Key('Inactive User Button')), findsOneWidget);
      expect(find.byKey(Key('Inactive Mail Button')), findsOneWidget);
      await _tester.pumpAndSettle();
      expect(find.byKey(Key('Main Story Screen')), findsOneWidget);
      expect(find.byKey(Key('User Button')), findsOneWidget);
      expect(find.byKey(Key('Active Mail Button')), findsOneWidget);

      await _tester.tap(find.byKey(Key('User Button')));
      await _tester.pumpAndSettle();
      expect(find.byKey(Key('User Name Dialog')), findsOneWidget);
      await _tester.tap(find.byKey(Key('Active Mail Button')));
      await _tester.pumpAndSettle();
      //First tap just gets us out of the dialog
      await _tester.tap(find.byKey(Key('Active Mail Button')));
      await _tester.pumpAndSettle();
      expect(find.byKey(Key('Mail Dialog')), findsOneWidget);
      expect(find.byKey(Key('Camera Icon')), findsOneWidget);
      expect(find.byKey(Key('Send Icon')), findsOneWidget);

      await _tester.tap(find.byKey(Key('Erlebnisse Menu')));
      await _tester.pumpAndSettle();
      //First tap just gets us out of the dialog
      await _tester.tap(find.byKey(Key('Erlebnisse Menu')));
      await _tester.pumpAndSettle();

      expect(find.byKey(Key('Beste Freunde')), findsOneWidget);
      expect(find.byKey(Key('Erlebniss Image')), findsOneWidget);
    });

    testWidgets('Test Story-forwarting', (WidgetTester _tester) async {
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

      await _tester.pumpWidget(StaticTestWidget(returnWidget: GeschichteMainScreen(dataHandler: dataHandler)));
      await _tester.pumpAndSettle();

      expect(find.byKey(Key('Story Text 0')), findsOneWidget);
      expect(find.byKey(Key('Screen 0 Option 0')), findsOneWidget);
      String _optionText = adventure['screens']['0']['options']['0'];
      expect(find.text(_optionText), findsOneWidget);
      await _tester.tap(find.text(_optionText));
      await _tester.pumpAndSettle();

      expect(find.byKey(Key('Story Text 1')), findsOneWidget);
      expect(find.byKey(Key('Screen 1 Option 0')), findsOneWidget);
      _optionText = adventure['screens']['1']['options']['0'];
      expect(find.text(_optionText), findsOneWidget);
      await _tester.tap(find.text(_optionText));
      await _tester.pumpAndSettle();
      expect(find.byKey(Key('Story Text 0')), findsOneWidget);
      expect(find.byKey(Key('Screen 0 Option 0')), findsOneWidget);
    });
  });
}
