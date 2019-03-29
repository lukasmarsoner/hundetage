import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';

void main() {
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
      expect(_testHeld.maxImages, _testHeld.defaults['maxImages']);
      expect(_testHeld.erlebnisse, _testHeld.defaults['erlebnisse']);
      expect(_testHeld.berufe.length,_testHeld.maxImages+1);
      //Check that descriptions are set for al heros
      for(int i=0;i<_testHeld.berufe.length;i++){
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
      _testHeld.maxImages=10;
      _testHeld.addErlebniss='test';

      expect(_testHeld.iBild, 3);
      expect(_testHeld.name, 'test');
      expect(_testHeld.geschlecht, 'w');
      expect(_testHeld.maxImages, 10);
      expect(_testHeld.erlebnisse, ['test']);

      _testHeld.addErlebniss='';
      expect(_testHeld.erlebnisse,['test']);

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

      try{_testHeld.maxImages=-1;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid number of images!');
      try{_testHeld.maxImages=null;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid number of images!');
      try{_testHeld.maxImages=2;} on Exception catch(error){_error = error.toString();}
      expect(_error, 'Exception: Invalid number of images!');
    });

  });
}