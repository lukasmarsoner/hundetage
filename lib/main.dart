import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_screen.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'utilities/json.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

void main() async{
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget{
  @override
  SplashScreenState createState() => new SplashScreenState();
}

class DataLoader {
  Authenticator authenticator;
  Substitution substitution;
  GeneralData generalData;
  VersionController versionController, testVersionController;
  VersionController _firebaseVersions = new VersionController();
  Firestore firestore;
  bool local, fakeOnlineMode;
  Held hero = Held.initial();
  BuildContext context;
  ConnectionStatus connectionStatus = new ConnectionStatus();

  //fakeOnlineMode is used so we don't need to mock the http-request during testing
  DataLoader({this.authenticator, this.context, this.firestore, this.fakeOnlineMode,
  this.testVersionController});

  Future<void> loadData() async {
    //Check if we are connected to the internet
    connectionStatus.checkConnection();
    //If so - we can check if there are any updates available for us
    //If not we see if we have local data - if not we need to inform the user
    //that they need to go online to retrieve it
    fakeOnlineMode
        ?local = false
        :local = !connectionStatus.online;

    versionController = await loadLocalVersionData();
    //If we have no connection we just load the local data
    if (local) {
      if (!(await canWorkOffline())) {
        _showConnectionNeededDialog(context);
      }
      else {
        generalData = await loadLocalGeneralData();
        hero = await hero.loadOffline();
      }
    }
    else {
        //First see if we have newer versions available on Firebase
        //For testing we need to mock this
        fakeOnlineMode
            ?_firebaseVersions = testVersionController
            :_firebaseVersions = await loadVersionInformation(firestore: firestore);

        bool _offineDataAvailable = await canWorkOffline();
        //If there is no offline data we need to load everything
      if (!_offineDataAvailable) {
        generalData = await loadGeneralData(firestore);
        versionController = _firebaseVersions;

        //Write stuff to file so it is there next time
        writeLocalVersionData(versionController);
        writeLocalGeneralData(generalData);
      }
      //If there is, we can just update what has changed
      else {
        if (versionController.gendering < _firebaseVersions.gendering) {
          generalData.gendering = await loadGendering(firestore);
          versionController.gendering = _firebaseVersions.gendering;
          //Update version-information on disk
          writeLocalVersionData(versionController);
          //Update data on disk
          writeLocalGenderingData(generalData);
        }
        if (versionController.erlebnisse < _firebaseVersions.erlebnisse) {
          generalData.erlebnisse = await loadErlebnisse(firestore);
          versionController.erlebnisse = _firebaseVersions.erlebnisse;
          //Update version-information on disk
          writeLocalVersionData(versionController);
          //Update data on disk
          writeLocalErlebnisseData(generalData);
        }
      }
    }

    //Here we manage user data. This is different as we might want to load local
    //data even if we are online
    //First we check if the user is currently logged-in
    bool _signedIn = await authenticator.getUid()==null;
    hero = await hero.load(authenticator: authenticator,
        signedIn: _signedIn,
        firestore: firestore);
    if (hero == null) {
      hero = Held.initial();
    }
    //Check if we are already logged-in
    hero.signedIn = _signedIn;

    //Generate substitutions and terminate loading animation
    substitution = Substitution(hero: hero, generalData: generalData);
  }

  _showConnectionNeededDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            key: Key('MissingDataAlert'),
            title: new Text("Keine Internetverbindung"),
            content: new Text(
                "Beim ersten Start wird eine internetverbindung benötigt."
                    "Danach kannst du die App auch offline benutzen."),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Schließen"),
                onPressed: () {
                  exit(0);
                },
              ),
            ],
          );
        }
    );
  }
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{
  Held hero = Held.initial();
  Animation<int> _characterCount;
  AnimationController _animationController;
  bool _isLoading = true;
  Authenticator authenticator = new Authenticator(firebaseAuth: FirebaseAuth.instance);
  Substitution substitution;
  GeneralData generalData;
  VersionController versionController;
  Firestore firestore = Firestore.instance;

  int _stringIndex;
  static const List<String> _textStrings = const <String>[
    'Daten werden geladen...',
  ];

  String get _currentString => _textStrings[_stringIndex % _textStrings.length];

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

  @override
  void initState() {
    super.initState();
    _animateText();
    WidgetsBinding.instance.addPostFrameCallback((_)=>_runDataLoaders());
    setState(() => _isLoading = false);
  }

  Future<void> _runDataLoaders() async{
    //Class taking care of all data-loading logic
    DataLoader _dataLoader = new DataLoader(firestore: firestore,
        authenticator: authenticator, context: context);
    await _dataLoader.loadData();
    generalData = _dataLoader.generalData;
    substitution = _dataLoader.substitution;
    hero = _dataLoader.hero;
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
    'name': '??????',
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
    if(signedIn){
      Held _hero = await loadFirestoreUserData(firestore: firestore, authenticator: authenticator);
      if(_hero==null){return null;}else{return _hero;}
    }
    //if not we lookf for a local file
    else{
      Held _hero = await loadLocalUserData();
      if(_hero==null){return null;}else{return _hero;}
    }
  }

  //Loading method for offline use
  Future<Held> loadOffline() async{
    Held _hero = await loadLocalUserData();
    if(_hero==null){return null;}else{return _hero;}
  }

  // Setters with sanity-checks
  set name(String valIn){
    (valIn != null && valIn.length != 0)?_name = valIn:throw new Exception('Invalid name!');
  }
  set geschlecht(String valIn){
    (valIn=='m' || valIn=='w')?_geschlecht = valIn:throw new Exception('Invalid sex!');
  }
  set iBild(int valIn){
    (valIn != null && valIn >=-1 && valIn <= maxImages)?_iBild = valIn:throw new Exception('Invalid imange index!');
  }
  set addErlebniss(String valIn){
    if(valIn != null && valIn != '' && !_erlebnisse.contains(valIn)){_erlebnisse.add(valIn);}
  }
  set iScreen(int valIn){
    if(valIn != null && valIn >=0){_iScreen = valIn;}
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

class GeneralData{
  //Contains stuff needed by all adventures
  //gendering contains mappings for male/female versions of words
  //erlebnisse contains all possible memories that can be collected during the adventures
  Map<String,Map<String,String>> gendering;
  Map<String,Map<String,String>> erlebnisse;

  GeneralData({@required this.gendering, @required this.erlebnisse});

  Map<String,dynamic> get values => {
    'gendering': gendering,
    'erlebnisse': erlebnisse
  };

  GeneralData.fromMap(Map<String,dynamic> _map){
    gendering = _map['gendering'];
    erlebnisse = _map['erlebnisse'];
  }

  set setGendering(Map<String, dynamic> _dataIn){gendering = generalDataFromDynamic(_dataIn);}
  set setErlebnisse(Map<String, dynamic> _dataIn){erlebnisse = generalDataFromDynamic(_dataIn);}
}

//Central class to monitor version-information
class VersionController{
  Map<String,double> stories;
  double gendering, erlebnisse;

  VersionController();

  VersionController.fromMap(Map<String,dynamic> _map){
    //Explicitly set some data
    gendering = double.parse(_map['gendering']);
    erlebnisse = double.parse(_map['erlebnisse']);
    //All other version-data refers to stories
    List<String> _keys = _map.keys.toList();
    stories = new Map<String,double>();
    for(int i=0;i<_keys.length;i++){
      String _key = _keys[i];
      if(!(<String>['gendering','erlebnisse'].contains(_key))){
        stories[_key] = double.parse(_map[_key]);
      }
    }
  }

  Map<String,String> getOutputData(){
    //Used to convert map into a format that can be written to JSON
    //And Firebase in the same way
    Map<String,String> _outputAsString = new Map<String,String>();
    _outputAsString['gendering'] = gendering.toString();
    _outputAsString['erlebnisse'] = erlebnisse.toString();
    List<String> _keys = stories.keys.toList();
    for(int i=0;i<_keys.length;i++){
      String _key = _keys[i];
      if(!(<String>['gendering','erlebnisse'].contains(_key))){
        _outputAsString[_key] = stories[_key].toString();
      }
    }
    return _outputAsString;
  }

  Map<String,dynamic> get values => getOutputData();
}

//Helper class to check online-offline status
class ConnectionStatus{
  bool online = false;

  //The test to actually see if there is a connection
  Future<void> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('http://wwww.google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        online = true;
      } else {
        online = false;
      }
    } on SocketException
    catch(_) {
      online = false;
    }
  }
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

class Geschichte {
  final String storyname;
  Image image;
  Held hero;
  Map<int,Map<String,dynamic>> screens;

  Geschichte.fromMap(Map<String, dynamic> map)
      : assert(map['name'] != null),
        assert(map['image'] != null),
        storyname = map['name'],
        image = Image.network(map['image'], fit: BoxFit.cover);

  Geschichte.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data);

  //Make sure all maps have the correct types
  void setStory(Map<String,dynamic> _map){
    screens = {};
    List<String> _keys = _map.keys.toList();
    for(int i=0;i<_keys.length;i++){
      String key = _keys[i];
      //Exclude metadata
      if(!<String>['name','image'].contains(key)){
        Map<String,dynamic> _screen = {};
        _screen['options'] = Map<String,String>.from(_map[key]['options']);
        _screen['forwards'] = Map<String,String>.from(_map[key]['forwards']);
        _screen['erlebnisse'] = Map<String,String>.from(_map[key]['erlebnisse']);
        _screen['conditions'] = Map<String,String>.from(_map[key]['conditions']);
        _screen['text'] = _map[key]['text'];
        screens[int.parse(key)] = _screen;
      }
    }
  }

  Map<String,dynamic> get data => {
    'screens': screens
  };

  Map<String,dynamic> get metaData => {
    'storyname': storyname,
    'image': image
  };
}