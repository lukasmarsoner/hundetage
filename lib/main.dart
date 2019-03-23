import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState(){
    // Implement reading from file here
    return new _MyAppState(hero: new Held.initial());
  }
}

//All user information should be store and kept-updated here
class _MyAppState extends State<MyApp> {
  Held hero;

  _MyAppState({this.hero});

  void heroCallback({Held newHero}){
    setState(() {hero = newHero;});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hundetage',
      home: Scaffold(body: MainPage(hero: hero, heroCallback: heroCallback)),
    );
  }
}

class Held{
  // Properties of users
  String _name, _geschlecht;
  int _iBild, _maxImages;
  List<String> _erlebnisse;
  Map<int,Map<String,String>> _berufe = {
    0: {'m': 'Ein gewiefter Abenteurer', 'w': 'Eine gewiefte Abenteurerin'},
    1: {'m': 'Der stärkste Hund im Land', 'w': 'Die stärkste Hündin im Land'},
    2: {'m': 'Hat schon alles gesehen', 'w': 'Hat schon alles gesehen'},
    3: {'m': 'Nichts kann ihn aufhalten', 'w': 'Nichts kann sie aufhalten'},
    4: {'m': 'Der neugierigste Hund der Stadt', 'w': 'Die neugierigste Hündin der Stadt'},
    5: {'m': 'Ihm kann man nichts vormachen', 'w': 'Ihr kann man nichts vormachen'},
    6: {'m': 'Genauso wuschelig wie tapfer', 'w': 'Genauso wuschelig wie tapfer'},
    7: {'m': 'Dein bester Freund', 'w': 'Deine beste Freundin'}};

  // Default values for user
  Map<String,dynamic> _defaults = {
    'name': 'Mara',
    'geschlecht': 'w',
    'iBild': 0,
    'maxImages': 7,
    'erlebnisse': <String>[]};

  Held(this._name,this._geschlecht,this._iBild,this._maxImages,this._erlebnisse);

  // Initialize new User with defaults
  Held.initial(){
    _name = _defaults['name'];
    _geschlecht = _defaults['geschlecht'];
    _iBild = _defaults['iBild'];
    _maxImages = _defaults['maxImages'];
    _erlebnisse = _defaults['erlebnisse'];
  }

  // Setters with sanity-checks
  set name(String valIn){
    (valIn != null && valIn.length != 0)?_name = valIn:throw new Exception('Invalid name!');
  }
  set geschlecht(String valIn){
    (valIn=='m' || valIn=='w')?_geschlecht = valIn:throw new Exception('Invalid sex!');
  }
  set iBild(int valIn){
    (valIn != null && valIn >=0 && valIn <= maxImages)?_iBild = valIn:throw new Exception('Invalid imange index!');
  }
  set maxImages(int valIn){
    (valIn!=null && valIn>iBild && valIn!=0)?_maxImages=valIn:throw new Exception('Invalid number of images!');
  }
  set addErlebniss(String valIn){
    if(valIn != null && valIn != '' && !_erlebnisse.contains(valIn)){_erlebnisse.add(valIn);}
  }

  // Getters
  String get name => _name;
  int get iBild => _iBild;
  int get maxImages => _maxImages;
  String get geschlecht => _geschlecht;
  List<String> get erlebnisse => _erlebnisse;
  Map<int,Map<String,String>> get berufe => _berufe;
  // This getter is only for testing
  Map<String,dynamic> get defaults => _defaults;
}

