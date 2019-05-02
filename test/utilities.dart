import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'package:hundetage/main_screen.dart';

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
  'besteFreunde':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'image': 'https://example.com/image.png'},
  'alteFrau':{'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.', 'image': 'https://example.com/image.png'}};

Map<String, dynamic> adventure = {
  '0':
    {'conditions': {'0':'','1':''}, 'erlebnisse': {'0':'','1':''},
    'forwards': {'0':'1','1':'5'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'test0','1':'test1'}},
  '1':{
    'conditions': {'0':''}, 'erlebnisse': {'0':'alteFrau'},
    'forwards': {'0':'0'}, 'text': '#ErSie ist #eineine #wahrerwahre #HeldHeldin.',
    'options': {'0':'new page'}}};

Map<String, dynamic> adventureMetadata = {
  'name': 'Raja', 'version': 0.6, 'image': 'https...'};

final testHeld = new Held.test();
final testGeschichte = new Geschichte.fromMap(adventureMetadata);
final generalData = new GeneralData(erlebnisse: erlebnisseTestData,gendering: genderingTestData);
final substitutions = new Substitution(hero: testHeld, generalData: generalData);
final authenticator = new Authenticator();
