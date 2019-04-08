import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hundetage/utilities/firebase.dart';

class GeschichteMainScreen extends StatefulWidget{
  final Function updateHero;
  final Held hero;
  final Geschichte geschichte;

  GeschichteMainScreen({@required this.updateHero, @required this.hero,
  @required this.geschichte});

  @override
  GeschichteMainScreenState createState() => GeschichteMainScreenState(updateHero: updateHero,
  hero: hero, geschichte: geschichte);
}

class GeschichteMainScreenState extends State<GeschichteMainScreen> with TickerProviderStateMixin{
  AnimationController _animationController;
  Animation<int> _characterCount;
  Function updateHero;
  Geschichte geschichte;
  Held hero;

  GeschichteMainScreenState({@required this.updateHero, @required this.hero,
  @required this.geschichte});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Container(

            )
        )
    );
  }
}

class Geschichte{
  String storyname;
  Held hero;
  List<Map<String,dynamic>> screens;

  Geschichte({@required this.hero, @required this.storyname, this.screens});

  void setStory(List<Map<String,dynamic>> _map) => screens = _map;
}

class StoryLoadingScreen extends StatefulWidget{
  final Function updateHero;
  final Held hero;
  final String storyname;
  final Firestore firestore;
  final Geschichte geschichte;

  StoryLoadingScreen({@required this.updateHero, @required this.hero,
  @required this.firestore, @required this.storyname, @required this.geschichte});

  @override
  StoryLoadingScreenState createState() => new StoryLoadingScreenState(hero: hero,
  updateHero: updateHero, firestore: firestore, storyname: storyname,
  geschichte: geschichte);
}

class StoryLoadingScreenState extends State<StoryLoadingScreen> with TickerProviderStateMixin{
  Held hero;
  String storyname;
  Function updateHero;
  Geschichte geschichte;
  Animation<int> _characterCount;
  AnimationController _animationController;
  bool _isLoading = true;
  Firestore firestore;

  StoryLoadingScreenState({@required this.updateHero, @required this.hero,
    @required this.firestore, @required this.storyname, @required this.geschichte});

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
    _animationController.dispose();
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
          Image.asset('images/icon.png', width: 200.0, height: 200.0),
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

  Future<void> _loadData() async{
    geschichte = await loadGeschichte(geschichte:geschichte, firestore: firestore);
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _animateText();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Widget _showCircularProgress(){
    return _isLoading
        ?Center(child: _loadingScreen())
        :GeschichteMainScreen(hero: hero, updateHero: updateHero,
        geschichte: geschichte);
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner: false,
        home: Scaffold(body:_showCircularProgress()));}
}