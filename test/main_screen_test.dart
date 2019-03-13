import 'package:flutter_test/flutter_test.dart';
import 'package:hundetage/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';

void main() {
  // Stuff we need for testing
  final Held _testHeld = new Held.initial();

  // Test top panes of main menu
  testWidgets('Test main-screen', (WidgetTester _testPage) async {
    await _testPage.pumpWidget(
        StaticTestWidget(returnWidget: ProfileRow(hero: _testHeld, imageHeight: 10.0))
    );

    final _findUsername = find.text(_testHeld.name);
    final _findJob = find.text('Beruf: ' + ((_testHeld.geschlecht == 'w') ? 'Abenteurerin' : 'Abenteurer'));

    expect(_findUsername, findsOneWidget);
    expect(_findJob, findsOneWidget);
  });

  // Test menu
  testWidgets('Test menu', (WidgetTester _testPage) async {
    await _testPage.pumpWidget(
        DynamicTestWidget(returnType:'Menu')
    );

    final _findMenuIcon = find.byIcon(Icons.settings);

    expect(_findMenuIcon, findsOneWidget);
  });
}

class StaticTestWidget extends StatelessWidget{
  final Widget returnWidget;

  StaticTestWidget({this.returnWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: returnWidget,
    );
  }
}

class DynamicTestWidget extends StatefulWidget {
  final String returnType;

  const DynamicTestWidget({this.returnType});

  @override
  DynamicTestWidgetState createState() => new DynamicTestWidgetState(returnType:returnType);
}

class DynamicTestWidgetState extends State<DynamicTestWidget> with SingleTickerProviderStateMixin{
  final String returnType;
  Widget returnWidget;

  DynamicTestWidgetState({this.returnType});

  @override
  Widget build(BuildContext context) {
    AnimationController animationController = new AnimationController(vsync: this,
        duration: Duration(milliseconds: 200));
    Animation<Color> colorAnimation = new ColorTween(begin: Colors.red, end: Colors.blue)
        .animate(animationController);

    if(returnType=='Menu'){
      returnWidget = new MenuButton(animationController: animationController, colorAnimation: colorAnimation,
          onButtonTap: () => null, hiddenSize: 10.0);
    }

    return MaterialApp(
      home: returnWidget
      );
  }
}