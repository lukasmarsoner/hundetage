import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'utilities/json.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async{
  Firestore firestore = Firestore();
  Held hero = new Held.initial();
  GeneralData generalData = await loadGeneralData(firestore);
  Authenticator authenticator = new Authenticator();
  Substitution substitution = Substitution(hero: hero,generalData: generalData);
  runApp(MyApp(generalData: generalData, authenticator: authenticator,
    hero: hero, substitution: substitution, firestore: firestore));
}

class MyApp extends StatefulWidget{
  final GeneralData generalData;
  final Authenticator authenticator;
  final Substitution substitution;
  final Firestore firestore;
  final Held hero;

  MyApp({@required this.generalData, @required this.authenticator,
    @required this.substitution, @required this.hero, @required this.firestore});

  @override
  _MyAppState createState(){
    return new _MyAppState(hero: hero, generalData: generalData,
    authenticator: authenticator, substitution: substitution,
    firestore: firestore);
  }
}

//All global should be store and kept-updated here
class _MyAppState extends State<MyApp>{
  Held hero;
  Authenticator authenticator;
  Substitution substitution;
  Firestore firestore;
  bool signedIn;
  GeneralData generalData;

  _MyAppState({@required this.hero, @required this.generalData,
    @required this.substitution, @required this.authenticator,
    @required this.firestore});

  void heroCallback({Held newHero}){
    setState(() {hero = newHero;});
    signedIn
        ?updateCreateFirestoreUserData(firestore: firestore,
        authenticator: authenticator, hero: hero)
        :writeLocalUserData(hero);
  }

  void signInStatusChange(){
    setState(() {
      signedIn?signedIn = false:signedIn = true;
    });
  }

  //Check if user is currently logged-in
  Future<bool> checkLoginStatus() async{
    if(await authenticator.getUsername()==null){return false;}else{return true;}
  }

  //Check if we are already logged-in
  @override
  void initState() {
    if(signedIn==null){
      //We set it here because the future takes longer to evaluate than the
      //screen takes to build
      signedIn = false;
      checkLoginStatus().then((_loggedIn){_loggedIn?signedIn=false:signedIn=true;});
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Hundetage',
      home: Scaffold(body: MainPage(hero: hero, heroCallback: heroCallback,
          authenticator: authenticator, signInStatusChange: signInStatusChange, signedIn: signedIn,
          generalData: generalData, substitution:substitution, firestore: firestore)),
    );
  }
}

class Held{
  // Properties of users
  //This is being set here. As user images are stored in the assets it will
  //never change in the live app
  int maxImages = 7;
  String _name, _geschlecht;
  int _iBild, _iScreen;
  List<String> _erlebnisse;
  List<int> _screens;
  Map<int,Map<String,String>> _berufe = {
    -1: {'m': '', 'w': ''},
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
    'name': '????????',
    'geschlecht': 'w',
    'iBild': -1,
    'iScreen': 0,
    'screens': <int>[],
    'erlebnisse': <String>[]};

  // Default values for testing
  Map<String,dynamic> _testing = {
    'name': 'Mara',
    'geschlecht': 'w',
    'iBild': 0,
    'iScreen': 3,
    'screens': <int>[0,1,2,3],
    'erlebnisse': <String>['besteFreunde']};

  // Initialize new User with defaults
  Held.initial(){
    _name = _defaults['name'];
    _geschlecht = _defaults['geschlecht'];
    _iBild = _defaults['iBild'];
    _erlebnisse = _defaults['erlebnisse'];
    _screens = _defaults['screens'];
    _iScreen = _defaults['iScreen'];
  }

  //Used for testing widgets
  Held.test(){
    _name = _testing['name'];
    _geschlecht = _testing['geschlecht'];
    _iBild = _testing['iBild'];
    _erlebnisse = _testing['erlebnisse'];
    _screens = _testing['screens'];
    _iScreen = _testing['iScreen'];
  }

  //Generate Hero from map
  Held.fromMap(Map<String,dynamic> _map){
    _name = _map['name'];
    _geschlecht = _map['geschlecht'];
    _iBild = _map['iBild'];
    _erlebnisse = _map['erlebnisse'];
    _screens = _map['screens'];
    _iScreen = _map['iScreen'];
  }

  //Loads hero-data either from firebase or local file
  //returns a default hero if nothing is found
  Future<Held> load({bool signedIn, Authenticator authenticator, Firestore firestore}) async{
    //If we are signed-in we load user data from firebase
    Held _hero;
    if(signedIn){
      _hero = await loadFirestoreUserData(firestore: firestore, authenticator: authenticator);
      if(_hero==null){return null;}else{return _hero;}
    }
    else{
      //This also takes care of defaulting to initial values if no file is found
      _hero = await loadLocalUserData();
      if(_hero==null){return null;}else{return _hero;}
    }
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
  set addErlebniss(String valIn){
    if(valIn != null && valIn != '' && !_erlebnisse.contains(valIn)){_erlebnisse.add(valIn);}
  }
  set iScreen(int valIn){
    if(valIn != null && valIn >=0 && _screens.contains(valIn)){_iScreen = valIn;}
  }
  set addScreen(int valIn){
    if(valIn != null && valIn >=0 && !_screens.contains(valIn)){_screens.add(valIn);}
  }

  // Getters
  String get name => _name;
  int get iBild => _iBild;
  int get iScreen => _iScreen;
  String get geschlecht => _geschlecht;
  List<String> get erlebnisse => _erlebnisse;
  List<int> get screens => _screens;
  Map<int,Map<String,String>> get berufe => _berufe;
  // This getter is only for testing
  Map<String,dynamic> get defaults => _defaults;
  Map<String,dynamic> get values => {
    'name': name,
    'geschlecht': geschlecht,
    'iBild': iBild,
    'erlebnisse': erlebnisse,
    'iScreen': iScreen,
    'screens': screens
  };
}

class Adventure{
  // Properties of adventures
  String name;
  int version;
  Map<int,Map<String,dynamic>> story;

  Adventure({@required this.name, @required this.version, @required this.story});

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

  GeneralData({@required this.gendering, @required this.erlebnisse});
}

//From here we handle gendering and name substitutions
class Substitution{
  final GeneralData generalData;
  final Held hero;

  Substitution({@required this.hero, @required this.generalData});

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