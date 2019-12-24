import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utilities.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DataHandler dataHandler = new DataHandler();
  dataHandler.firestore = mockFirestore;
  dataHandler.connectionStatus.online = true;
  dataHandler.offlineData = false;

  setUpAll(() async {
    // Create a temporary directory.
    final directory = await Directory.systemTemp.createTemp();

    // Mock out the MethodChannel for the path_provider plugin.
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      // If you're getting the apps documents directory, return the path to the
      // temp directory on the test environment instead.
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return directory.path;
      }
      return null;
    });
  });

  group('Test local Routines', () {
    //Tests start from here
    test('Local Story Data', () async {
      Geschichte _story = new Geschichte.fromFirebaseMap(adventure);
      _story.setStory(adventure['screens']);
      VersionController _versions = new VersionController.fromMap(versionData);
      expect(_versions.stories['Raja'], 1.1);
      writeLocalVersionData(_versions);
      _versions.stories['Raja'] = 1.3;
      expect(_story.storyname, 'Raja');
      Map<String,Geschichte> _stories = {'Raja': _story};
      await writeAllLocalStoriesData(_stories);
      _stories['Raja'].zusammenfassung = 'neuer Name';
      //Test updating
      await writeAllLocalStoriesData(_stories);
      await updateLocalStoryData(updatedStory: _story, updatedVersion: _versions);
      Geschichte _newStory = (await loadAllLocalStoryData())['Raja'];
      expect(_newStory.zusammenfassung, 'neuer Name');
      expect(_newStory.storyname, 'Raja');

      //Tes Hero data
      Held _testHeld = new Held.initial();
      _testHeld.name = 'TestName';
      writeLocalUserData(_testHeld);
      Held _loadedHeld = await loadLocalUserData();
      expect(_loadedHeld.name, 'TestName');

      //Test General data
      Map<String, dynamic> _generalDataMap= new Map<String, dynamic>();
      _generalDataMap['gendering'] = genderingMockData;
      Map<String,Erlebniss> erlebnisseIn = new Map<String,Erlebniss>();
      for (String _key in erlebnisseMockData.keys){
        erlebnisseIn[_key] = Erlebniss(text: erlebnisseMockData[_key]['text'],
        image: Image.asset('assets/images/jakob_lukas.png'), url: erlebnisseMockData[_key]['url'],
        title: erlebnisseMockData[_key]['title']);
      }
      _generalDataMap['erlebnisse'] = erlebnisseIn;
      GeneralData _generalData = new GeneralData.fromMap(_generalDataMap);

      writeLocalGeneralData(_generalData);
      GeneralData _loadedData = await loadLocalGeneralData();
      for (String _key in _generalData.erlebnisse.keys) {
        expect(_loadedData.erlebnisse[_key].text,
            _generalData.erlebnisse[_key].text);
        expect(_loadedData.erlebnisse[_key].title,
            _generalData.erlebnisse[_key].title);
        expect(_loadedData.erlebnisse[_key].url,
            _generalData.erlebnisse[_key].url);
      }
      for (String _key in _generalData.gendering.keys) {
        for (String _mw in _generalData.gendering[_key].keys) {
          expect(_loadedData.gendering[_key][_mw],
              _generalData.gendering[_key][_mw]);
        }
      }

    });
  });

}