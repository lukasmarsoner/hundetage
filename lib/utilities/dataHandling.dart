import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataHandler {
  Substitution substitution;
  GeneralData generalData;
  VersionController versionController, firebaseVersions;
  Firestore firestore = Firestore.instance;
  Map<String,Geschichte> stories;
  //We set this here for now. The machinery is in place to handle more than one
  //story but we don't have one for now ;-)
  String currentStory = 'Raja';
  bool local;
  Held hero = Held.initial();
  ConnectionStatus connectionStatus = new ConnectionStatus();

  //We want to use this all throughout the app so it should be a singleton
  DataHandler._privateConstructor();

  static final DataHandler _instance = DataHandler._privateConstructor();

  factory DataHandler({Firestore firestore,
    VersionController testVersionController}){
    return _instance;
  }

  get getCurrentStory => stories[currentStory];

  //Hero-setter also ensuring Firebase and local data are
  //always up-to-date
  set updateHero(Held heroIn) {
    hero = heroIn;
    writeLocalUserData(hero);
    substitution = Substitution(hero: hero, generalData: generalData);
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

    hero = await loadLocalUserData();
    if(hero==null){hero = Held.initial();}

    hero.analytics = new FirebaseAnalytics();

    this.updateHero = hero;
  }
}

class Held{
  // Properties of users
  //This is being set here. As user images are stored in the assets it will
  //never change in the live app
  String _name, _username, _geschlecht, _lastOption;
  Image userImage;
  int _iScreen;
  List<String> _erlebnisse;
  List<int> _screens;
  FirebaseAnalytics analytics;

  // Default values for user
  Map<String,dynamic> _defaults = {
    'lastOption': '',
    'iScreen': 0,
    'screens': <int>[],
    'erlebnisse': <String>[]};

  // Default values for testing
  Map<String,dynamic> _testing = {
    'name': 'Mara',
    'username': 'Maya',
    'geschlecht': 'w',
    'lastOption': 'Last option',
    'iScreen': 0,
    'screens': <int>[0,1,2,3],
    'erlebnisse': <String>['besteFreunde']};

  // Initialize new User with defaults
  Held.initial(){
    _name = _defaults['name'];
    _username = _defaults['username'];
    _geschlecht = _defaults['geschlecht'];
    _lastOption = _defaults['lastOption'];
    _erlebnisse = _defaults['erlebnisse'];
    _screens = _defaults['screens'];
    _iScreen = _defaults['iScreen'];
  }

  //Used for testing widgets
  Held.test(){
    _name = _testing['name'];
    _username = _defaults['username'];
    _geschlecht = _testing['geschlecht'];
    _lastOption = _testing['lastOption'];
    _erlebnisse = _testing['erlebnisse'];
    _screens = _testing['screens'];
    _iScreen = _testing['iScreen'];
  }

  //Generate Hero from map
  Held.fromMap(Map<String,dynamic> _map){
    _name = _map['name'];
    userImage = _map['userImage'];
    _username = _defaults['username'];
    _lastOption = _map['lastOption'];
    _geschlecht = _map['geschlecht'];
    _erlebnisse = _map['erlebnisse'];
    _screens = _map['screens'];
    _iScreen = _map['iScreen'];
  }

  // Setters with sanity-checks
  set name(String valIn){
    (valIn != null && valIn.length != 0)?_name = valIn:throw new Exception('Invalid name!');
  }
  set username(String valIn){
    (valIn != null && valIn.length != 0)?_username = valIn:throw new Exception('Invalid name!');
  }
  set geschlecht(String valIn){
    (valIn=='m' || valIn=='w')?_geschlecht = valIn:throw new Exception('Invalid sex!');
  }
  set addErlebniss(String valIn){
    if(valIn != null && valIn != ''){
      _erlebnisse.add(valIn);
      analytics.logEvent(name: valIn);
    }
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
  String get name => _name;
  String get username => _username;
  int get iScreen => _iScreen;
  String get geschlecht => _geschlecht;
  List<String> get erlebnisse => _erlebnisse;
  List<int> get screens => _screens;
  String get lastOption => (iScreen!=0 && iScreen!=888)?_lastOption+' ':'';

  // This getter is only for testing
  Map<String,dynamic> get defaults => _defaults;

  Map<String,dynamic> get values => {
    'name': name,
    'username': username,
    'lastOption': lastOption,
    'geschlecht': geschlecht,
    'erlebnisse': erlebnisse,
    'iScreen': iScreen,
    'screens': screens,
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
    textIn = textIn.replaceAll('#lesername', hero.username);
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
  String text, url, title;
  Image image;

  Erlebniss({@required this.text, @required this.image,
    this.url, @required this.title});

  get toMap => {'url': url, 'text': text, 'title': title};
}