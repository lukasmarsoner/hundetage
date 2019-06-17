import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/screens/mainScreen.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'utilities/json.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String convertText({DataHandler dataHandler,String textIn}){
  return dataHandler.substitution.applyAllSubstitutions(textIn);
}

void main() async{
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget{
  @override
  SplashScreenState createState() => new SplashScreenState();
}

class DataHandler {
  Authenticator authenticator = new Authenticator(firebaseAuth: FirebaseAuth.instance);
  Substitution substitution;
  GeneralData generalData;
  VersionController versionController, firebaseVersions;
  Firestore firestore = Firestore.instance;
  Map<String,Geschichte> stories;
  String currentStory;
  bool local;
  Held hero = Held.initial();
  ConnectionStatus connectionStatus = new ConnectionStatus();

  //We want to use this all throughout the app so it should be a singleton
  DataHandler._privateConstructor();

  static final DataHandler _instance = DataHandler._privateConstructor();

  //fakeOnlineMode is used so we don't need to mock the http-request during testing
  factory DataHandler({Authenticator authenticator, Firestore firestore,
    VersionController testVersionController}){
    return _instance;
  }

  get getCurrentStory => stories[currentStory];

  //Hero-setter also ensuring Firebase and local data are
  //always up-to-date
  set updateHero(Held heroIn) {
    hero = heroIn;
    hero.signedIn
        ?updateCreateFirestoreUserData(firestore: firestore,
        authenticator: authenticator, hero: hero)
        :writeLocalUserData(hero);
  }

  //This can get more functionality later
  //right now we only really care about te hero changing
  set updateData(DataHandler newData){
    this.updateHero = newData.hero;
    generalData = newData.generalData;
    stories = newData.stories;
    substitution = newData.substitution;
  }

  void updateLocalStoryData(Geschichte _updatedStory){
    //Update version-information on disk
    writeLocalVersionData(versionController);
    //Update data on disk
    writeLocalStoryData(_updatedStory);
  }

  Future<void> loadLocalData() async{
    generalData = await loadLocalGeneralData();
    stories = await loadAllLocalStoryData();
    hero = await hero.loadOffline();
    //For the user we just set it to it's initial value
    if(hero==null){
      hero = Held.initial();
    }
  }

  Future<void> loadData() async {
    //Check if we are connected to the internet
    await connectionStatus.checkConnection();
    //If so - we can check if there are any updates available for us
    //If not we see if we have local data - if not we need to inform the user
    //that they need to go online to retrieve it
    connectionStatus.online
        ?local = false
        :local = await canWorkOffline();

    versionController = await loadLocalVersionData();
    //If we have no connection we just load the local data
    if (local) {
      await loadLocalData();
      //If we have trouble loading local data, delete general data and
      //Stories and load them from Firebase
      //If one of the two is missing we re-load everything
      //This could be more sophisticated but should not really be an issue
      if(generalData==null || stories==null){
        await deleteLocalGeneralData();
        await deleteLocalStoryData();
        await loadData();
      }
    }
    else {
      if(connectionStatus.online) {
        //First see if we have newer versions available on Firebase
        firebaseVersions = await loadVersionInformation(firestore: firestore);
        //If there is no offline data we need to load everything
        if (!(await canWorkOffline())) {
          generalData = await loadGeneralData(firestore);
          stories = await loadGeschichten(firestore: firestore);
          versionController = firebaseVersions;
          //Write stuff to file so it is there next time
          //TODO: make this into an isolate
          await writeLocalVersionData(versionController);
          await writeLocalGeneralData(generalData);
          await writeAllLocalStoriesData(stories);
        }
        //If there is, we can just update what has changed
        else {
          //Load current local data before updating
          await loadLocalData();
          if (versionController.gendering < firebaseVersions.gendering) {
            generalData.gendering = await loadGendering(firestore);
            versionController.gendering = firebaseVersions.gendering;
            //Update version-information on disk
            writeLocalVersionData(versionController);
            //Update data on disk
            writeLocalGenderingData(generalData);
          }
          if (versionController.erlebnisse < firebaseVersions.erlebnisse) {
            generalData.erlebnisse = await loadErlebnisse(firestore);
            versionController.erlebnisse = firebaseVersions.erlebnisse;
            //Update version-information on disk
            writeLocalVersionData(versionController);
            //Update data on disk
            writeLocalErlebnisseData(generalData);
          }

          //Check all stories for updates
          List<String> _storiesFirebase = firebaseVersions.stories.keys
              .toList();
          List<String> _storiesLocal = versionController.stories.keys.toList();
          //Update existing stories
          for (int i = 0; i < _storiesFirebase.length; i++) {
            String _storyname = _storiesFirebase[i];
            if (_storiesLocal.contains(_storyname)) {
              if (versionController.stories[_storyname] <
                  firebaseVersions.stories[_storyname]) {
                stories[_storyname] = await loadGeschichte(firestore: firestore,
                    story: stories[_storyname]);
                versionController.stories[_storyname] =
                firebaseVersions.stories[_storyname];
                //Update local data
                updateLocalStoryData(stories[_storyname]);
              }
            }
            //Add missing stories
            else {
              //Create new story-entry and load data from firestore
              stories[_storyname] = Geschichte(storyname: _storyname);
              stories[_storyname] = await loadGeschichte(
                  firestore: firestore, story: stories[_storyname]);
              //Add version data to local version controller
              versionController.stories[_storyname] =
              firebaseVersions.stories[_storyname];
              //Update local data
              updateLocalStoryData(stories[_storyname]);
            }
          }
        }
      }
      else{await loadData();}
    }

    //Here we manage user data. This is different as we might want to load local
    //data even if we are online
    //First we check if the user is currently logged-in
    bool _signedIn = await authenticator.getUid()!=null;
    hero = await hero.load(authenticator: authenticator,
        signedIn: _signedIn,
        firestore: firestore);
    if (hero == null) {
      hero = Held.initial();
    }
    //Set sign-in status for user
    hero.signedIn = _signedIn;

    //Generate substitutions and terminate loading animation
    substitution = Substitution(hero: hero, generalData: generalData);
  }
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{
  Animation<int> _characterCount;
  AnimationController _animationController;
  bool _isLoading = true;
  DataHandler dataHandler;

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
              Image.asset('assets/images/icon.png', width: 200.0, height: 200.0),
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
    SchedulerBinding.instance.addPostFrameCallback((_)=>_runDataLoaders());
  }

  Future<void> _runDataLoaders() async{
    //Class taking care of all data-loading logic
    dataHandler = DataHandler();
    await dataHandler.loadData();
    setState(() => _isLoading = false);
  }

  Widget _showCircularProgress(){
    return _isLoading
        ?Center(child: _loadingScreen())
        :MyApp(dataHandler: dataHandler);
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner: false,
        home: Scaffold(body:_showCircularProgress()));}
}

class MyApp extends StatefulWidget{
  final DataHandler dataHandler;

  MyApp({@required this.dataHandler});

  @override
  _MyAppState createState() => new _MyAppState(dataHandler: dataHandler);
}

//All global should be store and kept-updated here
class _MyAppState extends State<MyApp>{
  final DataHandler dataHandler;

  _MyAppState({@required this.dataHandler});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hundetage',
      home: Scaffold(body: MainPage(dataHandler: dataHandler,)),
    );
  }
}

class Held{
  // Properties of users
  //This is being set here. As user images are stored in the assets it will
  //never change in the live app
  int _maxImages = 8;
  String _name, _geschlecht, _lastOption;
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
    4: {'m': 'Der neugierigste Hund im Land', 'w': 'Die neugierigste Hündin im Land'},
    5: {'m': 'Ihm kann man nichts vormachen', 'w': 'Ihr kann man nichts vormachen'},
    6: {'m': 'Genauso wuschelig wie tapfer', 'w': 'Genauso wuschelig wie tapfer'},
    7: {'m': 'Dein bester Freund', 'w': 'Deine beste Freundin'}};

  // Default values for user
  Map<String,dynamic> _defaults = {
    'name': 'Mara',
    'geschlecht': 'w',
    'iBild': -1,
    '_lastOption': '',
    'iScreen': 0,
    'signedIn': false,
    'screens': <int>[],
    'erlebnisse': <String>[]};

  // Default values for testing
  Map<String,dynamic> _testing = {
    'name': 'Mara',
    'geschlecht': 'w',
    'iBild': 0,
    '_lastOption': 'Last option',
    'iScreen': 0,
    'signedIn': false,
    'screens': <int>[0,1,2,3],
    'erlebnisse': <String>['besteFreunde']};

  // Initialize new User with defaults
  Held.initial(){
    _name = _defaults['name'];
    _geschlecht = _defaults['geschlecht'];
    _iBild = _defaults['iBild'];
    _lastOption = _defaults['lastOption'];
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
    _lastOption = _defaults['lastOption'];
    _erlebnisse = _testing['erlebnisse'];
    _screens = _testing['screens'];
    _iScreen = _testing['iScreen'];
    signedIn = _testing['signedIn'];
  }

  //Generate Hero from map
  Held.fromMap(Map<String,dynamic> _map){
    _name = _map['name'];
    _lastOption = _map['lastOption'];
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
    if(valIn != null && valIn >=0){_screens.add(valIn);}
  }
  set lastOption(String valIn){
    valIn==null
        ?_lastOption=''
        //Remove leading dots if we have any...
        :valIn.substring(0,3)=='...'
        ?_lastOption=valIn.substring(4)
        :_lastOption=valIn;
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
  String get lastOption => (iScreen!=0 && iScreen!=888)?_lastOption+' ':'';

  // This getter is only for testing
  Map<String,dynamic> get defaults => _defaults;

  Map<String,dynamic> get values => {
    'name': name,
    'lastOption': lastOption,
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
  Map<String,Erlebniss> erlebnisse;

  GeneralData({@required this.gendering, @required this.erlebnisse});

  erlebnisseToJSON(){
    List<String> _keys = erlebnisse.keys.toList();
    Map<String, Map<String,String>> _erlebnisseOut = Map<String, Map<String,String>>();
    for(String _key in _keys){
      _erlebnisseOut[_key] = erlebnisse[_key].toMap;
    }
    return _erlebnisseOut;
  }

  Map<String,dynamic> get values => {
    'gendering': gendering,
    'erlebnisse': erlebnisseToJSON()
  };

  GeneralData.fromMap(Map<String,dynamic> _map){
    gendering = _map['gendering'];
    erlebnisse = _map['erlebnisse'];
  }

  set setGendering(Map<String, dynamic> _dataIn){gendering = generalDataFromDynamic(_dataIn);}
  set setErlebnisse(Map<String, Erlebniss> _dataIn){erlebnisse = _dataIn;}
}

//Central class to monitor version-information
class VersionController{
  Map<String,double> stories;
  double gendering, erlebnisse;

  VersionController();

  VersionController.fromMap(Map<String,dynamic> _map){
    //Explicitly set some data
    gendering = _map['gendering'];
    erlebnisse = _map['erlebnisse'];
    //All other version-data refers to stories
    List<String> _keys = _map.keys.toList();
    stories = new Map<String,double>();
    for(String _key in _keys){
      if(!(<String>['gendering','erlebnisse'].contains(_key))){
        stories[_key] = _map[_key];
      }
    }
  }

  Map<String,double> getOutputData(){
    //Used to convert map into a format that can be written to JSON
    //And Firebase in the same way
    Map<String,double> _outputAsString = new Map<String,double>();
    _outputAsString['gendering'] = gendering;
    _outputAsString['erlebnisse'] = erlebnisse;
    List<String> _keys = stories.keys.toList();
    for(String _key in _keys){
      if(!(<String>['gendering','erlebnisse'].contains(_key))){
        _outputAsString[_key] = stories[_key];
      }
    }
    return _outputAsString;
  }

  Map<String,double> get values => getOutputData();
}

//Helper class to check online-offline status
class ConnectionStatus{
  bool online = false;

  //The test to actually see if there is a connection
  Future<void> checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    online = (connectivityResult == ConnectivityResult.mobile
        || connectivityResult == ConnectivityResult.wifi);
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
    for(String _key in _keys){
      String _substring = generalData.gendering[_key][hero.geschlecht];
      textIn = textIn.replaceAll('#'+_key, _substring);
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
  String url, zusammenfassung;
  Image image;
  Held hero;
  Map<int,Map<String,dynamic>> screens;

  Geschichte({this.storyname});

  Geschichte.fromFirebaseMap(Map<String, dynamic> map)
      : assert(map['name'] != null),
        assert(map['image'] != null),
        assert(map['zusammenfassung'] != null),
        assert(map['url'] != null),
        storyname = map['name'],
        url = map['url'],
        zusammenfassung = map['zusammenfassung'],
        image = map['image'];

  //Used to set data from local file
  void setFromJSON({Image imageIn, Map<String,dynamic> screensJSON,
  String summary}){
    screens = screensFromJSON(screensJSON);
    image = imageIn;
    zusammenfassung = summary;
}

  //Make sure all maps have the correct types
  void setStory(Map<dynamic,dynamic> _map){
    screens = {};
    List<String> _keys = List<String>.from(_map.keys);
    for(String _key in _keys){
      Map<String,dynamic> _screen = {};
      _screen['options'] = Map<String,String>.from(_map[_key]['options']);
      _screen['forwards'] = Map<String,String>.from(_map[_key]['forwards']);
      _screen['erlebnisse'] = Map<String,String>.from(_map[_key]['erlebnisse']);
      _screen['conditions'] = Map<String,String>.from(_map[_key]['conditions']);
      _screen['text'] = _map[_key]['text'];
      screens[int.parse(_key)] = _screen;
    }
  }

  Map<String,Map<String,dynamic>> allKeysToString(){
    Map<String,Map<String,dynamic>> _screensJSON = Map<String,Map<String,dynamic>>();
    List<int> _keys = screens.keys.toList();
    for(int _key in _keys){
      _screensJSON[_key.toString()] = screens[_key];
    }
    return _screensJSON;
  }

  Map<int,Map<String,dynamic>> screensFromJSON(Map<String,dynamic> _screensJSON){
    List<String> _keys = _screensJSON.keys.toList();
    Map<int,Map<String,dynamic>> _screensInt = Map<int,Map<String,dynamic>>();
    for(String _key in _keys){
      _screensInt[int.parse(_key)] = _screensJSON[_key];
    }
    return _screensInt;
  }

  Map<String,Map<String,dynamic>> get screensJSON => allKeysToString();
}

//Class for experiences
class Erlebniss {
  String text, url;
  Image image;

  Erlebniss({this.text, this.image, this.url});

  get toMap => {'url': url, 'text': text};
}