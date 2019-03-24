import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/main.dart';

void main() {
  test('Test adventure backend functions', () async {
    GeneralData _generalData = GeneralData();
    _generalData = await _generalData.updateFromJson();

    //Test some of the possible substitutions
    Map _testData = {
      'eineine':{'m': 'ein', 'w': 'eine'},
      'HeldHeldin':{'m': 'Held', 'w': 'Heldin'},
      'ersie':{'m': 'er', 'w': 'sie'}};
    List _testKeys = _testData.keys;
    for(int i;i<_testKeys.length;i++) {
      expect(_generalData.gendering[_testKeys[i]]['w'], _testData[i]['w']);
      expect(_generalData.gendering[_testKeys[i]]['m'], _testData[i]['m']);
    }
  });
  }