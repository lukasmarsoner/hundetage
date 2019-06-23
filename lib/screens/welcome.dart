import 'package:flutter/material.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:hundetage/screens/adventures.dart';
import 'package:hundetage/utilities/styles.dart';

class WelcomeScreen extends StatelessWidget{
  final DataHandler dataHandler;

  WelcomeScreen({@required this.dataHandler});

  @override
  Widget build(BuildContext context) {
    double getHeight = MediaQuery.of(context).size.height;
    double getWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => GeschichteMainScreen(
                dataHandler: dataHandler))),
        child: Container(
          width: getWidth,
          height: getHeight,
        decoration: BoxDecoration(gradient: gradient),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Avtar(size: 180, dataHandler: dataHandler),
              SizedBox(height: 20),
              Text('Willkommen zurück ${dataHandler.hero.username}!', style: titleStyle),
              SizedBox(height: 5),
              Text('Schön, dass du wieder da bist', style: subTitleSmallStyle),
            ]
        ),
      )
    );
  }
}