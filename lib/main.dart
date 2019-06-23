import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/screens/welcome.dart';
import 'package:flutter/scheduler.dart';
import 'package:hundetage/screens/userChat.dart';
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

  @override
  Widget build(BuildContext context){
    //Check if user has been loaded from file...
    bool _userFromFile = dataHandler.hero.userImage!=null && dataHandler.hero.username!=null
        && dataHandler.hero.name!=null && dataHandler.hero.geschlecht!=null;
    return _userFromFile
        ?WelcomeScreen(dataHandler: dataHandler)
        :UserChat(dataHandler: dataHandler);
  }
}