import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hundetage/utilities/firebase.dart';

//Cuts the square box on the top of the screen diagonally
class _DiagonalAdventureClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = new Path();
    path.lineTo(0.0, size.height - 20.0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

//Builds empty panel on top of the screen
class TopAdventurePanel extends StatelessWidget {
  final double imageHeight;
  final Held hero;

  TopAdventurePanel({@required this.imageHeight, @required this.hero});
  @override
  Widget build(BuildContext context) {
    return new Positioned.fill(
      bottom: null,
      child: new ClipPath(
          clipper: new _DiagonalAdventureClipper(),
          child: Container(
              height: imageHeight,
              width: MediaQuery.of(context).size.width,
              color: hero.geschlecht == 'm'? Colors.blueAccent : Colors.redAccent)
      ),
    );
  }
}

//Builds the user image and name to show in top panel
class ProfileAdventureRow extends StatelessWidget {
  final Held hero;
  final double imageHeight;

  ProfileAdventureRow({@required this.imageHeight, @required this.hero});

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: new EdgeInsets.only(left: 16.0, top: 30.0),
        child: new Row(
          children: [
            //Here we set the avatar image - the image is taken from hero
            new CircleAvatar(
                minRadius: 64.0,
                maxRadius: 64.0,
                backgroundColor: Colors.black,
                //Used to transition the image to other screens
                child: new Hero(
                    tag: 'userImage',
                    child: new Material(
                        color: Colors.transparent,
                        child: InkWell(
                            child: Center(child: new CircleAvatar(
                                backgroundImage: new AssetImage(
                                    hero.iBild!=-1?'images/user_images/hund_${hero.iBild}.jpg'
                                        :'images/user_images/fragezeichen.jpg'),
                                minRadius: 60.0,
                                maxRadius: 60.0))))))]));
  }
}

class GeschichteMainScreen extends StatefulWidget{
  final Function updateHero;
  final Held hero;
  final Geschichte geschichte;
  final Substitution substitution;

  GeschichteMainScreen({@required this.updateHero, @required this.hero,
  @required this.geschichte, @required this.substitution});

  @override
  GeschichteMainScreenState createState() => GeschichteMainScreenState(updateHero: updateHero,
  hero: hero, geschichte: geschichte, substitution: substitution);
}

class GeschichteMainScreenState extends State<GeschichteMainScreen>{
  Function updateHero;
  Geschichte geschichte;
  Substitution substitution;
  Held hero;
  double imageHeight = 100.0;

  GeschichteMainScreenState({@required this.updateHero, @required this.hero,
  @required this.geschichte, @required this.substitution});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: new Stack(
              children: <Widget>[
                StoryText(hero: hero, substitution: substitution,
                  geschichte: geschichte, imageHeight: imageHeight,),
                TopAdventurePanel(imageHeight: imageHeight, hero: hero),
                ProfileAdventureRow(imageHeight: imageHeight, hero: hero),
                ],
            )
    ));
  }
}

class Geschichte{
  String storyname;
  Held hero;
  List<Map<String,dynamic>> screens;

  Geschichte({@required this.hero, @required this.storyname, this.screens});

  //Make sure all maps have the correct types
  void setStory(List<Map<String,dynamic>> _map){
    screens = _map;
    for(int i=0;i<screens.length;i++){
      screens[i]['options'] = Map<String,String>.from(screens[i]['options']);
      screens[i]['forwards'] = Map<String,String>.from(screens[i]['forwards']);
      screens[i]['erlebnisse'] = Map<String,String>.from(screens[i]['erlebnisse']);
      screens[i]['conditions'] = Map<String,String>.from(screens[i]['conditions']);
    }
  }
}

class StoryLoadingScreen extends StatefulWidget{
  final Function updateHero;
  final Held hero;
  final String storyname;
  final Firestore firestore;
  final Substitution substitution;
  final Geschichte geschichte;

  StoryLoadingScreen({@required this.updateHero, @required this.hero,
  @required this.firestore, @required this.storyname, @required this.geschichte,
  @required this.substitution});

  @override
  StoryLoadingScreenState createState() => new StoryLoadingScreenState(hero: hero,
  updateHero: updateHero, firestore: firestore, storyname: storyname,
  geschichte: geschichte, substitution: substitution);
}

class StoryLoadingScreenState extends State<StoryLoadingScreen> with TickerProviderStateMixin{
  Held hero;
  String storyname;
  Function updateHero;
  Geschichte geschichte;
  Substitution substitution;
  Animation<int> _characterCount;
  AnimationController _animationController;
  bool _isLoading = true;
  Firestore firestore;

  StoryLoadingScreenState({@required this.updateHero, @required this.hero,
    @required this.firestore, @required this.storyname, @required this.geschichte,
    @required this.substitution});

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
        geschichte: geschichte, substitution: substitution);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(body: _showCircularProgress());}
}

class StringAnimation extends StatefulWidget{
  final String animatedString;
  final Function textCallback;
  final AnimationController animationController;
  final int delay, totalLength;

  StringAnimation({@required this.animatedString, @required this.delay,
    @required this.totalLength, @required this.animationController,
    this.textCallback});

  @override
  StringAnimationState createState() => new StringAnimationState(animatedString: animatedString,
      textCallback: textCallback, delay: delay, totalLength: totalLength,
      animationController: animationController);
}

class StringAnimationState extends State<StringAnimation> with TickerProviderStateMixin{
  String animatedString;
  Function textCallback;
  final int delay, totalLength;
  Animation<int> _characterCount;
  List<String> _textStrings;
  int _stringIndex;
  AnimationController animationController;

  StringAnimationState({@required this.animatedString, @required this.delay,
    @required this.totalLength, @required this.animationController, this.textCallback});

  String get _currentString => _textStrings[_stringIndex % _textStrings.length];

  Future<void> _animateText() async {
    //Start and stop values for controlling the animation
    double _start = delay.toDouble() / totalLength;
    double _stop = (delay+animatedString.length).toDouble() / totalLength;
    setState(() {
      _stringIndex = _stringIndex == null ? 0 : _stringIndex + 1;
      _characterCount = new StepTween(begin: 0, end: animatedString.length)
          .animate(new CurvedAnimation(parent: animationController,
          curve: Interval(_start, _stop, curve: Curves.easeInOutCubic)));
    });
    await animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    _textStrings = <String>[animatedString];
    //In case there is no callback function we just do nothing at all
    if(textCallback==null){textCallback=()=>null;}
    _animateText();
    return _characterCount == null ? Container() : new AnimatedBuilder(
        animation: _characterCount,
        builder: (BuildContext context, Widget child) {
          String text = _currentString.substring(0, _characterCount.value);
          return new GestureDetector(
            onTap: textCallback,
              child: new Text(
                text,
                key: Key('storyText'),
                style: new TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w300),
            )
          );
        });
  }
}

class StoryText extends StatefulWidget{
  final Substitution substitution;
  final Geschichte geschichte;
  final Held hero;
  final double imageHeight;

  StoryText({@required this.geschichte, @required this.substitution,
  @required this.hero, @required this.imageHeight});

  @override
  StoryTextState createState() => new StoryTextState(geschichte: geschichte,
      substitution: substitution, hero: hero, imageHeight: imageHeight);
}

class StoryTextState extends State<StoryText> with TickerProviderStateMixin{
  Substitution substitution;
  Geschichte geschichte;
  Held hero;
  int totalTextLength;
  List<int> delays = <int>[];
  final int duration = 5;
  String storyText;
  List<String> optionTexts = <String>[];
  double imageHeight;
  AnimationController animationController;

  StoryTextState({@required this.substitution, @required this.geschichte,
  @required this.hero, @required this.imageHeight});

  @override
  initState() {
    super.initState();
    animationController = AnimationController(
      duration: Duration(seconds: duration),
      vsync: this,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  String _convertText(String textIn){
    return substitution.applyAllSubstitutions(textIn);
  }

  Widget _buildOption({int iOption}){
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
      child: StringAnimation(animatedString: optionTexts[iOption], totalLength: totalTextLength,
          delay: delays[iOption], animationController: animationController,),
    );
  }

  @override
  Widget build(BuildContext context){
    //Animation take 5 second to compleate
    storyText = _convertText(geschichte.screens[hero.iScreen]['text']);
    totalTextLength = storyText.length;
    delays.add(storyText.length);
    List<String> _optionKeys = geschichte.screens[hero.iScreen]['options'].keys.toList();
    //I don't really like that all keys are strings but this is what we get from JSON...
    //Not sure if it is worth fixing this here and having the inconsistency of types elsewhere...
    for(int i=0; i<_optionKeys.length;i++){
      String _text = geschichte.screens[hero.iScreen]['options'][i.toString()];
      optionTexts.add(_text);
      totalTextLength += _text.length;
      delays.add(_text.length);
    }
    return new ListView(
            children: <Widget>[
              //Main story text
              Container(
              padding: EdgeInsets.fromLTRB(20.0, imageHeight+50.0, 20.0, 20.0),
              child: StringAnimation(animatedString: storyText,
                  delay: 0, totalLength:totalTextLength, animationController: animationController,),
              ),
              //First Option
              _buildOption(iOption: 0)
            ]
    );
  }
}
