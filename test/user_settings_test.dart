import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';

void main() {
  // Stuff we need for testing
  final Held _testHeld = new Held.initial();

  // Test user menu - here we test the menu as a whole
  testWidgets('Test user menu', (WidgetTester _tester) async {
    AnimatedButton _widget = AnimatedButton(hero: _testHeld,updateHero: ()=>null);
    await _tester.pumpWidget(
        StaticTestWidget(returnWidget: _widget)
    );

  });
}