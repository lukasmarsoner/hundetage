import 'package:flutter/material.dart';

class StaticTestWidget extends StatelessWidget{
  final Widget returnWidget;

  StaticTestWidget({this.returnWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(body:returnWidget));
  }
}