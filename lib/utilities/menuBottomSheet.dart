import 'dart:math' as math;
import 'dart:ui';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:hundetage/utilities/styles.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hundetage/utilities/json.dart';
import 'package:image_picker/image_picker.dart';

const double minHeightBottomSheet = 60;

//This is used if we are waiting for data to finish loading from Firebase
//While still in the main screen
class DummyMenuButtonSheet extends StatefulWidget {

  @override
  DummyMenuButtonSheetState createState() => DummyMenuButtonSheetState();
}

class DummyMenuButtonSheetState extends State<DummyMenuButtonSheet>{
  double get getWidth => MediaQuery.of(context).size.width;
  double get getHeight => MediaQuery.of(context).size.height;

  double get headerTopMargin => 8;

  Widget build(BuildContext context) {

    return new Positioned(
        height: minHeightBottomSheet,
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xDC00688B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: headerTopMargin),
                    child: Row(children: <Widget>[
                    Icon(Icons.face, color: Colors.white,
                        key: Key('Inactive User Button'), size: 35,
                      ),
                      SheetHeader(fontStyle: subTitleStyle),
                      Spacer(),
                      Icon(Icons.mail, color: Colors.white, size: 35, key: Key('Inactive Mail Button'))
                    ])
                )
              ],
            ),
        ),
    );
  }

}

//Main Class for the menu shown during adventures
class MenuBottomSheet extends StatefulWidget {
  final DataHandler dataHandler;

  MenuBottomSheet({@required this.dataHandler});

  @override
  MenuBottomSheetState createState() => MenuBottomSheetState(
  dataHandler: dataHandler);
}

class MenuBottomSheetState extends State<MenuBottomSheet>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  double get getWidth => MediaQuery.of(context).size.width;
  double get getHeight => MediaQuery.of(context).size.height;
  DataHandler dataHandler;

  MenuBottomSheetState({@required this.dataHandler});

  //Controls the hight of the sheet during animation
  double get headerTopMargin =>
      lerp(8, 8 + MediaQuery.of(context).padding.top);

  //Text for Menu-title
  TextStyle get headerTextStyle => TextStyleTween(begin: subTitleStyle, end: titleStyle).animate(_controller).value;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //Scnas through the menu-height
  double lerp(double min, double max) =>
      lerpDouble(min, max, _controller.value);

  @override
  Widget build(BuildContext context) {

    //This is the dialog for the mail contact
    Dialog senderDialog = new Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Container(padding: EdgeInsets.all(15),
            child: MailDialog(dataHandler: dataHandler)
        )
    );

    return new AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Positioned(
            height: lerp(minHeightBottomSheet, getHeight-30),
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              key: Key('Erlebnisse Menu'),
              onTap: _toggle,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
          child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xDC00688B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: <Widget>[
                    _buildErlebnisseList(),
                    Padding(padding: EdgeInsets.only(top: headerTopMargin),
                        child: Row(children: <Widget>[
                          //User settings
                          UserButton(dataHandler: dataHandler),
                          SheetHeader(fontStyle: subTitleStyle),
                          Spacer(),
                          //Mail-contact form
                          IconButton(icon: Icon(Icons.mail, color: Colors.white,),
                            key: Key('Active Mail Button'), iconSize: 35, 
                              onPressed: () => showDialog(context: context,
                              builder: (BuildContext context) => senderDialog))
                        ]
                        )
                    )
                  ],
              ),
            ),
          )
        );
      },
    );
  }

  //Events seen by the user are build into the menu-elements here
  Widget _buildErlebnisseList(){
    List<Widget> _erlebnisseList = new List<Widget>();

    for(String title in dataHandler.hero.erlebnisse.toSet()){
      _erlebnisseList.add(_buildItem(erlebniss: dataHandler.generalData.erlebnisse[title]));
    }

    //Events are displayed in a GridVire
    return Container(
        padding: EdgeInsets.only(top: 70.0),
        child:GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _erlebnisseList)
    );
  }

  //Every event has an animation associated with it, opening a dialog box
  Widget _buildItem({Erlebniss erlebniss}) {
    return ExpandedErlebniss(
        visibility: _controller.value,
            onTap: () => _openDialog(ShowErlebniss(erlebniss: erlebniss, dataHandler: dataHandler,
                getWidth: getWidth, getHeight: getHeight),
                context),
            erlebniss: erlebniss);
  }

  _openDialog(Widget _dialog, BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return _dialog;
        }
    );
  }

  //Stuff to control the animation of the sheet
  void _toggle() {
    final bool isOpen = _controller.status == AnimationStatus.completed;
    _controller.fling(velocity: isOpen ? -2 : 2);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value -= details.primaryDelta / getHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    //Fliging the sheet
    final double flingVelocity =
        details.velocity.pixelsPerSecond.dy / getHeight;
    if (flingVelocity < 0.0)
      _controller.fling(velocity: math.max(2.0, -flingVelocity));
    else if (flingVelocity > 0.0)
      _controller.fling(velocity: math.min(-2.0, -flingVelocity));
    else
      _controller.fling(velocity: _controller.value < 0.5 ? -2.0 : 2.0);
  }
}

//This controls the dialog for contact mails
class MailDialog extends StatefulWidget{
  final DataHandler dataHandler;

  MailDialog({@required this.dataHandler});

  @override
  MailDialogState createState() => new MailDialogState(dataHandler: dataHandler);
}

class MailDialogState extends State<MailDialog>{
  DataHandler dataHandler;
  MailSender mailSender;
  TextEditingController _controller;

  MailDialogState({@required this.dataHandler});

  @override
  void initState() {
    super.initState();
    mailSender = new MailSender(dataHandler: dataHandler);
  }

  void mailCallback(MailSender newSender){
    setState(()=> mailSender = newSender);
  }

  //Attachments can be added - they are shown as a small Image below the mail text
  //We only support one attachment at a time at this point
  Dialog attachmentDialog() {
    return Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Container(
            padding: EdgeInsets.all(10),
            height: 280,
            width: 180,
            child: Image.file(File(mailSender.attachmentPath))
        )
    );
  }

  //Image showing the attachement. If we have nothing, we add an empty container
  Widget attachment(double size){
    return mailSender.attachmentPath == null
        ?Container()
        :GestureDetector(
          onTap: ()  => showDialog(context: context,
        builder: (BuildContext context) => attachmentDialog()),
          child: Container(
              height: size,
              width: size,
              padding: EdgeInsets.all(size/50),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              child: CircleAvatar(backgroundImage: Image.file(File(mailSender.attachmentPath)).image))
    );
  }

  @override
  Widget build(BuildContext context) {
    //Check if opening the mail-client has worked or not
    AlertDialog _failure = new AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        title: Text('Ups... 😶', style: textStyle),
        content: Text('Da ist leider etwas schiefgelaufen 🙁', style: textStyle));

    AlertDialog _success = new AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        title: Text('Alles klar! 😄', style: textStyle),
        content: Text('Vielen Dank für deine Nachricht. '
            'Wir werden dir so schnell wie möglich antworten! 😊', style: textStyle));

    //Dialog containing the mail-text
    return Container(
      key: Key('Mail Dialog'),
      padding: EdgeInsets.all(10),
      height: 320,
      child: ListView(
        children: <Widget>[
          MailField(mailCallback: mailCallback, mailSender: mailSender),
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:<Widget>[
              //Butten opening an image-picker and adding the attachment
              IconButton(
                icon: Icon(Icons.camera, size: 35, color: Colors.orange),
                key: Key('Camera Icon'),
                onPressed: () async {
                  File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
                  setState(() => mailSender.attachmentPath = imageFile.path);
                },
              ),
              //Image of the attachment
              attachment(45),
              //Button opening the mail-dialog
              IconButton(
                icon: Icon(Icons.send, size: 35, color: Colors.orange), 
                  key: Key('Send Icon'),
                  onPressed: () async {
                    bool success = await mailSender.send();
                    success
                      ?showDialog(context: context, builder: (BuildContext context) => _success)
                      :showDialog(context: context, builder: (BuildContext context) => _failure);
                    },
              )
            ]
          )
        ]
      )
    );
  }
}

class MailField extends StatefulWidget{
  final MailSender mailSender;
  final Function mailCallback;

  MailField({@required this.mailSender, @required this.mailCallback});

  @override
  MailFieldState createState() => new MailFieldState(mailSender: mailSender,
      mailCallback: mailCallback);
}

class MailFieldState extends State<MailField>{
  MailSender mailSender;
  Function mailCallback;
  TextEditingController _controller;

  MailFieldState({@required this.mailSender, @required this.mailCallback});

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: mailSender.text);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            child: TextField(
              keyboardType: TextInputType.multiline,
              minLines: 8,
              maxLines: 120,
              //This should make it more comfortable to write names
              textCapitalization: TextCapitalization.words,
              decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.orange)),
                  labelText: 'Erzähl uns von dir 😄'),
              style: textStyle,
              controller: _controller,
              onChanged: (text) {mailSender.text=text;
              setState(() => mailCallback(mailSender));
              },
            )
        ));
  }
}

class ExpandedErlebniss extends StatelessWidget {
  final double visibility;
  final Function onTap;
  final Erlebniss erlebniss;

  const ExpandedErlebniss(
      {@required this.visibility,
        @required this.onTap,
        @required this.erlebniss});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: Key(erlebniss.title),
      opacity: visibility,
      duration: Duration(milliseconds: 600),
      child:GestureDetector(
        onTap: () => onTap(),
          child: ClipRRect(
            key: Key('Erlebniss Image'),
            borderRadius: BorderRadius.all(Radius.circular(30)),
            child: erlebniss.image),
      )
    );
  }
}

class ShowErlebniss extends StatelessWidget{
  final Erlebniss erlebniss;
  final DataHandler dataHandler;
  final double getWidth, getHeight;

  ShowErlebniss({@required this.erlebniss, @required this.dataHandler,
    @required this.getHeight, @required this.getWidth});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: 100, maxWidth: getWidth * 4/5,
              minWidth: 00, maxHeight: getHeight * 3/4),
            child: ListView(
                children: <Widget>[
                  Center(child: Container(
                      padding: EdgeInsets.fromLTRB(15,10,15,0),
                      child: Text(erlebniss.title, style: subTitleBlackStyle)
                  )),
                  SizedBox(height: 10,),
                  Container(
                      padding: EdgeInsets.only(left: 15, right: 15),
                      height: 220,
                      width: 220,
                      child: ClipRRect(
                          borderRadius: new BorderRadius.circular(30.0),
                          child: erlebniss.image)),
                  SizedBox(height: 10,),
                  Container(
                      padding: EdgeInsets.fromLTRB(15,10,15,10),
                      child: Text(dataHandler.substitution.applyAllSubstitutions(erlebniss.text),
                          style: textStyle))
                ]
            )
        )
    );
  }
}


class SheetHeader extends StatelessWidget {
  final TextStyle fontStyle;

  const SheetHeader({@required this.fontStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 15),
          child: Text(
            'Erlebnisse',
            style: fontStyle,
          ),
    );
  }
}

class UserButton extends StatelessWidget {
  final DataHandler dataHandler;

  UserButton({this.dataHandler});

  @override
  Widget build(BuildContext context) {
    Dialog userNameDialog  = new Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: NameDialog(dataHandler: dataHandler)
    );

    return IconButton(
      key: Key('User Button'),
      onPressed: () => showDialog(context: context, builder: (BuildContext context) => userNameDialog),
      iconSize: 35,
      icon: Icon(Icons.face, color: Colors.white)
    );
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

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.all(15),
      child: Container(
        key: Key('User Name Dialog'),
        height: 360,
        child: Column(
          children: <Widget>[
            Avatar(size: 100, dataHandler: dataHandler),
            NameField(setUsername: true, dataHandler: dataHandler),
            SizedBox(height: 20,),
            NameField(setUsername: false, dataHandler: dataHandler),
            SizedBox(height: 30,),
            GenderSelection(dataHandler: dataHandler, callback: () => setState((){})),
          ],
        ),
      ),
    );
  }
}

class NameField extends StatefulWidget{
  final DataHandler dataHandler;
  final bool setUsername;

  NameField({@required this.dataHandler, @required this.setUsername});

  @override
  NameFieldState createState() =>
      new NameFieldState(dataHandler: dataHandler, setUsername: setUsername);
}

class NameFieldState extends State<NameField>{
  DataHandler dataHandler;
  bool setUsername;
  TextEditingController _controller;

  NameFieldState({@required this.dataHandler, @required this.setUsername});

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
                setUsername?dataHandler.hero.username=name:dataHandler.hero.name=name;},
            )
        ));
  }
}

class Avatar extends StatefulWidget{
  final double size;
  final DataHandler dataHandler;

  Avatar({@required this.size, @required this.dataHandler});

  @override
  AvatarState createState() =>
      new AvatarState(dataHandler: dataHandler, size: size);
}

class AvatarState extends State<Avatar>{
  double size;
  DataHandler dataHandler;

  @override
  void initState() { 
    super.initState();
  }

  AvatarState({@required this.size, @required this.dataHandler});

  Future<void> _setImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    await saveCameraImageToFile(image: imageFile, filename: 'user_image');
    setState(() => dataHandler.hero.userImage = Image.file(imageFile, fit: BoxFit.cover));
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
  final VoidCallback callback;

  GenderSelection({@required this.dataHandler, @required this.callback});

  @override
  GenderSelectionState createState() =>
      new GenderSelectionState(dataHandler: dataHandler, callback: callback);
}

class GenderSelectionState extends State<GenderSelection>{
  DataHandler dataHandler;
  VoidCallback callback;
  var rng = new math.Random();

  @override
  void initState() { 
    super.initState();
  }

  GenderSelectionState({@required this.dataHandler, @required this.callback});

  void changeGender(String _gender){
    setState(() => dataHandler.hero.geschlecht = _gender);
    callback();
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