import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
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
    'erlebnisse': new List<String>(0)};

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
    (valIn != null || valIn.length == 0)?_name = valIn:_name = _defaults['name'];
  }
  set geschlecht(String valIn){
    (valIn!="m" && valIn!="w")?_geschlecht = valIn:_geschlecht = _defaults['geschlecht'];
  }
  set iBild(int valIn){
    (valIn != null && valIn < maxImages)?_iBild = valIn:_iBild = _defaults['iBild'];
  }
  set maxImages(int valIn){
    (valIn!=null && valIn!=0)?_maxImages=valIn:throw("Null or zero Held images!");
  }
  set erlebniss(String valIn){
    if(valIn != null && !_erlebnisse.contains(valIn)){_erlebnisse.add(valIn);}
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