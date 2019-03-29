import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/erlebnisse.dart';
import 'package:image_test_utils/image_test_utils.dart';

void main() {
  group('Test Erlebnisse Page', () {
    testWidgets('Test Profile-Row', (WidgetTester _tester) async {
      provideMockedNetworkImages(() async {
    ProfileRowErlebnisse _profileErlebnisse = new ProfileRowErlebnisse(hero: testHeld,imageHeight: 200.0);

    //Let's see if the widgets are there
    await _tester.pumpWidget(
    StaticTestWidget(returnWidget: _profileErlebnisse)
    );

    final _userImage = find.byType(CircleAvatar);
    expect(_userImage, findsNWidgets(2));

    });});

    testWidgets('Test Erlebnisse Page', (WidgetTester _tester) async {
      provideMockedNetworkImages(() async {
      Erlebnisse _erlebnisse = new Erlebnisse(hero: testHeld,substitution: substitutions,
      generalData: generalData);

      //Let's see if the widgets are there
      await _tester.pumpWidget(
          StaticTestWidget(returnWidget: _erlebnisse)
      );

      final _gridView = find.byType(GridView);
      expect(_gridView, findsOneWidget);
      final _positioned = find.byType(Positioned);
      expect(_positioned, findsOneWidget);
      final _padding = find.byType(Padding);
      expect(_padding, findsNWidgets(3));
      final _tile = find.byType(GridTile);
      expect(_tile, findsOneWidget);
      final _image = find.byType(Image);
      expect(_image, findsOneWidget);
    });
    });
  });
}