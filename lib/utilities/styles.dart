import 'package:flutter/material.dart';

final titleStyle = new TextStyle(
    fontSize: 24,
    fontFamily: 'PatrickHand',
    color: Colors.white,
    fontWeight: FontWeight.w600);

final TextStyle titleBlackStyle = new TextStyle(
    fontSize: 24,
    fontFamily: 'PatrickHand',
    fontWeight: FontWeight.w600);

final TextStyle subTitleStyle = new TextStyle(
    fontSize: 18,
    fontFamily: 'IndieFlower',
    color: Colors.white,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w300);

final TextStyle subTitleBlackStyle = new TextStyle(
    fontSize: 18,
    fontFamily: 'IndieFlower',
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w300);

final TextStyle subTitleBlackBoldStyle = new TextStyle(
    fontSize: 18,
    fontFamily: 'IndieFlower',
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600);

final TextStyle textStyle = new TextStyle(
    fontSize: 16,
    fontFamily: 'Montserrat');

final Color red = Color(0xc8B02302);
final Color orange = Color(0xc8D95F11);
final Color yellow = Color(0xc8F19421);

class Background extends StatelessWidget {
  final double getWidth, getHeight;

  Background({@required this.getWidth, @required this.getHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: getWidth,
      height: getHeight,
      decoration: new BoxDecoration(
        gradient: LinearGradient(
          // Where the linear gradient begins and ends
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Add one stop for each color. Stops should increase from 0 to 1
          stops: [0.05, 0.3, 0.9],
          colors: [
            red,
            orange,
            yellow
          ],
        ),
      ),
    );
  }
}