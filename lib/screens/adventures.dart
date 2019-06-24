import 'package:flutter/material.dart';
import 'package:hundetage/menuBottomSheet.dart';
import 'package:hundetage/utilities/styles.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:hundetage/utilities/json.dart';
import 'dart:io';
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
  double get getHeight => MediaQuery.of(context).size.height;
  double get getWidth => MediaQuery.of(context).size.width;

  GeschichteMainScreenState({@required this.dataHandler});

  @override
  Widget build(BuildContext context) {
    Dialog userNameDialog  = new Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: NameDialog(dataHandler: dataHandler)
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Container(child:
            SafeArea(child: Stack(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(bottom: minHeightBottomSheet+5),
                    child: StoryText(dataHandler: dataHandler, imageHeight: imageHeight)),
                MenuBottomSheet(dataHandler: dataHandler,
                    homeButtonFunction: () => showDialog(context: context, builder: (BuildContext context) => userNameDialog))
              ],
            )))
        )
    );
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
    if(textCallback==null) {
      textCallback=()=>null;
    }
    else {
      await animationNextScreen.forward();
    }
    textCallback();
  }

  Widget _buildStaticText(text){
    return Text(text,
        style: italic==null
            ?bold==null?textStyle:textBoldStyle
            :bold==null?textItalicStyle:textBoldItalicStyle);
  }

  Widget _buildTextWithFadeOut({String text, BuildContext context}){
    return new AnimatedBuilder(animation: opacity,
        builder: (BuildContext context, Widget child) {
          return new Opacity(opacity: 1.0 - opacity.value,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _characterCount.isCompleted
                    ?Image.asset('assets/images/forward.png', height: 20, width: 20)
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
                  ?_buildStaticText(text)
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
    updateData(newData: dataHandler);
    animationText.reset();
    animationText.forward();
  }

  Widget _buildOption({int iOption}){
    return Container(
      padding: EdgeInsets.all(25),
      child: StringAnimation(animatedString: optionTexts[iOption], totalLength: totalTextLength,
          delay: delays[iOption], animationText: animationText,
          key: Key(dataHandler.hero.iScreen.toString()+iOption.toString()), italic: true,
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
      child: StringAnimation(animatedString: storyText, delay: 0, key: Key(dataHandler.hero.iScreen.toString()),
        totalLength:totalTextLength, animationText: animationText),
    ));

    //Create widgets for options
    for(int i=0;i<_optionKeys.length;i++){if(_validForward[i]){animatedTexts.add(_buildOption(iOption: i));}}

    return new Scrollbar(
        child: new ListView(
            children: animatedTexts
    ));
  }
}

class NameDialog extends StatefulWidget{
  final DataHandler dataHandler;

  NameDialog({@required this.dataHandler});

  @override
  NameDialogState createState() =>
      new NameDialogState(dataHandler: dataHandler);
}

class NameDialogState extends State<NameDialog>{
  DataHandler dataHandler;
  TextEditingController _controller;

  NameDialogState({@required this.dataHandler});

  void updateData({DataHandler newData}){
    setState(() {
      dataHandler.updateData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.all(15),
      child: Container(
        height: 420,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Avtar(size: 100, dataHandler: dataHandler, updateData: updateData),
            NameField(setUsername: true, updateData: updateData, dataHandler: dataHandler),
            SizedBox(height: 20,),
            NameField(setUsername: false, updateData: updateData,
                dataHandler: dataHandler),
            SizedBox(height: 30,),
            GenderSelection(dataHandler: dataHandler, updateData: updateData),
          ],
        ),
      ),
    );
  }
}

class NameField extends StatefulWidget{
  final DataHandler dataHandler;
  final Function updateData;
  final bool setUsername;

  NameField({@required this.dataHandler, @required this.updateData,
  @required this.setUsername});

  @override
  NameFieldState createState() =>
      new NameFieldState(dataHandler: dataHandler, updateData: updateData,
      setUsername: setUsername);
}

class NameFieldState extends State<NameField>{
  DataHandler dataHandler;
  Function updateData;
  bool setUsername;
  TextEditingController _controller;

  NameFieldState({@required this.dataHandler, @required this.updateData,
    @required this.setUsername});

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(
        text: setUsername?dataHandler.hero.username:dataHandler.hero.name);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            child: TextField(
              //This should make it more comfortable to write names
              textCapitalization: TextCapitalization.words,
              decoration: new InputDecoration(
                labelText: setUsername
                    ?'Dein Name'
                    :'${dataHandler.hero.geschlecht=='w'?'Unsere Heldin':'Unser Held'}',
              ),
              style: textStyle,
              controller: _controller,
              onChanged: (name){
                setUsername?dataHandler.hero.username=name:dataHandler.hero.name=name;
                updateData(newData: dataHandler);},
            )
        ));
  }
}

class Avtar extends StatelessWidget{
  final double size;
  final DataHandler dataHandler;
  final Function updateData;

  Avtar({@required this.size, @required this.dataHandler, @required this.updateData});

  Future<void> _setImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    await saveCameraImageToFile(image: imageFile, filename: 'user_image');
    dataHandler.hero.userImage = Image.file(imageFile, fit: BoxFit.cover);
    updateData(newData: dataHandler);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _setImage(),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size/50),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
          child: CircleAvatar(backgroundImage: dataHandler.hero.userImage.image)
      )
    );
  }
}

class GenderSelection extends StatefulWidget{
  final DataHandler dataHandler;
  final Function updateData;

  GenderSelection({@required this.dataHandler, @required this.updateData});

  @override
  GenderSelectionState createState() =>
      new GenderSelectionState(dataHandler: dataHandler, updateData: updateData);
}

class GenderSelectionState extends State<GenderSelection>{
  DataHandler dataHandler;
  Function updateData;
  var rng = new math.Random();

  GenderSelectionState({@required this.dataHandler, @required this.updateData});

  void changeGender(String _gender){
    dataHandler.hero.geschlecht = _gender;
    updateData(newData: dataHandler);
  }

  Widget _genderButton(String _gender) {
    return GestureDetector(
        onTap: () => changeGender(_gender),
        child: Container(
          height: 60,
          width: 60,
          decoration: dataHandler.hero.geschlecht==_gender
              ?BoxDecoration(color: _gender=='m'?Colors.deepPurpleAccent:Colors.green,
              borderRadius: BorderRadius.circular(40)):BoxDecoration(),
          padding: EdgeInsets.all(5),
          child: Image.asset('assets/images/user_images/gender_selection/'
              '${_gender=='m'?'boy':'girl'}-${rng.nextInt(12)}.png'),
        )
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _genderButton('m'),
              SizedBox(width: 20),
              _genderButton('w')
            ]
        )
    );
  }
}
