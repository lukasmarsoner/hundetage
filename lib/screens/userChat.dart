import 'package:flutter/material.dart';
import 'package:hundetage/utilities/styles.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hundetage/utilities/json.dart';
import 'package:hundetage/screens/adventures.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:path_provider/path_provider.dart';

//User settings main class
class UserChat extends StatefulWidget {
  final DataHandler dataHandler;

  const UserChat({@required this.dataHandler});

  @override
  UserChatState createState() => new UserChatState(
      dataHandler: dataHandler);
}

class UserChatState extends State<UserChat> with SingleTickerProviderStateMixin{
  DataHandler dataHandler;
  int boyGirlIcon;
  bool _chatRunning, _defaultImage=false;
  List<bool> _qAndAsDone;
  TextEditingController _textController;
  List<Widget> _messages = new List<Widget>();
  ScrollController _listScrollController;
  var rng = new math.Random();
  double get getWidth => MediaQuery.of(context).size.width;

  UserChatState({@required this.dataHandler});

  @override
  void initState() {
    super.initState();
    //Makes sure users don't re-start automated chats
    _chatRunning = true;
    //This checks if the set-up process has previously be interrupted
    if(dataHandler.hero.userImage!=null || dataHandler.hero.username==null
        || dataHandler.hero.name==null || dataHandler.hero.geschlecht==null) {
        dataHandler.hero = Held.initial();
      }
    //We use this so we don't repeat segments if the user sends us something
    //in-between questions
    _qAndAsDone = [false, false, false, false, false];
    _textController = new TextEditingController();
    _listScrollController = new ScrollController();
    boyGirlIcon = rng.nextInt(2);
    SchedulerBinding.instance.addPostFrameCallback((_)=>_performQandA());
  }

  void _postButton(Widget _button){
    setState(() => _messages.add(_button));
  }

  Future<void> _sendImage({bool defaultImage = false}) async {
    File imageFile;
    Directory directory = await getApplicationDocumentsDirectory();
    //We hand in an image if the user does not want to set one of their own
    if(defaultImage){
      imageFile = File(directory.path +'/assets/images/jakob.png');
      _defaultImage = true;
    }
    else {imageFile = await ImagePicker.pickImage(source: ImageSource.camera);}
    //Save image to file
    if (dataHandler.hero.userImage == null && !_chatRunning) {
      saveCameraImageToFile(image: imageFile, filename: 'user_image');
    }
    setState(() {
      if (dataHandler.hero.userImage == null && !_chatRunning) {
        dataHandler.hero.userImage = Image.file(imageFile, fit: BoxFit.cover);
      }
      _messages.add(_newImage(dataHandler.hero.userImage, 'user'));
    });
    if(!_chatRunning){await _performQandA();}
  }

//Updates the hero's gender from the user's selection
  Future<void> _setGender(String _geschlecht) async{
    setState(() => _messages.add(_newButtonResponse(_genderButton(_geschlecht))));
    if(dataHandler.hero.geschlecht==null) {
      dataHandler.hero.geschlecht = _geschlecht;
      dataHandler.updateHero();
    }
    if(!_chatRunning){await _performQandA();}
  }

  //Sends a message to the chat (used by automatic and user inputs)
  Future<void> _sendMessage(String text) async{
    text = text.trim();

    setState((){
      if(text.length != 0) {
        if (dataHandler.hero.username == null && !_chatRunning) {
          dataHandler.hero.username = text;
        }
        else if (dataHandler.hero.name == null && !_chatRunning) {
          dataHandler.hero.name = text;
        }
      }
      _messages.add(_newItem(text, 'user'));
      _textController.clear();
    });
    dataHandler.updateHero();
    if(!_chatRunning){await _performQandA();}
  }

  //Posts automated responses to the chat
  Future<void> _postMessages(int start, int stop) async{
    Map<int, Map<String, String>> qAndAOutputs = {
      0: {'text': 'Hallo liebe Leser - willkommen bei Hundetage!', 'user': 'Lukas'},
      1: {'text': 'Bevor wir unser Abenteuer beginnen, wollten wir uns kurz vorstellen und '
          'euch - unsere Leser - ein bisschen besser kennenlernen 😊', 'user': 'Lukas'},
      2: {'text': 'Wir, das sind ich, Lukas und mein Bruder Jakob', 'user': 'Lukas'},
      3: {'text': 'Wir haben zusammen an Hundetage gearbeitet: Ich habe die Geschichte '
          'geschrieben und die Hundetage App programmiert, und Jakob hat all die tollen '
          'Bilder gemahlt, die du in dieser Geschichte findest.', 'user': 'Lukas'},
      4: {'text': 'Noch dazu ist Jakob ein waschechter Anwalt. Sollten unsere Freunde '
          'auf ihren Abenteuern also in Schwierigkeiten geraten, wissen sie an wen '
          'sie sich wenden müssen 😉', 'user': 'Lukas'},
      5: {'text': 'Aber genug von uns - wir würden gerne auch mehr über dich erfahren: '
          'Wie heißt du denn? 🙂', 'user': 'Lukas'},
      6: {'text': '${dataHandler.hero.username} - das ist aber ein '
          '${{0: 'schöner', 1: 'cooler', 2: 'toller'}[rng.nextInt(3)]} Name!', 'user': 'Lukas'},
      7: {'text': 'Wie schön, dass du heute bei uns bist ${dataHandler.hero.username}! 😁', 'user': 'Lukas'},
      8: {'text': 'Um dieses Buch für dich ganz persöhnlich zu gestalten, kannst du jetzt '
          'noch ein cooles Bild hochladen. Das kann ein Bild von dir sein, oder '
          'von einem Spielzeug das du besonders gerne magst.', 'user': 'Lukas'},
      9: {'text': 'Das Bild ist nur für dich alleine da. Wir werden es mit niemanden sonst teilen '
          'und sehen es auch selbst nicht. Wenn du jetzt kein Bild einstellen möchtest, drück einfach '
          'auf den Knopf unten.', 'user': 'Lukas'},
      10: {'text': 'Colles Bild 👍👍', 'user': 'Lukas'},
      11: {'text': 'Jetzt wird es auch langsam Zeit, für die Geschichte selbst - viel Spaß also '
          'bei Hundetage - wir hoffen das Abenteuer unserer Freunde gefällt dir! 😊', 'user': 'Lukas'},
      12: {'text': 'Ohnn nein... verflixt... *Blätterrascheln* "Jakob? 😲"', 'user': 'Lukas'},
      13: {'text': 'Ja, Lukas? Was ist los? Ich dachte, wir wollten mit der Geschichte anfangen? '
          'Ich hab schon alles vorbereitet. Du wolltest doch unsere Leser nur noch nach ihrem Namen '
          'und einem Bild fragen.', 'user': 'Jakob'},
      14: {'text': 'Hab ich gemacht', 'user': 'Lukas'},
      15: {'text': 'Und was ist dann das Problem? Wir sollten echt langsam anfangen mit der Geschichte - '
          'die Leute sind schon ganz neugierig!', 'user': 'Jakob'},
      16: {'text': '🙄', 'user': 'Lukas'},
      17: {'text': 'LUKAS? Was ist hast du diesmal verlohren? 😒', 'user': 'Jakob'},
      18: {'text': 'Ich... naja... ich hab nicht so sehr was verlohren, '
          'als dass ich was vergessen habe', 'user': 'Lukas'},
      19: {'text': 'Was hast du vergessen? 🤨', 'user': 'Jakob'},
      20: {'text': 'Naja... ich hab vergessen, wie unsere Heldin überhaubt heißt. Wenn ich ehrlich bin, '
          'bin ich mir auch gar nicht mehr so sicher, ob sie überhaubt ein Mädchen war, '
          'oder nicht doch ein Junge...🤔', 'user': 'Lukas'},
      21: {'text': '😑', 'user': 'Jakob'},
      22: {'text': 'Es tut mir wirklich Leid! 😣', 'user': 'Lukas'},
      23: {'text': 'Schon gut... Aber jetzt müssen wir uns echt was einfallen lassen... '
          'Wer könnte uns nur weiterhelfen? 🤔', 'user': 'Jakob'},
      24: {'text': 'Wie wäre es mit ${dataHandler.hero.username}? 🙂', 'user': 'Lukas'},
      25: {'text': '${dataHandler.hero.username}? Du willst die Leser fragen von wem unsere '
          'Geschichte handelt? 🤨', 'user': 'Jakob'},
      26: {'text': 'Also wenn du mich fragst, dann sehen die ziemlich klug aus - '
          'die können uns bestimmt weiterhelfen! 🧐', 'user': 'Lukas'},
      27: {'text': 'Wenn du meinst... Aber dann frag diesmal ich sie - '
          'nicht, dass du es wieder vergisst.', 'user': 'Jakob'},
      28: {'text': '*Räuspern* Also, *Blätterraschel* ${dataHandler.hero.username}... '
          'Wie du vielleicht mitbekommen hast, hatten wir hier'
          'bei Hundetage einen keinen... Unfall 🙄 Kurz gesagt: wir bräuchten deine Hilfe - sonst '
          'müssen wir unsere Geschichte absagen, noch bevor sie richtig begonnen hat.... 😦','user': 'Jakob'},
      29: {'text': 'Also, ${dataHandler.hero.username}, erste Frage: '
          'ist der Hund von dem dieses Buch handelt ein Junge oder ein Mädchen?','user': 'Jakob'},
      30: {'text': 'Aber natürlich - ein ${dataHandler.hero.geschlecht=='w'?'Mädchen':'Junge'} '
          'wie konnten wir das nur vergessen 🙈','user': 'Jakob'},
      31: {'text': 'Großartig - das klappt echt besser als gedacht. Nächste Frage: '
          'Weißt du denn auch den Namen '
          '${dataHandler.hero.geschlecht=='w'?'unserer Heldin':'unseres Helden'}?','user': 'Jakob'},
      32: {'text': 'Aber klar: ${dataHandler.hero.name} - das ist auch wirklich ein toller Name! ❤💛🧡','user': 'Jakob'},
      33: {'text': 'So... *Blätterraschel* ich glaube damit haben wir auch alles - Lukas?','user': 'Jakob'},
      34: {'text': 'Jop - das sollte Alles sein - nochmal Enschuldigung, dass ich die '
          'Blätter verschlampt habe 😶','user': 'Lukas'},
      35: {'text': 'Ach - kein Problem. Zum Glück war ja ${dataHandler.hero.username} zur '
          'Stelle um uns zu helfen. 😃','user': 'Jakob'},
      36: {'text': 'Uns bleibt jetzt nur noch dir viel Spaß mit der Geschichte zu wünschen. '
          'Lukas und ich hoffen du hast viel Spaß mit den Abenteuern, die du zusammen '
          'mit ${dataHandler.hero.name} erleben wirst. 🐶','user': 'Jakob'},
      37: {'text': 'Tschüss 👋👋','user': 'Lukas'},
      99: {'text': 'Dann nehmen wir in der Zwischenzeit ein Bild von unserer neuen Programmiererin. '
          'Maya arbeitet zwar schon hart an der nächsten App, aber '
          'für ein Foto ist immer Zeit 😉','user': 'Lukas'},
    };

    for(int i=start;i<stop;i++) {
      String _text = qAndAOutputs[i]['text'];
      String _user = qAndAOutputs[i]['user'];
      setState(() => _messages.add(_newItem(_text, _user)));
      //Don't wait on the last response
      if(i<stop-1){await _sleep(text: _text);}
      //If we only have one response - we still wait
      if(stop-start == 1){await _sleep(text: _text);}
    }
  }

  //Waiting between automates messages - waiting-time depends on the message's length
  Future<void> _sleep({int seconds, String text}) async{
    //Average german reading-speed is 150 words / minutes
    //We add a random element to make things seem less robotic
    int milliseconds;
    int _readingSpeed = 150;
    if(text != null) {
      int _nWords = text.split(' ').length;
      milliseconds = (_nWords * 60 ~/ _readingSpeed) * 1000  + rng.nextInt(400);
    }
    else{
      milliseconds = seconds * 1000;
    }
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  //Move to the main screen
  Future<void> _gotoAdventureScreen() async{
    dataHandler.hero.analytics = new FirebaseAnalytics();
    dataHandler.updateHero();
    await _sleep(seconds: 1);
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GeschichteMainScreen(
            dataHandler: dataHandler))
    );
  }

  //Controlls all automated postings
  Future<void> _performQandA() async{
    if(dataHandler.hero.userImage==null && dataHandler.hero.username==null
        && dataHandler.hero.name==null && dataHandler.hero.geschlecht==null
        && !_qAndAsDone[0]){
      _chatRunning = true;
      await _postMessages(0,3);
      setState(() => _messages.add(_newImage(
          Image.asset('assets/images/jakob_lukas.png', fit: BoxFit.cover), 'Lukas')));
      await _sleep(seconds: 3);
      await _postMessages(3,6);
      _qAndAsDone[0] = true;
      _chatRunning = false;
    }
    else if(dataHandler.hero.userImage==null && dataHandler.hero.username!=null
        && dataHandler.hero.name==null && dataHandler.hero.geschlecht==null
        && !_qAndAsDone[1]){
      _chatRunning = true;
      await _sleep(seconds: 2);
      await _postMessages(6,10);
      _postButton(_keinBildButton());
      _qAndAsDone[1] = true;
      _chatRunning = false;
    }
    else if(dataHandler.hero.userImage!=null && dataHandler.hero.username!=null
        && dataHandler.hero.name==null && dataHandler.hero.geschlecht==null
        && !_qAndAsDone[2]){
      _chatRunning = true;
      await _sleep(seconds: 2);
      _defaultImage
          ?await _postMessages(99,100)
          :await _postMessages(10,11);
      await _postMessages(11,30);
      _postButton(_boyGirlSelection());
      _qAndAsDone[2] = true;
      _chatRunning = false;
    }
    else if(dataHandler.hero.userImage!=null && dataHandler.hero.username!=null
        && dataHandler.hero.name==null && dataHandler.hero.geschlecht!=null
        && !_qAndAsDone[3]){
      _chatRunning = true;
      await _sleep(seconds: 2);
      await _postMessages(30,32);
      _qAndAsDone[3] = true;
      _chatRunning = false;
    }
    else if(dataHandler.hero.userImage!=null && dataHandler.hero.username!=null
        && dataHandler.hero.name!=null && dataHandler.hero.geschlecht!=null
        && !_qAndAsDone[4]){
      _chatRunning = true;
      await _sleep(seconds: 2);
      await _postMessages(32,38);
      _qAndAsDone[4] = true;
      _postButton(_weiterButton());
      _chatRunning = false;
    }
  }

  //Button allowing user to opt-out of providing an image of themselves
  Widget _keinBildButton(){
    return GestureDetector(
      key: Key('Kein Bild'),
      onTap: () => _sendImage(defaultImage: true),child:
    Stack(children: <Widget>[
      Container(
          padding: EdgeInsets.fromLTRB(4,4,0,10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    constraints: BoxConstraints(maxWidth: getWidth - 10),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(40)),
                    child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Text('Jetzt kein Bild hinzufügen',
                            style: chatStyle, softWrap: true))
                )
              ]
          )
      ),
    ]
    )
    );
  }

  //Button to go to main screen
  Widget _weiterButton(){
    return GestureDetector(
        onTap: () => _gotoAdventureScreen(),child:
        Stack(children: <Widget>[
          Container(
              padding: EdgeInsets.fromLTRB(4,4,0,10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                        constraints: BoxConstraints(maxWidth: getWidth - 10),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(40)),
                        child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Text('Alles klar - lass uns loslegen! 🙂',
                                style: chatStyle, softWrap: true))
                    )
                  ]
              )
          ),
        ]
        )
    );
  }

  //Button for gender selection - icons are random
  Widget _genderButton(String _gender) {
    return GestureDetector(
        key: Key('Button_'+_gender),
        onTap: () => _setGender(_gender),
        child: Container(
          height: 100,
          width: 100,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _gender=='m'?Colors.green:Colors.orange,
              borderRadius: BorderRadius.circular(40)
          ),
          child: Image.asset('assets/images/user_images/gender_selection/'
              '${_gender=='m'?'boy':'girl'}-${rng.nextInt(12)}.png'),
        )
    );
  }

  //Button for each of the two geners
  Widget _boyGirlSelection(){
    return Container(
      key: Key('Boy-Girl Selection'),
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _genderButton('m'),
          SizedBox(width: 20),
          _genderButton('w')
        ]
      )
    );
  }

  //Adds the avatar of the person posting to the chat in a little bubble
  Widget _posterAvatar(String user){
    return Container(
        width: 43,
        height: 43,
        padding: EdgeInsets.all(2),
        alignment: user=='user'?Alignment.bottomRight:Alignment.bottomRight,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
        child: CircleAvatar(
            backgroundImage: user=='user'
                ?dataHandler.hero.userImage==null
                  ?new AssetImage('assets/images/user_images/gender_selection/'
                    '${boyGirlIcon==0?'boy':'girl'}-${rng.nextInt(12)}.png')
                  :dataHandler.hero.userImage.image
                :user=='Lukas'
                  ?new AssetImage('assets/images/lukas.png')
                  :new AssetImage('assets/images/jakob.png'))
    );
  }

  //Adds a new image to the chat
  Widget _newImage(Image _image, String user){
    return GestureDetector(
      key: Key('Poste Image'),
      onTap: () => showDialog(context: context, builder: (BuildContext context) => _showImage(_image)),
      child: Stack(children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(user=='user'?0:8,8,user=='user'?8:0,10),
          child: Row(
            mainAxisAlignment: user=='user'?MainAxisAlignment.end:MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 200,
                  height: 250,
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: user=='user'?Colors.orange:user=='Lukas'?red:blue,
                    borderRadius: BorderRadius.circular(40)
                  ),
                child: ClipRRect(
                  borderRadius: new BorderRadius.circular(40.0), child: _image),
                ),
              ]
          )
        ),
        Row(
          mainAxisAlignment: user=='user'?MainAxisAlignment.end:MainAxisAlignment.start,
          children: <Widget>[_posterAvatar(user)]),
      ])
    );
  }

  //Button-responses are things like the gender selection, opting-out of providing an image
  //or moving to the main screen
  Widget _newButtonResponse(Widget response){
    return Stack(children: <Widget>[
      Container(
          padding: EdgeInsets.fromLTRB(0,4,4,10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                    constraints: BoxConstraints(maxWidth: getWidth * 2/3),
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(40)),
                    child: Padding(
                        padding: EdgeInsets.all(5),
                        child: response)
                )
              ]
          )
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[_posterAvatar('user')]),
    ]
    );
  }

  //Ads any new text item to the chat
  Widget _newItem(String text, String user){
    return Stack(children: <Widget>[
      Container(
          key: Key('Poste Message'),
          padding: EdgeInsets.fromLTRB(user=='user'?0:4,4,user=='user'?4:0,10),
          child: Row(
              mainAxisAlignment: user=='user'?MainAxisAlignment.end:MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  constraints: BoxConstraints(maxWidth: getWidth * 2/3),
                    decoration: BoxDecoration(
                              color: user=='user'?Colors.orange:user=='Lukas'?red:blue,
                              borderRadius: BorderRadius.circular(40)),
                          child: Padding(
                              padding: user=='user'?EdgeInsets.fromLTRB(20,20,40,15):EdgeInsets.all(20),
                              child: Text((user=='user'?'':(' '*6)) + text,
                                  style: chatStyle, softWrap: true))
                          )
              ]
          )
      ),
      Row(
          mainAxisAlignment: user=='user'?MainAxisAlignment.end:MainAxisAlignment.start,
          children: <Widget>[_posterAvatar(user)]),
    ]
    );
  }

  //Input bar containing icons for the camera and sending messages
  Widget _buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                key: Key('Send Image'),
                icon: new Icon(Icons.camera, size: 35, color: Colors.orange),
                onPressed: () => _sendImage(),
                color: Colors.orange,
              ),
            ),
            color: Colors.white,
          ),
          SizedBox(width: 5),
          Flexible(
            child: Container(
              child: TextField(
                key: Key('Chat Text Field'),
                style: textStyle,
                controller: _textController,
              ),
            ),
          ),
          SizedBox(width: 5),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                key: Key('Send Message'),
                icon: new Icon(Icons.send, size: 35, color: Colors.orange,),
                onPressed: () => _sendMessage(_textController.text),
                color: Colors.orange,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(top:
          new BorderSide(color: Colors.blueGrey, width: 0.5)), color: Colors.white),
    );
  }

  //Pop-up for viewing chat-images in a dialog
  Dialog _showImage(Image _image) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Container(
          key: Key('Image Dialog'),
          height: 500.0,
          width: 250.0,
          child: Padding(
            padding: EdgeInsets.all(15.0),
            child: _image,
          ),
        )
    );
  }

  //Actually build the chat-window
  @override
  Widget build(BuildContext context) {
    return Scaffold(body:
      SafeArea(
        child:Stack(children: <Widget>[
          ListView.builder(
            padding: EdgeInsets.fromLTRB(10,0,10,55),
            itemBuilder: (context, index) => _messages[_messages.length - (index+1)],
            itemCount: _messages.length,
            reverse: true,
            controller: _listScrollController
          ),
          Positioned(
            height: 50,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInput())
            ])
    ));
  }

}