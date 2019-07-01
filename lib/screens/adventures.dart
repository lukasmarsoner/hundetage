import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:hundetage/utilities/menuBottomSheet.dart';
import 'package:hundetage/utilities/styles.dart';
import 'package:hundetage/utilities/dataHandling.dart';

class GeschichteMainScreen extends StatefulWidget{
  final DataHandler dataHandler;

  GeschichteMainScreen({@required this.dataHandler});

  @override
  GeschichteMainScreenState createState() => GeschichteMainScreenState(dataHandler: dataHandler);
}

class GeschichteMainScreenState extends State<GeschichteMainScreen>{
  DataHandler dataHandler;
  double imageHeight = 100.0;
  bool _storiesLoading, _generalDataLoading;
  double get getHeight => MediaQuery.of(context).size.height;
  double get getWidth => MediaQuery.of(context).size.width;

  GeschichteMainScreenState({@required this.dataHandler});

  @override
  void initState() { 
    super.initState();
    _storiesLoading = true;
    _generalDataLoading = true;
    SchedulerBinding.instance.addPostFrameCallback((_)=>_waitForFutures());
  }

  Future<void> _waitForFutures() async{
    //Write stuff to file so it is there next time
    if(dataHandler.futureStories != null) {
      dataHandler.stories = await dataHandler.futureStories;
      await writeAllLocalStoriesData(dataHandler.stories);
    }
    setState(() => _storiesLoading = false);
    if(dataHandler.futureGeneralData != null) {
      dataHandler.generalData = await dataHandler.futureGeneralData;
      await writeLocalGeneralData(dataHandler.generalData);
    }
    dataHandler.updateSubstitutions();
    setState(() => _generalDataLoading = false);
  }

  //If we have not loaded yet we need to finish here
  Widget _showCircularProgress({DataHandler dataHandler}){
    return (_storiesLoading || _generalDataLoading)
      ?Stack(key: Key('Loading Story Screen'), children: <Widget>[_dummyStory(), CircularProgressIndicator()])
      :_story(dataHandler: dataHandler);
  }

  Widget _story({DataHandler dataHandler}){
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            key: Key('Main Story Screen'),
            body: Container(child:
            SafeArea(child: Stack(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(bottom: minHeightBottomSheet+5),
                    child: StoryText(dataHandler: dataHandler, imageHeight: imageHeight)),
                MenuBottomSheet(dataHandler: dataHandler)
              ],
            )))
        )
    );
  }

  //Is shown if data has not finished loading yet
  Widget _dummyStory(){
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Container(child:
            SafeArea(child: Stack(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(bottom: minHeightBottomSheet+5),
                    child: Container(height: imageHeight)),
                DummyMenuButtonSheet()
              ],
            )))
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showCircularProgress(dataHandler: dataHandler);
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
  double get getWidth => MediaQuery.of(context).size.width;
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
    textCallback==null
      ?textCallback=() => null
      :await animationNextScreen.forward();
    textCallback();
  }

  //Build text of main story (not options)
  Widget _buildStaticText(text){
    return Text(text,
        style: italic==null
            ?bold==null?textStyle:textBoldStyle
            :bold==null?textItalicStyle:textBoldItalicStyle);
  }

  //Build option texts
  Widget _buildTextWithFadeOut({String text, BuildContext context}){
    return new AnimatedBuilder(animation: opacity,
        builder: (BuildContext context, Widget child) {
          return new Opacity(opacity: 1.0 - opacity.value,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _characterCount.isCompleted
                  ?Image.asset('assets/images/forward.png', height: 20, width: 20, key:Key('Option'))
                  :Container(),
                SizedBox(width: 10),
                Flexible(fit: FlexFit.loose,
                  child: Text(text,
                    softWrap: true,
                    style: italic==null
                      ?bold==null?textStyle:textBoldStyle
                      :bold==null?textItalicStyle:textBoldItalicStyle))
              ])
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    _textStrings = <String>[animatedString];
    _animateText();
    if(!(animationNextScreen==null)){_fadeOut();}
    return _characterCount == null ? Container() : new AnimatedBuilder(
        animation: _characterCount,
        builder: (BuildContext context, Widget child){
          String text = _currentString.substring(0, _characterCount.value);
          return new GestureDetector(
              onTap: moveToNextScreen,
              child: opacity == null
                  //Main story text
                  ?_buildStaticText(text)
                  //Option texts
                  :_buildTextWithFadeOut(text: text, context: context)
          );
        });
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
  double get getWidth => MediaQuery.of(context).size.width;
  double get getHeight => MediaQuery.of(context).size.height;

  StoryTextState({@required this.dataHandler, @required this.imageHeight});

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
  _textCallback(String iNext, String erlebniss, String option){
    //Update last option in hero
    dataHandler.hero.lastOption = option;

    //Show pop-up if user encounters a new event
    if(erlebniss!='' && !dataHandler.hero.erlebnisse.contains(erlebniss)){
      _openDialog(ShowErlebniss(erlebniss: dataHandler.generalData.erlebnisse[erlebniss],
          dataHandler: dataHandler, getHeight: getHeight, getWidth: getWidth), context);}
    setState((){
      dataHandler.hero.iScreen = int.parse(iNext);
      dataHandler.hero.addScreen = int.parse(iNext);
      dataHandler.hero.addErlebniss = erlebniss;
    });
    dataHandler.updateHero();
    animationText.reset();
    animationText.forward();
  }

  Widget _buildOption({int iOption}){
    return Container(
      padding: EdgeInsets.all(25),
      child: StringAnimation(animatedString: optionTexts[iOption], totalLength: totalTextLength,
          delay: delays[iOption], animationText: animationText,
          key: Key('Screen ${dataHandler.hero.iScreen} Option $iOption'), italic: true,
          textCallback: () => _textCallback(forwards[iOption], _erlebnisse[iOption], optionTexts[iOption])),
    );
  }

  @override
  Widget build(BuildContext context){
    //Add previous option to story text
    storyText = dataHandler.substitution.applyAllSubstitutions(dataHandler.hero.lastOption + ' ' +
            dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['text']);
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
      String _text = dataHandler.substitution.applyAllSubstitutions(
          dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['options'][i.toString()]);
      optionTexts.add(_text);
      totalTextLength += _text.length;
      delays.add(totalTextLength);
      _condition = dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['conditions'][i.toString()];
      _erlebnisse.add(dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['erlebnisse'][i.toString()]);
      //Check if conditions for the option are fulfilled
      _validForward.add(dataHandler.hero.erlebnisse.contains(_condition)||_condition=='');
    }

    //We should always have an equal number of options and forwards for them
    //As we don't add all forwards to the screen we add dummy-forwards for the remaining ones
    forwards = <String>[];
    for(int i=0;i<_optionKeys.length;i++){
      if(_validForward[i])
      {forwards.add(dataHandler.getCurrentStory.screens[dataHandler.hero.iScreen]['forwards'][i.toString()]);}
      else{forwards.add('');}
    }

    //Create widget for main text
    animatedTexts = <Widget>[];
    animatedTexts.add(Container(
      padding: EdgeInsets.fromLTRB(25,40,25,15),
      child: StringAnimation(animatedString: storyText, delay: 0, key: Key('Story Text ${dataHandler.hero.iScreen}'),
        totalLength:totalTextLength, animationText: animationText),
    ));

    //Create widgets for options
    for(int i=0;i<_optionKeys.length;i++){if(_validForward[i]){animatedTexts.add(_buildOption(iOption: i));}}

    return new Scrollbar(
      child: new ListView(
        key: Key('Text'),
        children: animatedTexts
    ));
  }
}
