import 'package:flutter/material.dart';
import 'package:hundetage/utilities/styles.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hundetage/utilities/dataHandling.dart';

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
  bool waitingForUsername, waitingForHeroName;
  TextEditingController _textController;
  List<Widget> _messages = new List<Widget>();
  ScrollController _listScrollController;
  var rng = new math.Random();

  UserChatState({@required this.dataHandler});

  @override
  void initState() {
    super.initState();
    waitingForUsername = false;
    waitingForHeroName = false;
    _textController = new TextEditingController();
    _listScrollController = new ScrollController();
    SchedulerBinding.instance.addPostFrameCallback((_)=>_performQandA());
  }

  void _boyGirl(){
    setState(() => _messages.add(_boyGirlSelection()));
  }

  Future _postImage() async {
    var _image = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      dataHandler.hero.userImage = Image.file(_image, fit: BoxFit.cover);
      _messages.add(_newImage(dataHandler.hero.userImage, 'user'));
    });
  }

  void _sendMessage(String text){
    setState((){
      dataHandler.hero.userName = text;
      _messages.add(_newItem(text, 'user'));
      if (text.trim() != '') {
        _textController.clear();
      }
    });
  }

  Future<void> _postMessages(int start, int stop) async{
    Map<int, Map<String, String>> qAndAOutputs = {
      0: {'text': 'Hallo liebe Leser - willkommen bei Hundetage!', 'user': 'Lukas'},
      1: {'text': 'Bevor wir unser Abenteuer beginnen, wollten wir uns kurz vorstellen und'
          'euch - unsere Leser - ein bisschen besser kennenlernen 😊', 'user': 'Lukas'},
      2: {'text': 'Wir, das sind ich, Lukas und mein Bruder Jakob', 'user': 'Lukas'},
      4: {'text': 'Wir haben zusammen an Hundetage gearbeitet: Ich habe die Geschichte '
          'geschrieben und die Hundetage App programmiert, und Jakob hat all die tollen '
          'Bilder gemahlt, die du in dieser Geschichte findest.', 'user': 'Lukas'},
      5: {'text': 'Noch dazu ist Jakob ein waschechter Anwalt. Sollten unsere Freunde '
          'auf ihren Abenteuern also in Schwierigkeiten geraten, wissen sie an wen '
          'sie sich wenden müssen 😉', 'user': 'Lukas'},
      6: {'text': 'Aber genug von uns - wir würden gerne auch mehr über dich erfahren: '
          'Wie heißt du denn? 🙂', 'user': 'Lukas'},
      7: {'text': '${dataHandler.hero.userName} - das ist aber ein '
          '${{0: 'schöner', 1: 'cooler', 2: 'toller'}[rng.nextInt(3)]} Name!', 'user': 'Lukas'},
      8: {'text': 'Wie schön, dass du heute bei uns bist! 🥰', 'user': 'Lukas'},
      9: {'text': 'Um dieses Buch für dich ganz persöhnlich zu gestalten, kannst du jetzt '
          'noch ein cooles Bild hochladen. Das kann ein Bild von dir sein, oder '
          'von einem Spielzeug das du besonders gerne magst.', 'user': 'Lukas'},
      10: {'text': 'Das Bild ist nur für dich alleine da. Wir werden es mit niemanden sonst teilen'
          'und sehen es auch selbst nicht.', 'user': 'Lukas'},
      11: {'text': 'Colles Bild 👍👍', 'user': 'Lukas'},
      12: {'text': 'Jetzt wird es auch langsam Zeit, für die Geschichte selbst - viel Spaß also'
          'bei Hundetage - wir hoffen das Abenteuer unserer Freunde gefällt dir! 😊', 'user': 'Lukas'},
      13: {'text': 'Ohnn nein... verflixt... *Blätterrascheln* "Jakob? 😲"', 'user': 'Lukas'},
      14: {'text': 'Jakob: "Ja Lukas? Was ist los? Ich dachte, wir wollten mit der Geschichte anfangen? '
          'Ich hab schon alles vorbereitet. Du wolltest doch unsere Leser nur noch nach ihrem Namen'
          'und einem Bild fragen.', 'user': 'Jakob'},
      15: {'text': 'Lukas: "Hab ich gemacht"', 'user': 'Lukas'},
      16: {'text': 'Jakob: "Und was ist dann das Problem? Wir sollten echt langsam anfangen mit der Geschichte -'
          'die Leute sind schon ganz neugierig!"', 'user': 'Jakob'},
      17: {'text': '🙄', 'user': 'Lukas'},
      18: {'text': 'LUKAS? Was ist hast du diesmal verlohren? 😒', 'user': 'Jakob'},
      19: {'text': 'Ich... naja... ich hab nicht so sehr was verlohren, '
          'als dass ich was vergessen habe', 'user': 'Lukas'},
      20: {'text': 'Was hast du vergessen? 🤨', 'user': 'Jakob'},
      21: {'text': 'Naja... ich hab vergessen, wie unsere Heldin überhaubt heißt. Wenn ich ehrlich bin,'
          'bin ich mir auch gar nicht mehr so sicher, ob sie überhaubt ein Mädchen war, '
          'oder nicht doch ein Junge...🤔', 'user': 'Lukas'},
      22: {'text': '😑', 'user': 'Jakob'},
      23: {'text': 'Es tut mir wirklich Leid! 😣', 'user': 'Lukas'},
      24: {'text': 'Schon gut... Aber jetzt müssen wir uns echt was einfallen lassen... '
          'Wer könnte uns nur weiterhelfen? 🤔', 'user': 'Jakob'},
      25: {'text': 'Wie wäre es mit den Lesern? 🙂', 'user': 'Lukas'},
      26: {'text': 'Die Leser? Du willst die Leser fragen von wem unsere '
          'Geschichte handelt? 🤨', 'user': 'Jakob'},
      27: {'text': 'Also wenn du mich fragst, dann sehen die ziemlich klug aus - '
          'die können uns bestimmt weiterhelfen! 🧐', 'user': 'Lukas'},
      28: {'text': 'Wenn du meinst... Aber dann frag diesmal ich sie - '
          'nicht, dass du es wieder vergisst.', 'user': 'Jakob'},
      29: {'text': '*Räuspern* Also, *Blätterraschel* ${dataHandler.hero.userName}... '
          'Wie du vielleicht mitbekommen hast, hatten wir hier'
          'bei Hundetage einen keinen... Unfall. Kurz gesagt: wir bräuchten deine Hilfe - sonst'
          'müssen wir unsere Geschichte absagen, noch bevor sie richtig begonnen hat....','user': 'Jakob'},
      29: {'text': 'Also, ${dataHandler.hero.userName}, erste Frage: '
          'ist der Hund von dem dieses Buch handelt ein Junge oder ein Mädchen?','user': 'Jakob'},
      31: {'text': 'Aber natürlich - ${dataHandler.hero.geschlecht=='w'?'Mädchen':'Junge'} '
          'wie konnten wir das nur vergessen 🙈','user': 'Jakob'},
      32: {'text': 'Großartig - das klappt echt besser als gedacht. Nächste Frage: '
          'Weißt du denn auch den Namen '
          '${dataHandler.hero.geschlecht=='w'?'unserer Heldin':'unseres Helden'}?','user': 'Jakob'},
      33: {'text': 'Aber klar: ${dataHandler.hero.name} - das ist auch wirklich ein toller Name!','user': 'Jakob'},
      34: {'text': 'So... *Blätterraschel* ich glaube damit haben wir auch alles - Lukas?','user': 'Jakob'},
      35: {'text': 'Jop - das sollte Alles sein - nochmal Enschuldigung, dass ich die '
          'Blätter verschlampt habe 😶','user': 'Lukas'},
      36: {'text': 'Ach - kein Problem. Zum Glück war ja ${dataHandler.hero.userName} zur '
          'Stelle um uns zu helfen. 😃','user': 'Jakob'},
      37: {'text': 'Uns bleibt jetzt nur noch dir viel Spaß mit der Geschichte zu wünschen. '
          'Lukas und ich hoffen du hast viel Spaß mit den Abenteuern, die du zusammen '
          'mit ${dataHandler.hero.name} erleben wirst. 🐶','user': 'Jakob'},
      38: {'text': 'Tschüss 👋👋','user': 'Lukas'},
    };

    for(int i=start;i<stop;i++) {
      String _text = qAndAOutputs[i]['text'];
      String _user = qAndAOutputs[i]['user'];
      setState(() => _messages.add(_newItem(_text, _user)));
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<void> _performQandA() async{
    await _postMessages(0,3);
    setState(() => _messages.add(_newImage(
        Image.asset('assets/images/jakob_lukas.png', fit: BoxFit.cover), 'Lukas')));
    await Future.delayed(Duration(seconds: 1));

    await _postMessages(4,7);
  }

  Widget _boyGirlSelection(){
    return Container(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                  onTap: () => setState(() {
                    dataHandler.hero.geschlecht = 'm';
                  }),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15,10,15,10),
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(40)
                    ),
                    child: Text('Junge', style: chatStyle),
              )),
              SizedBox(width: 20),
              GestureDetector(
                  onTap: () => setState(() {
                    dataHandler.hero.geschlecht = 'w';
                  }),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15,10,15,10),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(40)
                    ),
                    child: Text('Mädchen', style: chatStyle),
                  ))
            ]
        )
    );
  }

  Widget _newImage(Image _image, String user){
    return Container(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
            mainAxisAlignment: user=='user'?MainAxisAlignment.end:MainAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 150,
                width: 150,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: user=='user'?orange:user=='Lukas'?red:yellow,
                    borderRadius: BorderRadius.circular(40)
                ),
                child: ClipRRect(
                    borderRadius: new BorderRadius.circular(40.0),
                    child: _image),
              )
            ]
        )
    );
  }

  Widget _newItem(String text, String user){
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: user=='user'?MainAxisAlignment.end:MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 250,
            padding: EdgeInsets.fromLTRB(15,10,15,10),
            decoration: BoxDecoration(
                color: user=='user'?orange:user=='Lukas'?red:yellow,
                borderRadius: BorderRadius.circular(40)
            ),
            child: Text(text, style: chatStyle, softWrap: true,),
          )
        ]
      )
    );
  }

  Widget _buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.photo_camera),
                onPressed: () => _postImage(),
                color: orange,
              ),
            ),
            color: Colors.white,
          ),
          Flexible(
            child: Container(
              child: TextField(
                style: textStyle,
                controller: _textController,
              ),
            ),
          ),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => _sendMessage(_textController.text),
                color: orange,
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