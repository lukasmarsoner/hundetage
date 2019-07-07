import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/screens/userChat.dart';
import 'package:hundetage/utilities/dataHandling.dart';

void main() {

  DataHandler dataHandler = new DataHandler();
  dataHandler.firestore = mockFirestore;
  dataHandler.connectionStatus.online = true;
  dataHandler.offlineData = false;

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

      expect(find.byKey(Key('Posted Message')), findsNWidgets(3));
      expect(find.byKey(Key('Posted Image')), findsOneWidget);

      //Send a response
      expect(find.byKey(Key('Chat Text Field')), findsOneWidget);
      await _tester.enterText(find.byKey(Key('Chat Text Field')), 'Test');
      await _tester.tap(find.byKey(Key('Send Message')));
      
      await _tester.pumpAndSettle(Duration(minutes: 10));
      expect(find.byKey(Key('Posted Message')), findsNWidgets(4));

      expect(find.byKey(Key('Kein Bild')), findsOneWidget);
    });
  });
}