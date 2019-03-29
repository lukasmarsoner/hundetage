import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';

void main() {
  testWidgets('Test user image selector', (WidgetTester _tester) async {
    UserImageRow _widget = UserImageRow(hero: testHeld,heroCallback: ({Held newHero})=>null);
    await _tester.pumpWidget(
        StaticTestWidget(returnWidget: _widget)
    );

    //See if user image is there
    final _findUserImage = find.byType(CircleAvatar);
    expect(_findUserImage, findsNWidgets(2));
    //See if buttons are there
    final _findButtons = find.byType(IconButton);
    expect(_findButtons, findsNWidgets(2));

    //Define variable used for comparison
    int _iBildToBe = _widget.hero.iBild;
    //Click on backward button
    await _tester.tap(_findButtons.first);
    //See if image has changes
    _iBildToBe -= 1;
    _widget.hero.iBild < 0?_iBildToBe=_widget.hero.maxImages:_iBildToBe=_widget.hero.iBild;
    expect(_widget.hero.iBild, _iBildToBe);

    //Click on forward button
    await _tester.tap(_findButtons.first);
    //See if image has changes
    _iBildToBe += 1;
    _widget.hero.iBild < 0?_iBildToBe=_widget.hero.maxImages:_iBildToBe=_widget.hero.iBild;
    expect(_widget.hero.iBild, _iBildToBe);

    //Swipe image backward
    await _tester.drag(_findUserImage.last, Offset(20.0, 0.0));
    //See if image has changes
    _iBildToBe += 1;
    _widget.hero.iBild < 0?_iBildToBe=_widget.hero.maxImages:_iBildToBe=_widget.hero.iBild;
    expect(_widget.hero.iBild, _iBildToBe);

    //Swipe image forward
    await _tester.drag(_findUserImage.last, Offset(-20.0, 0.0));
    //See if image has changes
    _iBildToBe += 1;
    _widget.hero.iBild < 0?_iBildToBe=_widget.hero.maxImages:_iBildToBe=_widget.hero.iBild;
    expect(_widget.hero.iBild, _iBildToBe);
  });

  testWidgets('Test user name setting', (WidgetTester _tester) async {
    UserNameField _widget = UserNameField(
        hero: testHeld, heroCallback: ({Held newHero}) => null);
    await _tester.pumpWidget(
        StaticTestWidget(returnWidget: _widget)
    );

    //See if user name field is there
    final _findTextField = find.byType(TextField);
    expect(_findTextField, findsOneWidget);

    //See if we can change the name
    String _testName = 'Teemu';
    await _tester.enterText(_findTextField, _testName);
    expect(_widget.hero.name, _testName);
  });

  testWidgets('Test gender settings', (WidgetTester _tester) async {
    GenderSelector _widget = GenderSelector(
        hero: testHeld, heroCallback: ({Held newHero}) => null);
    await _tester.pumpWidget(
        StaticTestWidget(returnWidget: _widget)
    );

    //See if user gender-selection looks as it should
    final _findGenderButtons = find.byType(IconButton);
    expect(_findGenderButtons, findsNWidgets(2));
    //here I assume the male icon is the first to be added...
    //Don't really like this - this should be more general
    //Depending on the gender we need to click on the right icons to change it
    String _genderIs = _widget.hero.geschlecht;
    Finder _firstButton = _genderIs=='w'?_findGenderButtons.first:_findGenderButtons.last;
    Finder _secondButton = _genderIs=='w'?_findGenderButtons.last:_findGenderButtons.first;
    await _tester.tap(_firstButton);
    await _tester.pumpAndSettle();
    //Check if gender has changed
    expect(_widget.hero.geschlecht==_genderIs, false);

    //Clicking the same button again should do nothing
    _genderIs = _widget.hero.geschlecht;
    await _tester.tap(_firstButton);
    await _tester.pumpAndSettle();
    //Check if gender has changed
    expect(_widget.hero.geschlecht==_genderIs, true);

    //And for completeness' sake - go back
    _genderIs = _widget.hero.geschlecht;
    await _tester.tap(_secondButton);
    await _tester.pumpAndSettle();
    //Check if gender has changed
    expect(_widget.hero.geschlecht==_genderIs, false);
  });
  }