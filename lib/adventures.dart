import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/erlebnisse.dart';
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
  final GeneralData generalData;
  final Geschichte geschichte;
  final Substitution substitution;

  GeschichteMainScreen({@required this.updateHero, @required this.hero,
  @required this.geschichte, @required this.substitution, @required this.generalData});

  @override
  GeschichteMainScreenState createState() => GeschichteMainScreenState(updateHero: updateHero,
  hero: hero, geschichte: geschichte, substitution: substitution, generalData: generalData);
}

class GeschichteMainScreenState extends State<GeschichteMainScreen>{
  Function updateHero;
  Geschichte geschichte;
  GeneralData generalData;
  Substitution substitution;
  Held hero;
  double imageHeight = 100.0;

  void updateHeroStory({Held newHero}){
    setState(() {
      hero = newHero;
      updateHero(newHero: hero);
    });
  }

  GeschichteMainScreenState({@required this.updateHero, @required this.hero,
  @required this.geschichte, @required this.substitution, @required this.generalData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: new Stack(
              children: <Widget>[
                StoryText(hero: hero, substitution: substitution, updateHeroStory: updateHeroStory,
                  geschichte: geschichte, imageHeight: imageHeight, generalData: generalData),
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
  Map<int,Map<String,dynamic>> screens;

  Geschichte({@required this.hero, @required this.storyname, this.screens});

  //Make sure all maps have the correct types
  void setStory(List<Map<String,dynamic>> _map){
    screens = {};
    for(int i=0;i<_map.length;i++){
      Map<String,dynamic> _screen = {};
      _screen['options'] = Map<String,String>.from(_map[i]['options']);
      _screen['forwards'] = Map<String,String>.from(_map[i]['forwards']);
      _screen['erlebnisse'] = Map<String,String>.from(_map[i]['erlebnisse']);
      _screen['conditions'] = Map<String,String>.from(_map[i]['conditions']);
      _screen['text'] = _map[i]['text'];
      screens[i] = _screen;
    }
  }
}

class StoryLoadingScreen extends StatefulWidget{
  final Function updateHero;
  final Held hero;
  final GeneralData generalData;
  final String storyname;
  final Firestore firestore;
  final Substitution substitution;
  final Geschichte geschichte;

  StoryLoadingScreen({@required this.updateHero, @required this.hero,
  @required this.firestore, @required this.storyname, @required this.geschichte,
  @required this.substitution, @required this.generalData});

  @override
  StoryLoadingScreenState createState() => new StoryLoadingScreenState(hero: hero,
  updateHero: updateHero, firestore: firestore, storyname: storyname,
  geschichte: geschichte, substitution: substitution, generalData: generalData);
}

class StoryLoadingScreenState extends State<StoryLoadingScreen> with TickerProviderStateMixin{
  Held hero;
  String storyname;
  Function updateHero;
  GeneralData generalData;
  Geschichte geschichte;
  Substitution substitution;
  Animation<int> _characterCount;
  AnimationController _animationText;
  bool _isLoading = true;
  Firestore firestore;

  StoryLoadingScreenState({@required this.updateHero, @required this.hero,
    @required this.firestore, @required this.storyname, @required this.geschichte,
    @required this.substitution, @required this.generalData});

  int _stringIndex;
  static const List<String> _textStrings = const <String>[
    'Daten werden geladen...',
  ];

  String get _currentString => _textStrings[_stringIndex % _textStrings.length];

  Future<void> _animateText() async {
    _animationText = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    setState(() {
      _stringIndex = _stringIndex == null ? 0 : _stringIndex + 1;
      _characterCount = new StepTween(begin: 0, end: _currentString.length)
          .animate(
          new CurvedAnimation(parent: _animationText, curve: Curves.easeIn));
    });
    await _animationText.forward();
  }

  @override
  void dispose() {
    _animationText.dispose();
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
        :GeschichteMainScreen(hero: hero, updateHero: updateHero, generalData: generalData,
        geschichte: geschichte, substitution: substitution);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(body: _showCircularProgress());}
}

class StringAnimation extends StatefulWidget{
  final String animatedString;
  final Function textCallback;
  final AnimationController animationText;
  final int delay, totalLength;
  final Key key;
  final bool italic;

  StringAnimation({@required this.animatedString, @required this.delay,
    @required this.totalLength, @required this.animationText, @required this.key,
    this.textCallback, this.italic});

  @override
  StringAnimationState createState() => new StringAnimationState(animatedString: animatedString,
      textCallback: textCallback, delay: delay, totalLength: totalLength, key: key,
      animationText: animationText, italic: italic);
}

class StringAnimationState extends State<StringAnimation> with TickerProviderStateMixin{
  String animatedString;
  Function textCallback;
  Key key;
  Animation<double> opacity;
  bool italic, bold;
  final int delay, totalLength;
  Animation<int> _characterCount;
  List<String> _textStrings;
  int _stringIndex;
  AnimationController animationText, animationNextScreen;

  StringAnimationState({@required this.animatedString, @required this.delay,
    @required this.key, @required this.totalLength, @required this.animationText,
    this.textCallback, this.italic});

  @override
  initState() {
    super.initState();
    //Animation for transition to new screen
    //We only need this when we have an option not a main text
    if(!(textCallback==null)){
      animationNextScreen = AnimationController(
        duration: Duration(milliseconds: 700),
        vsync: this,
    );}
  }

  String get _currentString => _textStrings[_stringIndex % _textStrings.length];

  Future<void> _animateText() async {
    //Start and stop values for controlling the animation
    double _start = delay.toDouble() / totalLength.toDouble();
    double _stop = (delay+animatedString.length).toDouble() / totalLength.toDouble();
    setState(() {
      _stringIndex = _stringIndex == null ? 0 : _stringIndex + 1;
      _characterCount = new StepTween(begin: 0, end: animatedString.length)
          .animate(new CurvedAnimation(parent: animationText,
          curve: Interval(_start, _stop, curve: Curves.easeInOutCubic)));
    });
    await animationText.forward();
  }

  Future<void> _fadeOut() async {
    setState(() => opacity = new Tween(begin: 0.0,end: 1.0)
        .animate(new CurvedAnimation(parent: animationNextScreen,
        curve: Interval(0.0, 1.0, curve: Curves.easeIn))));
  }

  void moveToNextScreen() async{
    bold = true;
    //In case there is no callback function we just do nothing at all
    if(textCallback==null) {
      textCallback=()=>null;
    }
    else {
      await animationNextScreen.forward();
    }
    textCallback();
  }

  Widget _buildStaticText(text){
    return new Text(
                  text,
                  style: new TextStyle(
                      fontSize: 20.0,
                      fontStyle: italic == null
                          ? FontStyle.normal
                          : FontStyle.italic,
                      color: Colors.black,
                      fontWeight: bold == null
                          ? FontWeight.w300
                          : FontWeight.w500)
              );
  }

  Widget _buildTextWithFadeOut({String text, BuildContext context}){
    return new AnimatedBuilder(animation: opacity,
        builder: (BuildContext context, Widget child) {
          return new Opacity(opacity: 1.0 - opacity.value,
              child: new Text(
                  text,
                  style: new TextStyle(
                      fontSize: 20.0,
                      fontStyle: italic == null
                          ? FontStyle.normal
                          : FontStyle.italic,
                      color: Colors.black,
                      fontWeight: bold == null
                          ? FontWeight.w300
                          : FontWeight.w500)
              )
          );});
  }

  @override
  Widget build(BuildContext context) {
    _textStrings = <String>[animatedString];
    _animateText();
    if(!(animationNextScreen==null)){_fadeOut();}
    return _characterCount == null ? Container(key: key) : new AnimatedBuilder(
        key: key,
        animation: _characterCount,
        builder: (BuildContext context, Widget child){
          String text = _currentString.substring(0, _characterCount.value);
          return new GestureDetector(
              onTap: moveToNextScreen,
              child: opacity == null
                  ?_buildStaticText(text)
                  :_buildTextWithFadeOut(text: text, context: context)
          );});
  }
}

class StoryText extends StatefulWidget{
  final Function updateHeroStory;
  final Substitution substitution;
  final Geschichte geschichte;
  final Held hero;
  final GeneralData generalData;
  final double imageHeight;

  StoryText({@required this.geschichte, @required this.substitution, @required this.generalData,
  @required this.hero, @required this.imageHeight, @required this.updateHeroStory});

  @override
  StoryTextState createState() => new StoryTextState(geschichte: geschichte,
      substitution: substitution, hero: hero, imageHeight: imageHeight,
      updateHeroStory: updateHeroStory, generalData: generalData);
}

class StoryTextState extends State<StoryText> with TickerProviderStateMixin{
  Function updateHeroStory;
  Substitution substitution;
  Geschichte geschichte;
  GeneralData generalData;
  Held hero;
  int totalTextLength;
  List<int> delays;
  List<Widget> animatedTexts;
  final int duration = 5;
  String storyText, _condition;
  List<String> _optionKeys, optionTexts, forwards, _erlebnisse;
  List<bool> _validForward;
  double imageHeight;
  AnimationController animationText;

  StoryTextState({@required this.substitution, @required this.geschichte,
  @required this.hero, @required this.imageHeight, @required this.updateHeroStory,
  @required this.generalData});

  @override
  initState() {
    super.initState();
    animationText = AnimationController(
      duration: Duration(seconds: duration),
      vsync: this,
    );
  }

  @override
  void dispose() {
    animationText.dispose();
    super.dispose();
  }

  String _convertText(String textIn){
    return substitution.applyAllSubstitutions(textIn);
  }

  _openDialog(Widget _dialog, BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return _dialog;
        }
    );
  }
  
  //Function moving user to next screen
  _textCallback(String iNext, String erlebniss){
    //Show pop-up if user encounters a new event
    if(erlebniss!='' && !(hero.erlebnisse.contains(erlebniss))){
      String _text = generalData.erlebnisse[erlebniss]['text'];
      Image _image = Image.network(generalData.erlebnisse[erlebniss]['image'], fit: BoxFit.cover);
      final _record = Erlebniss(text: _text, image: _image, substitution: substitution);
      _record.applySubstitutions();
      _openDialog(ShowErlebniss(image: _record.image, text: _record.text), context);}
    setState((){
      hero.iScreen = int.parse(iNext);
      hero.addScreen = int.parse(iNext);
      hero.addErlebniss = erlebniss;
    });
    updateHeroStory(newHero: hero);
    animationText.reset();
    animationText.forward();
  }

  Widget _buildOption({int iOption}){
    return Container(
      padding: EdgeInsets.all(20.0),
      child: StringAnimation(animatedString: optionTexts[iOption], totalLength: totalTextLength,
          delay: delays[iOption], animationText: animationText,
          key: Key(hero.iScreen.toString()+iOption.toString()), italic: true,
          textCallback: () => _textCallback(forwards[iOption], _erlebnisse[iOption])),
    );
  }

  @override
  Widget build(BuildContext context){
    storyText = _convertText(geschichte.screens[hero.iScreen]['text']);
    totalTextLength = storyText.length;

    delays = <int>[];
    delays.add(storyText.length);
    _optionKeys = geschichte.screens[hero.iScreen]['options'].keys.toList();
    //I don't really like that all keys are strings but this is what we get from JSON...
    //Not sure if it is worth fixing this here and having the inconsistency of types elsewhere...
    optionTexts = <String>[];
    _erlebnisse = <String>[];
    _validForward = <bool>[];
    for(int i=0; i<_optionKeys.length;i++){
      String _text = _convertText(geschichte.screens[hero.iScreen]['options'][i.toString()]);
      optionTexts.add(_text);
      totalTextLength += _text.length;
      delays.add(totalTextLength);
      _condition = geschichte.screens[hero.iScreen]['conditions'][i.toString()];
      _erlebnisse.add(geschichte.screens[hero.iScreen]['erlebnisse'][i.toString()]);
      //Check if conditions for the option are fulfilled
      _validForward.add(hero.erlebnisse.contains(_condition)||_condition=='');
    }

    //We should always have an equal number of options and forwards for them
    forwards = <String>[];
    for(int i=0;i<_optionKeys.length;i++){if(_validForward[i])
    {forwards.add(geschichte.screens[hero.iScreen]['forwards'][i.toString()]);}}

    //Create widget for main text
    animatedTexts = <Widget>[];
    animatedTexts.add(Container(
      padding: EdgeInsets.fromLTRB(20.0, imageHeight+50.0, 20.0, 20.0),
      child: StringAnimation(animatedString: storyText, delay: 0, key: Key(hero.iScreen.toString()),
        totalLength:totalTextLength, animationText: animationText),
    ));

    //Create widgets for options
    for(int i=0;i<_optionKeys.length;i++){if(_validForward[i]){animatedTexts.add(_buildOption(iOption: i));}}

    return new Scrollbar(child: new ListView(
            children: animatedTexts
    ));
  }
}
