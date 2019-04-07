import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:hundetage/utilities/json.dart';

void main() {
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

  group('Main Classes Unit-Tests', () {
    test('Substitutions', (){
      //Do the name-substitution here already
      String _testText = '#username ist cool. #ErSie ist #eineine #wahrerwahre #HeldHeldin!'
          .replaceAll('#username', testHeld.name);
      //This makes us independent of a future change in the default for hero-gender
      String _extectedW = _testText.replaceAll('#ErSie', 'Sie').replaceAll('#HeldHeldin', 'Heldin')
          .replaceAll('#eineine', 'eine').replaceAll('#wahrerwahre', 'wahre');
      String _extectedM = _testText.replaceAll('#ErSie', 'Er').replaceAll('#HeldHeldin', 'Held')
          .replaceAll('#eineine', 'ein').replaceAll('#wahrerwahre', 'wahrer');
      String _substitutedText = substitutions.applyAllSubstitutions(_testText);
      //Check if the name has been substituted correctly
      testHeld.geschlecht=='w'?expect(_substitutedText,_extectedW):expect(_substitutedText,_extectedM);
    });

    test('Initialize with defaults', () {
      final _testHeld = new Held.initial();
      expect(_testHeld.iBild, _testHeld.defaults['iBild']);
      expect(_testHeld.name, _testHeld.defaults['name']);
      expect(_testHeld.geschlecht, _testHeld.defaults['geschlecht']);
      expect(_testHeld.erlebnisse, _testHeld.defaults['erlebnisse']);
      expect(_testHeld.screens, _testHeld.defaults['screens']);
      expect(_testHeld.iScreen, _testHeld.defaults['iScreen']);
      //The +2 comes from:
      //0-indexing
      //Using -1 for a placeholder
      expect(_testHeld.berufe.length,_testHeld.maxImages+2);
      //Check that descriptions are set for al heros
      for(int i=0;i<_testHeld.berufe.length-1;i++){
        expect(_testHeld.berufe[i].keys.length,2);
        expect(_testHeld.berufe[i]['w'],isNotEmpty);
        expect(_testHeld.berufe[i]['m'],isNotEmpty);
      }
    });

    test('Set values ', () {
      final _testHeld = new Held.initial();
      _testHeld.iBild=3;
      _testHeld.name='test';
      _testHeld.geschlecht='w';
      _testHeld.addErlebniss='test';
      _testHeld.addScreen=4;
      _testHeld.iScreen=4;

      expect(_testHeld.iBild, 3);
      expect(_testHeld.name, 'test');
      expect(_testHeld.geschlecht, 'w');
      expect(_testHeld.erlebnisse, ['test']);
      expect(_testHeld.iScreen, 4);
      expect(_testHeld.screens, [4]);

      _testHeld.addErlebniss='';
      expect(_testHeld.erlebnisse,['test']);
      _testHeld.addScreen=4;
      expect(_testHeld.screens,[4]);

      String _error;
      try{_testHeld.iBild=-1;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid imange index!');
      try{_testHeld.iBild=null;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid imange index!');

      try{_testHeld.name='';} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid name!');
      try{_testHeld.name=null;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid name!');

      try{_testHeld.geschlecht='q';} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid sex!');
      try{_testHeld.geschlecht=null;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid sex!');
    });

    test('Load from JSON', () async {
      //Write user data to file
      writeLocalUserData(testHeld);
      Held _tmpHeld = await loadLocalUserData();
      expect(_tmpHeld.values, testHeld.values);
    });

  });
}