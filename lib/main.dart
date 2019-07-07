import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/screens/welcome.dart';
import 'package:flutter/scheduler.dart';
import 'package:hundetage/utilities/styles.dart';
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
  AnimationController _animationController;
  bool _isLoading = true;
  DataHandler dataHandler = DataHandler();
  Animation<Color> _colorTween;
  double getHeight, getWidth;

  Future<void> _animateColor() async {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    setState(() {
      _colorTween = ColorTween(begin: red, end: yellow).animate(_animationController);
    });
    await _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _loadingScreen(){
    return Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Row(
            mainAxisAlignment:MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                  mainAxisAlignment:MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/icon.png', width: 200.0, height: 200.0),
                    SizedBox(height: 40,),
                    dataHandler.cannotLoad?Text('Keine Internetverbindung...', style: chatBoldStyle):Container(),
                    dataHandler.cannotLoad?SizedBox(height: 40,):Container(),
                    Container(key: Key('Loading...'), child: CircularProgressIndicator(valueColor: _colorTween))
                  ]
              )
            ]
        )
    );
  }

  @override
  void initState() {
    super.initState();
    _animateColor();
    SchedulerBinding.instance.addPostFrameCallback((_)=>_runDataLoaders());
  }

  Future<void> _runDataLoaders() async{
    //Class taking care of all data-loading logic
    await dataHandler.checkDataSituation();
    await dataHandler.loadData();
    //If we ca't load data we inform the user and try again
    if(dataHandler.cannotLoad){
      setState((){});
      _runDataLoaders();
    }
    else{setState(() => _isLoading = false);}
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

  @override
  Widget build(BuildContext context){
    //Check if user has been loaded from file...
    bool _userFromFile = dataHandler.hero.userImage!=null && dataHandler.hero.username!=null
        && dataHandler.hero.name!=null && dataHandler.hero.geschlecht!=null;
    return 
    
    _userFromFile
        ?WelcomeScreen(dataHandler: dataHandler)
        :UserChat(dataHandler: dataHandler);
  }
}