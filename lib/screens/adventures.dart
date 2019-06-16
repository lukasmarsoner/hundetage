import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';

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
              color: Colors.blue)
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
                                    'assets/images/user_images/hund_${hero.iBild}.jpg'),
                                minRadius: 60.0,
                                maxRadius: 60.0))))))]));
  }
}

class GeschichteMainScreen extends StatefulWidget{
  final DataHandler dataHandler;

  GeschichteMainScreen({@required this.dataHandler});

  @override
  GeschichteMainScreenState createState() => GeschichteMainScreenState(dataHandler: dataHandler);
}

class GeschichteMainScreenState extends State<GeschichteMainScreen>{
  DataHandler dataHandler;
  double imageHeight = 100.0;

  void updateDataStory({DataHandler newData}){
    setState(() {
      dataHandler.updateData = newData;
    });
  }

  GeschichteMainScreenState({@required this.dataHandler});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: new Stack(
              children: <Widget>[
                StoryText(dataHandler: dataHandler, imageHeight: imageHeight),
                TopAdventurePanel(imageHeight: imageHeight, hero: dataHandler.hero),
                ProfileAdventureRow(imageHeight: imageHeight, hero: dataHandler.hero),
                ],
            )
    ));
  }
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
  final DataHandler dataHandler;
  final double imageHeight;

  StoryText({@required this.dataHandler, @required this.imageHeight});

  @override
  StoryTextState createState() => new StoryTextState(imageHeight: imageHeight,
      dataHandler: dataHandler);
}

class StoryTextState extends State<StoryText> with TickerProviderStateMixin{
  DataHandler dataHandler;
  int totalTextLength;
  List<int> delays;
  List<Widget> animatedTexts;
  final int duration = 5;
  String storyText, _condition;
  List<String> _optionKeys, optionTexts, forwards, _erlebnisse;
  List<bool> _validForward;
  double imageHeight;
  AnimationController animationText;

  StoryTextState({@required this.dataHandler, @required this.imageHeight});

  //Update user page and hand change to hero to main function
  void updateData({DataHandler newData}){
    setState(() {
      dataHandler.updateData = newData;
    });
  }

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
    //if(erlebniss!='' && !(dataHandler.hero.erlebnisse.contains(erlebniss))){
    //  _openDialog(ShowErlebniss(image: dataHandler.generalData.erlebnisse[erlebniss].image,
    //      text: convertText(dataHandler: dataHandler, textIn:dataHandler.generalData.erlebnisse[erlebniss].text)
    //  ), context);}
    setState((){
      dataHandler.hero.iScreen = int.parse(iNext);
      dataHandler.hero.addScreen = int.parse(iNext);
      dataHandler.hero.addErlebniss = erlebniss;
    });
    updateData(newData: dataHandler);
    animationText.reset();
    animationText.forward();
  }

  Widget _buildOption({int iOption}){
    return Container(
      padding: EdgeInsets.all(20.0),
      child: StringAnimation(animatedString: optionTexts[iOption], totalLength: totalTextLength,
          delay: delays[iOption], animationText: animationText,
          key: Key(dataHandler.hero.iScreen.toString()+iOption.toString()), italic: true,
          textCallback: () => _textCallback(forwards[iOption], _erlebnisse[iOption])),
    );
  }

  @override
  Widget build(BuildContext context){
    storyText = convertText(dataHandler: dataHandler,
        textIn: dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['text']);
    totalTextLength = storyText.length;

    delays = <int>[];
    delays.add(storyText.length);
    _optionKeys = dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['options'].keys.toList();
    //I don't really like that all keys are strings but this is what we get from JSON...
    //Not sure if it is worth fixing this here and having the inconsistency of types elsewhere...
    optionTexts = <String>[];
    _erlebnisse = <String>[];
    _validForward = <bool>[];
    for(int i=0; i<_optionKeys.length;i++){
      String _text = convertText(dataHandler: dataHandler,
          textIn: dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['options'][i.toString()]);
      optionTexts.add(_text);
      totalTextLength += _text.length;
      delays.add(totalTextLength);
      _condition = dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['conditions'][i.toString()];
      _erlebnisse.add(dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['erlebnisse'][i.toString()]);
      //Check if conditions for the option are fulfilled
      _validForward.add(dataHandler.hero.erlebnisse.contains(_condition)||_condition=='');
    }

    //We should always have an equal number of options and forwards for them
    forwards = <String>[];
    for(int i=0;i<_optionKeys.length;i++){if(_validForward[i])
    {forwards.add(dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['forwards'][i.toString()]);}}

    //Create widget for main text
    animatedTexts = <Widget>[];
    animatedTexts.add(Container(
      padding: EdgeInsets.fromLTRB(20.0, imageHeight+50.0, 20.0, 20.0),
      child: StringAnimation(animatedString: storyText, delay: 0, key: Key(dataHandler.hero.iScreen.toString()),
        totalLength:totalTextLength, animationText: animationText),
    ));

    //Create widgets for options
    for(int i=0;i<_optionKeys.length;i++){if(_validForward[i]){animatedTexts.add(_buildOption(iOption: i));}}

    return new Scrollbar(child: new ListView(
            children: animatedTexts
    ));
  }
}
