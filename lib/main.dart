import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';
import 'firebase_utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async{
  //GeneralData generalData = await initializeGeneralData();
  GeneralData generalData = await loadGeneralData(Firestore());
  runApp(MyApp(generalData: generalData));
}

class MyApp extends StatefulWidget{
  final GeneralData generalData;

  MyApp({this.generalData});

  @override
  _MyAppState createState(){
    return new _MyAppState(hero: new Held.initial(), generalData: generalData);
  }
}

//All global should be store and kept-updated here
class _MyAppState extends State<MyApp>{
  Held hero;
  GeneralData generalData;

  _MyAppState({this.hero, this.generalData});

  void heroCallback({Held newHero}){
    setState(() {hero = newHero;});
  }

  @override
  Widget build(BuildContext context){
    Substitution substitution = Substitution(hero: hero,generalData: generalData);
    return MaterialApp(
      title: 'Hundetage',
      home: Scaffold(body: MainPage(hero: hero, heroCallback: heroCallback,
          generalData: generalData, substitution:substitution)),
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

  // Default values for testing
  Map<String,dynamic> _testing = {
    'name': 'Mara',
    'geschlecht': 'w',
    'iBild': 0,
    'maxImages': 7,
    'erlebnisse': <String>['besteFreunde']};

  Held(this._name,this._geschlecht,this._iBild,this._maxImages,this._erlebnisse);

  // Initialize new User with defaults
  Held.initial(){
    _name = _defaults['name'];
    _geschlecht = _defaults['geschlecht'];
    _iBild = _defaults['iBild'];
    _maxImages = _defaults['maxImages'];
    _erlebnisse = _defaults['erlebnisse'];
  }

  //Used for testing widgets
  Held.test(){
    _name = _testing['name'];
    _geschlecht = _testing['geschlecht'];
    _iBild = _testing['iBild'];
    _maxImages = _testing['maxImages'];
    _erlebnisse = _testing['erlebnisse'];
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

class Adventure{
  // Properties of adventures
  String name;
  int version;
  Map<int,Map<String,dynamic>> story;

  Adventure({this.name,this.version,this.story});

  factory Adventure.fromJson(Map<String, dynamic> _jsonData){
    return Adventure(
        name:_jsonData['name'],
        version: _jsonData['version'],
        story: _jsonData['story']
    );
  }

}

class GeneralData{
  //Contains stuff needed by all adventures
  //gendering contains mappings for male/female versions of words
  //erlebnisse contains all possible memories that can be collected during the adventures
  Map<String,Map<String,String>> gendering;
  Map<String,Map<String,String>> erlebnisse;

  GeneralData({this.gendering,this.erlebnisse});
}

//From here we handle gendering and name substitutions
class Substitution{
  final GeneralData generalData;
  final Held hero;

  Substitution({this.hero, this.generalData});

  //Substitute gendered Versions of Words
  _applyGenderSubstitutions(String textIn){
    List<String> _keys = generalData.gendering.keys.toList();
    for(int i=0;i<_keys.length;i++){
      String _substring = generalData.gendering[_keys[i]][hero.geschlecht];
      textIn = textIn.replaceAll('#'+_keys[i], _substring);
    }
    return textIn;
  }

  //Substitute username in text - in the future more might happen here...
  _applyNameSubstitutions(String textIn){
    textIn = textIn.replaceAll('#username', hero.name);
    return textIn;
  }

  applyAllSubstitutions(String textIn){
    textIn = _applyGenderSubstitutions(textIn);
    textIn = _applyNameSubstitutions(textIn);
    return textIn;
  }
}