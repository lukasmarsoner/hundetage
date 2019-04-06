import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'utilities/json.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async{
  runApp(MyApp());
}

class MyApp extends StatefulWidget{

  @override
  _MyAppState createState() => new _MyAppState();
}

//All global should be store and kept-updated here
class _MyAppState extends State<MyApp>{
  Held hero;
  bool _isLoading;
  Authenticator authenticator;
  Substitution substitution;
  GeneralData generalData;
  Firestore firestore;

  void heroCallback({Held newHero}){
    setState(() {hero = newHero;});
    hero.signedIn
        ?updateCreateFirestoreUserData(firestore: firestore,
        authenticator: authenticator, hero: hero)
        :writeLocalUserData(hero);
  }

  //Check if user is currently logged-in
  Future<bool> checkLoginStatus() async{
    if(await authenticator.getUsername()==null){return false;}else{return true;}
  }

  Future<void> _loadAndInitializeMain() async {
    firestore = Firestore();
    authenticator = new Authenticator(firebaseAuth: FirebaseAuth.instance);
    substitution = Substitution(hero: hero,generalData: generalData);
    hero = Held.initial();
    bool _signedIn = await checkLoginStatus();
    hero = await hero.load(authenticator:authenticator, signedIn: _signedIn, firestore: firestore);
    if(hero==null){hero = Held.initial();}
    generalData = await loadGeneralData(firestore);
    //Check if we are already logged-in
    hero.signedIn = _signedIn;
    setState(() {
      hero = hero;
      generalData = generalData;
      firestore = firestore;
      authenticator = authenticator;
      substitution = substitution;
    });
  }

  void _pageAndLoadingScreen(){
    setState(()=>_isLoading = true);
    _loadAndInitializeMain();
    setState(()=>_isLoading = false);
  }

  Widget _showCircularProgress(){
    return _isLoading
    ?Center(child: CircularProgressIndicator())
    :Container(height: 0.0, width: 0.0,);
  }

  @override
  Widget build(BuildContext context){
    _pageAndLoadingScreen();
    return MaterialApp(
      title: 'Hundetage',
      home: Scaffold(body: new Stack(children: <Widget>[MainPage(hero: hero,
          heroCallback: heroCallback, authenticator: authenticator,
          generalData: generalData, substitution:substitution, firestore: firestore),
          _showCircularProgress()])),
    );
  }
}

class Held{
  // Properties of users
  //This is being set here. As user images are stored in the assets it will
  //never change in the live app
  int _maxImages = 7;
  String _name, _geschlecht;
  int _iBild, _iScreen;
  List<String> _erlebnisse;
  List<int> _screens;
  bool signedIn;
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
    'signedIn': false,
    'screens': <int>[],
    'erlebnisse': <String>[]};

  // Default values for testing
  Map<String,dynamic> _testing = {
    'name': 'Mara',
    'geschlecht': 'w',
    'iBild': 0,
    'iScreen': 3,
    'signedIn': false,
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
    signedIn = _defaults['signedIn'];
  }

  //Used for testing widgets
  Held.test(){
    _name = _testing['name'];
    _geschlecht = _testing['geschlecht'];
    _iBild = _testing['iBild'];
    _erlebnisse = _testing['erlebnisse'];
    _screens = _testing['screens'];
    _iScreen = _testing['iScreen'];
    signedIn = _testing['signedIn'];
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
    //if not we lookf for a local file
    else{
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
  int get maxImages => _maxImages;
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