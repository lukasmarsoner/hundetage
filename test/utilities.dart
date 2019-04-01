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
            body:returnWidget));
  }
}

//Stuff needed by a number of tests
Map<String,Map<String,String>> genderingTestData = {'ErSie':{'m':'Er','w':'Sie'},
  'eineine':{'m':'ein','w':'eine'},
  'HeldHeldin':{'m':'Held','w':'Heldin'},
  'wahrerwahre':{'m':'wahrer','w':'wahre'}};
Map<String,Map<String,String>> erlebnisseTestData = {
  'besteFreunde':{'text': 'Some test Text', 'image': 'https://example.com/image.png'},
  'alteFrau':{'text': 'Some other test Text', 'image': 'https://example.com/image.png'}};
final testHeld = new Held.test();
final generalData = new GeneralData(erlebnisse: erlebnisseTestData,gendering: genderingTestData);
final substitutions = new Substitution(hero: testHeld, generalData: generalData);
final authenticator = new Authenticator();