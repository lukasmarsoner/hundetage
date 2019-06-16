import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/utilities/authentication.dart';

class StaticTestWidget extends StatelessWidget{
  final Widget returnWidget;

  StaticTestWidget({this.returnWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
        body: returnWidget));
  }
}

//Stuff needed by a number of tests
Map<String,Map<String,String>> genderingTestData = {'ErSie':{'m':'Er','w':'Sie'},
  'eineine':{'m':'ein','w':'eine'},
  'HeldHeldin':{'m':'Held','w':'Heldin'},
  'wahrerwahre':{'m':'wahrer','w':'wahre'}};

Map<String,Map<String,String>> erlebnisseTestData = {
  'besteFreunde':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'url': 'https://example.com/image.png'},
  'alteFrau':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'url': 'https://example.com/image.png'}};

//Data used for testing - we will return this in our mocked request to Firebase
//The data returnd from firebase is Map<dynamic,dynamic>, so the versions handed
//to the mock firebase should be of that same type. As tests seem to fail that
//way, we use the next-best thing
Map<String,dynamic> genderingMockData = {'ErSie':{'m':'Er','w':'Sie'},
  'eineine':{'m':'ein','w':'eine'},
  'HeldHeldin':{'m':'Held','w':'Heldin'},
  'wahrerwahre':{'m':'wahrer','w':'wahre'}};
Map<String,dynamic> erlebnisseMockData = {
  'besteFreunde':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'image': 'https://example.com/image.png'},
  'alteFrau':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'image': 'https://example.com/image.png'}};

Map<int,Map<String, dynamic>> screens = {
  0:
    {'conditions': {'0':'','1':''}, 'erlebnisse': {'0':'','1':''},
    'forwards': {'0':'1','1':'5'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'test0','1':'test1'}},
  1:{'conditions': {'0':''}, 'erlebnisse': {'0':'alteFrau'},
    'forwards': {'0':'0'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'new page'}}};

Map<String, dynamic> screensFirebase = {
  '0':
  {'conditions': {'0':'','1':''}, 'erlebnisse': {'0':'','1':''},
    'forwards': {'0':'1','1':'5'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'test0','1':'test1'}},
  '1':{'conditions': {'0':''}, 'erlebnisse': {'0':'alteFrau'},
    'forwards': {'0':'0'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'new page'}}};

Map<String, Geschichte> geschichten = {'Raja': Geschichte(storyname: 'Raja')};

Map<String, dynamic> adventureMetadata = {
  'name': 'Raja', 'image': 'https...'};

Map<String, double> versionData = {
  'gendering': 0.7, 'erlebnisse': 0.8, 'Raja': 0.8, 'GrosseFahrt': 0.0};

Map<String, dynamic> versionDataLower = {
  'gendering': 0.5, 'erlebnisse': 0.6, 'Raja': 0.8, 'GrosseFahrt': 0.0};

final testHeld = new Held.test();
final testGeschichte = new Geschichte.fromFirebaseMap(adventureMetadata);
final generalData = new GeneralData(erlebnisse: {'alteFrau':
Erlebniss(text: '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',image: Image.asset('images/icon.png')),
'besteFreunde':
Erlebniss(text: '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',image: Image.asset('images/icon.png'))}
,gendering: genderingTestData);
final substitutions = new Substitution(hero: testHeld, generalData: generalData);
final authenticator = new Authenticator();
final versionController = new VersionController.fromMap(versionData);
