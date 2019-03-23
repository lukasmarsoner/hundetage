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