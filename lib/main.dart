import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'user_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState(){
    // Implement reading from file here
    return new _MyAppState(hero: new Held.initial());
  }
}

class _MyAppState extends State<MyApp> {
  Held hero;

  _MyAppState({this.hero});

  void heroCallback({Held newHero}){
    setState(() {hero = newHero;});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: new UserPage(hero: hero, heroCallback: heroCallback),
    );
  }
}

class Held{
  // Properties of users
  String _name, _geschlecht;
  int _iBild, _maxImages;
  List<String> _erlebnisse;

  // Default values for user
  Map<String,dynamic> _defaults = {
    'name': 'Teemu',
    'geschlecht': 'w',
    'iBild': 0,
    'maxImages': 5,
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
    (valIn != null && valIn >=0 && valIn < maxImages)?_iBild = valIn:throw new Exception('Invalid imange index!');
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
  // This getter is only for testing
  Map<String,dynamic> get defaults => _defaults;
}

