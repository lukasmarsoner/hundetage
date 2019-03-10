import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/main.dart';

void main() {
  group('SetGet', () {
    test('Initialize with defaults', () {
      final _testHeld = new Held.initial();
      expect(_testHeld.iBild, _testHeld.defaults['iBild']);
      expect(_testHeld.name, _testHeld.defaults['name']);
      expect(_testHeld.geschlecht, _testHeld.defaults['geschlecht']);
      expect(_testHeld.maxImages, _testHeld.defaults['maxImages']);
      expect(_testHeld.erlebnisse, _testHeld.defaults['erlebnisse']);
    });

  });
}