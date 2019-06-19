import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/screens/mainScreen.dart';
import 'package:hundetage/utilities/styles.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/scheduler.dart';
import 'package:hundetage/utilities/dataHandling.dart';

void main() async{
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget{
  @override
  SplashScreenState createState() => new SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{
  Animation<int> _characterCount;
  AnimationController _animationController;
  bool _isLoading = true;
  DataHandler dataHandler;

  int _stringIndex;
  static const List<String> _textStrings = const <String>[
    'Daten werden geladen...',
  ];

  String get _currentString => _textStrings[_stringIndex % _textStrings.length];

  Future<void> _animateText() async {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    setState(() {
      _stringIndex = _stringIndex == null ? 0 : _stringIndex + 1;
      _characterCount = new StepTween(begin: 0, end: _currentString.length)
          .animate(
          new CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    });
    await _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _loadingScreen(){
    return Column(
            mainAxisAlignment:MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/images/icon.png', width: 200.0, height: 200.0),
              Container(
                  padding: EdgeInsets.only(top: 10.0),
                  child: _characterCount == null ? null : new AnimatedBuilder(
                    key: Key('loadingText'),
                      animation: _characterCount,
                      builder: (BuildContext context, Widget child) {
                      String text = _currentString.substring(0, _characterCount.value);
                      return new Text(text, style: new TextStyle(
                          fontSize: 20.0,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                      );
                    })
              ),
              Container(padding: EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator())
            ]
    );
  }

  @override
  void initState() {
    super.initState();
    _animateText();
    SchedulerBinding.instance.addPostFrameCallback((_)=>_runDataLoaders());
  }

  Future<void> _runDataLoaders() async{
    //Class taking care of all data-loading logic
    dataHandler = DataHandler();
    await dataHandler.loadData();
    setState(() => _isLoading = false);
  }

  Widget _showCircularProgress(){
    return _isLoading
        ?Center(child: _loadingScreen())
        :MyApp(dataHandler: dataHandler);
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner: false,
        home: Scaffold(body:_showCircularProgress()));}
}

class MyApp extends StatefulWidget{
  final DataHandler dataHandler;

  MyApp({@required this.dataHandler});

  @override
  _MyAppState createState() => new _MyAppState(dataHandler: dataHandler);
}

class _MyAppState extends State<MyApp>{
  DataHandler dataHandler;
  double get getWidth => MediaQuery.of(context).size.width;

  _MyAppState({@required this.dataHandler});

  //Update user page and hand change to hero to main function
  void updateData({DataHandler newData}){
    setState(() {
      dataHandler.updateData = newData;
    });
  }

    //Dialog for asking for permission to use analytics
  Widget useAnalyticsDialog() {
    return Center(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0)),
        child: Container(
          height: 520.0,
          width: getWidth-20,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 15.0),
                  child: Text('Nutzungsdaten',
                      style: titleBlackStyle),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15.0),
                  child: Text('Lieber Nutzer, um unsere Geschichte in Zukunft noch besser zu machen, '
                      'würden wir gerne anonyme Daten über dein Leseverhalten sammeln. '
                      'Um genau zu sein, möchten wir wissen, wie viele Nutzer gewisse '
                      'besondere Punkte in der Geschichte erreichen.'
                      'Alle Daten sind vollkommen anonym, helfen uns aber sehr dabei zu verstehen, '
                      'was dir an unserer Geschichte gefällt.'
                      'Wenn du das nicht möchtest, klick einfach auf "Nein" und genieß die Geschichte.\n\n'
                      'Liebe Grüße\n'
                      'Lukas und Jakob',
                      style: textStyle),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                            color: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            child: Text('Ja',
                                style: subTitleButtonStyle),
                            onPressed:() {
                              dataHandler.hero.useAnalytics = true;
                              dataHandler.hero.analytics = new FirebaseAnalytics();
                              updateData(newData: dataHandler);
                            }),
                        SizedBox(width: 30,),
                        RaisedButton(
                            color: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            child: Text('Nein',
                                style: subTitleButtonStyle),
                            onPressed:() {
                              dataHandler.hero.useAnalytics = false;
                              updateData(newData: dataHandler);
                            }),
                ])),
              ]
            ),
      )));
    }

  @override
  Widget build(BuildContext context){

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hundetage',
      home: Scaffold(body: dataHandler.hero.useAnalytics==null
          ?useAnalyticsDialog()
          :MainPage(dataHandler: dataHandler))
    );
  }
}