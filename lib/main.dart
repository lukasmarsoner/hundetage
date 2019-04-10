import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'utilities/json.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async{
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget{
  @override
  SplashScreenState createState() => new SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{
  Held hero;
  Animation<int> _characterCount;
  AnimationController _animationController;
  bool _isLoading = true;
  Authenticator authenticator;
  Substitution substitution;
  GeneralData generalData;
  Firestore firestore;

  int _stringIndex;
  static const List<String> _textStrings = const <String>[
    'Daten werden geladen...',
  ];

  String get _currentString => _textStrings[_stringIndex % _textStrings.length];

  //Check if user is currently logged-in
  Future<bool> checkLoginStatus() async{
    if(await authenticator.getCurrentUser()==null){return false;}else{return true;}
  }

  Future<void> _animateText() async {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    setState(() {
      _stringIndex = _stringIndex == null ? 0 : _stringIndex + 1;
      _characterCount = new StepTween(begin: 0, end: _currentString.length)
          .animate(
          new CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    });
    await _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _loadingScreen(){
    return Column(
            mainAxisAlignment:MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset('images/icon.png', width: 200.0, height: 200.0),
              Container(
                  padding: EdgeInsets.only(top: 10.0),
                  child: _characterCount == null ? null : new AnimatedBuilder(
                    key: Key('loadingText'),
                      animation: _characterCount,
                      builder: (BuildContext context, Widget child) {
                      String text = _currentString.substring(0, _characterCount.value);
                      return new Text(text, style: new TextStyle(
                          fontSize: 20.0,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                      );
                    })
              ),
              Container(padding: EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator())
            ]
    );
  }

  Future<void> _loadData() async{
    firestore = Firestore.instance;
    firestore.settings(timestampsInSnapshotsEnabled: true);
    authenticator = new Authenticator(firebaseAuth: FirebaseAuth.instance);
    generalData = await loadGeneralData(firestore);
    bool _signedIn = await checkLoginStatus();
    hero = Held.initial();
    hero = await hero.load(authenticator: authenticator,
        signedIn: _signedIn,
        firestore: firestore);
    if (hero == null) {
      hero = Held.initial();
    }
    //Check if we are already logged-in
    hero.signedIn = _signedIn;
    substitution = Substitution(hero: hero, generalData: generalData);
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _animateText();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Widget _showCircularProgress(){
    return _isLoading
        ?Center(child: _loadingScreen())
        :MyApp(hero: hero, authenticator: authenticator,
        generalData: generalData, substitution: substitution, firestore: firestore);
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner: false,
        home: Scaffold(body:_showCircularProgress()));}
}

class MyApp extends StatefulWidget{
  final Held hero;
  final Authenticator authenticator;
  final Substitution substitution;
  final GeneralData generalData;
  final Firestore firestore;

  MyApp({@required this.hero, @required this.authenticator, @required this.generalData,
  @required this.substitution, @required this.firestore});

  @override
  _MyAppState createState() => new _MyAppState(hero: hero, substitution: substitution,
  generalData: generalData, firestore: firestore, authenticator: authenticator);
}

//All global should be store and kept-updated here
class _MyAppState extends State<MyApp>{
  Held hero;
  Authenticator authenticator;
  Substitution substitution;
  GeneralData generalData;
  Firestore firestore;

  _MyAppState({@required this.hero, @required this.authenticator,
  @required this.generalData, @required this.firestore, @required this.substitution});

  void heroCallback({Held newHero}){
    setState(() {hero = newHero;});
    hero.signedIn
        ?updateCreateFirestoreUserData(firestore: firestore,
        authenticator: authenticator, hero: hero)
        :writeLocalUserData(hero);
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hundetage',
      home: Scaffold(body: MainPage(hero: hero,
          heroCallback: heroCallback, authenticator: authenticator,
          generalData: generalData, substitution:substitution, firestore: firestore)),
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
    'iScreen': 0,
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