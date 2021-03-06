import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:async';

class MailSender{
  DataHandler dataHandler;
  String text, subject;
  Email email;
  String attachmentPath;
  bool success;

  MailSender({@required this.dataHandler});

  Future<bool> send() async {
    email = Email(
      body: text,
      subject: 'Nachricht von ${dataHandler.hero.username}',
      recipients: ['hallo@hundetage.app'],
      attachmentPath: attachmentPath,
    );

    try {
      await FlutterEmailSender.send(email);
      success = true;
    } catch (error) {
      success = false;
    }

    return success;
  }
}

class DataHandler{
  Substitution substitution;
  GeneralData generalData;
  Future<GeneralData> futureGeneralData;
  VersionController versionController, firebaseVersions;
  Firestore firestore = Firestore.instance;
  Map<String,Geschichte> stories;
  Future<Map<String,Geschichte>> futureStories;
  //We set this here for now. The machinery is in place to handle more than one
  //story but we don't have one for now ;-)
  String currentStory = 'Raja';
  bool offlineData, cannotLoad=false;
  Held hero = Held.initial();
  ConnectionStatus connectionStatus = new ConnectionStatus();

  //We want to use this all throughout the app so it should be a singleton
  DataHandler._privateConstructor();

  static final DataHandler _instance = DataHandler._privateConstructor();

  factory DataHandler({Firestore firestore}){
    return _instance;
  }

  get getCurrentStory => stories[currentStory];

  //Hero-setter also ensuring Firebase and local data are
  //always up-to-date
  Future<void> updateHero() async{
    //We await this. Otherwise it is to easy to get the user
    //into an ill-defined state or losing data
    await writeLocalUserData(hero);
    //We can only update the substitutions if we have already
    //loaded all general data
    if(generalData != null) {
      updateSubstitutions();
    }
  }

  void updateSubstitutions(){
    substitution = Substitution(hero: hero, generalData: generalData);
  }

  Future<void> checkDataSituation() async{
    //Check if we are connected to the internet
    await connectionStatus.checkConnection();
    //If so - we can check if there are any updates available for us
    //If not we see if we have local data - if not we need to inform the user
    //that they need to go online to retrieve it
    offlineData = await canWorkOffline();
  }

  Future<Map<String,Geschichte>> updateStoryDataFromTheWeb() async {
    //Check all stories for updates
    List<String> _storiesLocal = versionController.stories.keys.toList();

    //Update existing stories
    for (String _storyname in firebaseVersions.stories.keys) {
      if (_storiesLocal.contains(_storyname)) {
        if (versionController.stories[_storyname] < firebaseVersions.stories[_storyname]) {
          stories[_storyname] = await loadGeschichte(firestore: firestore, story: stories[_storyname]);
          versionController.stories[_storyname] = firebaseVersions.stories[_storyname];
          //Update local data
          await updateLocalStoryData(updatedVersion: versionController, updatedStory: stories[_storyname]);
        }
      }
      //Add missing stories
      else {
        //Create new story-entry and load data from firestore
        stories[_storyname] = Geschichte(storyname: _storyname);
        stories[_storyname] = await loadGeschichte(firestore: firestore, story: stories[_storyname]);
        //Add version data to local version controller
        versionController.stories[_storyname] = firebaseVersions.stories[_storyname];
        //Update local data
        await updateLocalStoryData(updatedVersion: versionController, updatedStory: stories[_storyname]);
      }
    }
    //Update version-information on disk
    await writeLocalVersionData(versionController);
    return stories;
  }

  Future<GeneralData> updateGeneralDataFromTheWeb() async {
    //Load current local data before updating
    //This is data-loading is rather selective so we do it synchronously
    if (versionController.gendering < firebaseVersions.gendering) {
      generalData.gendering = await loadGendering(firestore);
      versionController.gendering = firebaseVersions.gendering;
      //Update data on disk
      await writeLocalGenderingData(generalData);
      }

    if (versionController.erlebnisse < firebaseVersions.erlebnisse) {
      generalData.erlebnisse = await loadErlebnisse(firestore);
      versionController.erlebnisse = firebaseVersions.erlebnisse;
      //Update data on disk
      await writeLocalErlebnisseData(generalData);
    }

    //Update version-information on disk
    await writeLocalVersionData(versionController);
    return generalData;
  }

  Future<void> loadData() async {
    versionController = await loadLocalVersionData();
    if(connectionStatus.online){firebaseVersions = await loadVersionInformation(firestore: firestore);}

    //If we have offline data we load it as we'll update or use it directly
    if (offlineData) {
      generalData = await loadLocalGeneralData();
      stories = await loadAllLocalStoryData();
      if(connectionStatus.online) {
        //If we are connected to the internet: check if there are updates available
        //We can do this asynchronously as the sub-processes keep the order in tact
        updateGeneralDataFromTheWeb();
        updateStoryDataFromTheWeb();
      }
    }
    //If we don't have offline data we need to load it - this is done asynchronously
    //So we don't slow-down loading
    else{
      if(connectionStatus.online) {
        futureGeneralData = loadGeneralData(firestore);
        futureStories = loadGeschichten(firestore);
        versionController = firebaseVersions;
      }
      //If we don't have a connection we need to tell the user to connect to the internet
      else{cannotLoad=true;}
    }
    //If there was an error loading we also re-load
    //This checks if we failed to load from file (error in loading)
    if((generalData==null&&stories==null&&futureGeneralData==null&&futureStories==null))
      {
        cannotLoad=true;
        //Clean-up incorrect files
        await deleteLocalStoryData();
        await deleteLocalGeneralData();
        await deleteLocalVersionData();
      }
    else{cannotLoad=false;}

    //Update Versions on file
    await writeLocalVersionData(versionController);

    //We catch reading-errors in the reading itself
    //and return default values in that case
    hero = await loadLocalUserData();
    hero.analytics = new FirebaseAnalytics();
    updateHero();
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

  // Initialize new User with defaults
  Held.initial(){
    _lastOption = _defaults['lastOption'];
    _erlebnisse = _defaults['erlebnisse'];
    _screens = _defaults['screens'];
    _iScreen = _defaults['iScreen'];
  }

  //Generate Hero from map
  Held.fromMap(Map<String,dynamic> _map){
    _name = _map['name'];
    userImage = _map['userImage'];
    _username = _map['username'];
    _lastOption = _map['lastOption'];
    _geschlecht = _map['geschlecht'];
    _erlebnisse = _map['erlebnisse'];
    _screens = _map['screens'];
    _iScreen = _map['iScreen'];
  }

  // Setters with sanity-checks
  set name(String valIn){
    (valIn != null && valIn.length != 0)?_name = valIn.trim():throw new Exception('Invalid name!');
  }
  set username(String valIn){
    (valIn != null && valIn.length != 0)?_username = valIn.trim():throw new Exception('Invalid name!');
  }
  set geschlecht(String valIn){
    (valIn=='m' || valIn=='w')?_geschlecht = valIn:throw new Exception('Invalid sex!');
  }
  set addErlebniss(String valIn){
    if(valIn != null && valIn != ''){
      _erlebnisse.add(valIn);
      if(analytics != null){
        analytics.logEvent(name: valIn);
      }
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
        :_lastOption=valIn;
  }

  // Getters
  String get name => _name;
  String get username => _username;
  int get iScreen => _iScreen;
  String get geschlecht => _geschlecht;
  List<String> get erlebnisse => _erlebnisse;
  List<int> get screens => _screens;
  String get lastOption => (iScreen!=0 || iScreen!=888 || iScreen!=999)?_lastOption:'';

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
    Map<String, Map<String,String>> _erlebnisseOut = Map<String, Map<String,String>>();
    for(String _key in erlebnisse.keys){
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
    stories = new Map<String,double>();

    for(String _key in _map.keys){
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

    for(String _key in stories.keys){
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
    for(String _key in generalData.gendering.keys){
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
  String zusammenfassung;
  Held hero;
  Map<int,Map<String,dynamic>> screens;

  Geschichte({this.storyname});

  Geschichte.fromFirebaseMap(Map<String, dynamic> map)
      : assert(map['name'] != null),
        assert(map['zusammenfassung'] != null),
        storyname = map['name'],
        zusammenfassung = map['zusammenfassung'];

  //Used to set data from local file
  void setFromJSON({Image imageIn, Map<String,dynamic> screensJSON,
    String summary}){
    screens = screensFromJSON(screensJSON);
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
    for(int _key in screens.keys){
      _screensJSON[_key.toString()] = screens[_key];
    }
    return _screensJSON;
  }

  Map<int,Map<String,dynamic>> screensFromJSON(Map<String,dynamic> _screensJSON){
    Map<int,Map<String,dynamic>> _screensInt = Map<int,Map<String,dynamic>>();
    for(String _key in _screensJSON.keys){
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