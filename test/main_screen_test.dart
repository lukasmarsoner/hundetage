import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/main_screen.dart';
import 'package:flutter/material.dart';
import 'utilities.dart';

void main() {
  // Test top panels of main menu
  testWidgets('Test main-screen', (WidgetTester _tester) async {
    await _tester.pumpWidget(
        StaticTestWidget(returnWidget: ProfileRow(hero: testHeld, imageHeight: 200.0))
    );

    //See if the main screen looks as it should
    final _findUsername = find.text(testHeld.name);
    final String _beruf = testHeld.berufe[testHeld.iBild][testHeld.geschlecht];
    final _findJob = find.text(_beruf);
    final _userImage = find.byType(CircleAvatar);

    expect(_userImage, findsNWidgets(2));
    expect(_findUsername, findsOneWidget);
    expect(_findJob, findsOneWidget);
  });

  // Test menu
  testWidgets('Test menu', (WidgetTester _tester) async {
    AnimatedButton _widget = AnimatedButton(hero: testHeld,updateHero: ()=>null);
    await _tester.pumpWidget(
        StaticTestWidget(returnWidget: _widget)
    );

    //See if icon is there
    var _findMenuIcon = find.byIcon(Icons.settings);
    expect(_findMenuIcon, findsOneWidget);

    //Click on menu
    var _findButton = find.byType(FloatingActionButton);
    expect(_findButton, findsOneWidget);
    await _tester.tap(find.byType(FloatingActionButton));
    //Wait for animation to terminate
    await _tester.pumpAndSettle();
    //Check if Icon has changed
    var _findChangedMenuIcon = find.byIcon(Icons.supervisor_account);
    expect(_findChangedMenuIcon, findsOneWidget);
    //Check if menu items are now there
    _findMenuIcon = find.byIcon(Icons.cloud_queue);
    expect(_findMenuIcon, findsOneWidget);
    _findMenuIcon = find.byIcon(Icons.account_circle);
    expect(_findMenuIcon, findsOneWidget);
    _findMenuIcon = find.byIcon(Icons.add_a_photo);
    expect(_findMenuIcon, findsOneWidget);

    //Click menu again and check it has been closed
    //Click on menu
    _findButton = find.byType(FloatingActionButton);
    expect(_findButton, findsOneWidget);
    await _tester.tap(find.byType(FloatingActionButton));
    //Wait for animation to terminate
    await _tester.pumpAndSettle();
    //Check if Icon has changed
    _findChangedMenuIcon = find.byIcon(Icons.settings);
    expect(_findChangedMenuIcon, findsOneWidget);
    //Check if menu items are now there
    _findMenuIcon = find.byIcon(Icons.cloud_queue);
    expect(_findMenuIcon, findsNothing);
    _findMenuIcon = find.byIcon(Icons.account_circle);
    expect(_findMenuIcon, findsNothing);
    _findMenuIcon = find.byIcon(Icons.add_a_photo);
    expect(_findMenuIcon, findsNothing);
  });

  testWidgets('Test License', (WidgetTester _tester) async {
    MainPage _widget = MainPage(hero: testHeld,heroCallback: ()=>null);
      await _tester.pumpWidget(
          StaticTestWidget(returnWidget: _widget));

      //Click on license button
      var _findButton = find.byType(IconButton);
      expect(_findButton, findsOneWidget);
      await _tester.tap(find.byType(IconButton));
      //Wait for animation to terminate
      await _tester.pumpAndSettle();
      //Check Title is there
      var _findTitleText = find.text('Licenses');
      expect(_findTitleText, findsOneWidget);
      //Check App Title is maintained
      var _findAppText = find.text('Hundetage');
      expect(_findAppText, findsOneWidget);
      });
}