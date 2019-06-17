import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/menuBottomSheet.dart';
import 'package:hundetage/screens/login.dart';
import 'package:hundetage/utilities/styles.dart';
import 'dart:math' as math;

//User settings main class
class UserPage extends StatefulWidget {
  final DataHandler dataHandler;

  const UserPage({@required this.dataHandler});

  @override
  UserPageState createState() => new UserPageState(
      dataHandler: dataHandler);
}

class UserPageState extends State<UserPage> with SingleTickerProviderStateMixin{
  DataHandler dataHandler;
  double get getHeight => MediaQuery.of(context).size.height;
  double get getWidth => MediaQuery.of(context).size.width;

  UserPageState({@required this.dataHandler});

  //Update user page and hand change to hero to main function
  void updateData({DataHandler newData}){
    setState(() => dataHandler.updateData = newData);
  }

  @override
  Widget build(BuildContext context) {
    //Dialog for entering user name
    Dialog userNameDialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), //this right here
      child: Container(
        height: 200.0,
        width: 140.0,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding:  EdgeInsets.only(top: 15.0),
              child: Text('Gib einen Namen ein',
                  style: titleBlackStyle),
            ),
            Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: UserNameField(dataHandler: dataHandler, updateData: updateData),
            ),
          ],
        ),
      ),
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            resizeToAvoidBottomPadding: false,
            body: Stack(children: <Widget>[
              SafeArea(
                child: Stack(children: <Widget>[
                  Background(getHeight: getHeight, getWidth: getWidth),
                  new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                      SizedBox(height: 10),
                        Header(dataHandler: dataHandler, getWidth: getWidth,
                            userNameDialog: userNameDialog),
                        SizedBox(height: 30),
                        HeldAuswahl(dataHandler: dataHandler, getHeight: getHeight,
                            getWidth: getWidth, updateData: updateData),
                        SizedBox(height: minHeightBottomSheet)
                    ]
                  )
                ])
              ),
              MenuBottomSheet(getHeight: getHeight, dataHandler: dataHandler,
                  getWidth: getWidth, icon: 'assets/images/house.png',
                  homeButtonFunction: () => Navigator.pop(context))
            ])
        )
    );
  }

}

class Header extends StatelessWidget {
  final DataHandler dataHandler;
  final double getWidth;
  final Dialog userNameDialog;

  Header({@required this.dataHandler, @required this.getWidth, @required this.userNameDialog});

  _gotoLoginScreen({BuildContext context, DataHandler dataHandler}){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginSignUpPage(
            dataHandler: dataHandler))
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (BuildContext context) => userNameDialog),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => _gotoLoginScreen(context: context, dataHandler: dataHandler),
                child: Container(
                    height: 75.0,
                    width: 75.0,
                    child:Image.asset(dataHandler.hero.signedIn
                        ?'assets/images/cloud.png'
                        :'assets/images/world.png')
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: GestureDetector(
                  onTap: () => showDialog(context: context, builder: (BuildContext context) => userNameDialog),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Erstelle ' + (dataHandler.hero.geschlecht=='m'
                              ?'deinen Helden!'
                              :'deine Heldin!'),
                          style: titleStyle,
                        ),
                        new Text(
                            'Ändere ' + (dataHandler.hero.geschlecht=='m'
                                ?'seinen'
                                :'ihren') + ' Namen hier',
                            style: subTitleStyle)
                        ,
                        new Text(
                            'Oder log dich über das Bild ein',
                            style: subTitleStyle)
                      ]
                  ),
                ),
              ),
            ]
        ),
      ),
    );
  }
}

class HeldAuswahl extends StatefulWidget{
  final DataHandler dataHandler;
  final Function updateData;
  final double getHeight, getWidth;

  HeldAuswahl({@required this.dataHandler, @required this.getHeight,
    @required this.updateData, @required this.getWidth});

  @override
  HeldAuswahlState createState() => new HeldAuswahlState(dataHandler: dataHandler,
  getHeight: getHeight, getWidth: getWidth, updateData: updateData);
}

class HeldAuswahlState extends State<HeldAuswahl> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  double _rotAngle = 2*math.pi;
  int duration = 500;
  int iconIndex = 0;
  DataHandler dataHandler;
  Function updateData;
  double getHeight, getWidth;
  double pageOffset = 0.0;
  PageController pageController;
  var rng = new math.Random();

  HeldAuswahlState({@required this.dataHandler, @required this.getHeight,
    @required this.getWidth, @required this.updateData});

  @override
  void initState() {
    super.initState();
    _animationController = new AnimationController(
        vsync: this,
        lowerBound: 0.0,
        upperBound: _rotAngle);
    pageController = PageController(viewportFraction: 0.75,
        //Set initial image to zero if we have a new user
        initialPage: dataHandler.hero.iBild==-1?0:dataHandler.hero.iBild);
    //When we get to the page we need to set the offset so we center the images
    pageOffset = (dataHandler.hero.iBild==-1?0:dataHandler.hero.iBild).toDouble();
    //We need this to actually re-draw the page view when the page is changed
    //We need that for the paralax effect
    pageController.addListener(() {
      setState(() => pageOffset = pageController.page); //<-- add listener and set state
    });
  }

  void changeGender(String geschlecht) {
    //setState(() => null);
    dataHandler.hero.geschlecht = geschlecht;
    //Actually animate the selection - direction depends on the selected sex
    _animationController.animateTo(_animationController.value==_rotAngle?0.0:_rotAngle,
      duration: Duration(milliseconds: duration),
    );
    //Make sure to tell the parent widgets about the new sex
    updateData(newData: dataHandler);
  }

  //Kill the animation controller when we no longer need it
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Dialog userNameDialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), //this right here
      child: Container(
        height: 200.0,
        width: 140.0,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding:  EdgeInsets.only(top: 15.0),
              child: Text('Gib einen Namen ein',
                  style: titleBlackStyle),
            ),
            Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: UserNameField(dataHandler: dataHandler, updateData: updateData),
            ),
          ],
        ),
      ),
    );

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
              onTap: () => showDialog(context: context, builder: (BuildContext context) => userNameDialog),
              child: Container(height: getHeight - 290.0,
                  child: _buildTiledSelection(context: context,
                      imageList: Iterable.generate(dataHandler.hero.maxImages).toList()
                  )
              )
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    height: 80.0,
                    width: 80.0,
                    child: RotatedGenderIcon(
                        changeGender: changeGender, animationController: _animationController,
                        //Show the sex not currently selected
                        geschlecht: dataHandler.hero.geschlecht == 'm'?'w':'m',
                        duration: duration, iconIndex: iconIndex)
                    )
              ]
          )
        ]
    );
  }

  //Builds the tiled list for adventure selection
  Widget _buildTiledSelection({BuildContext context, List<dynamic> imageList}) {
    return PageView(
      controller: pageController,
      onPageChanged: (pageIndex) {
        //We get a new number here to show the user we have more than one icon
        iconIndex = rng.nextInt(3);
        dataHandler.hero.iBild = pageIndex;
        updateData(newData: dataHandler);
      },
      children: imageList.map((iBild) =>
          _buildCard(context: context, iBild: iBild)).toList(),
    );
  }

  Widget _buildCard({BuildContext context, int iBild}) {
    double _imageHeight = getHeight - 400.0;
    return new Card(
        margin: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        child: Column(
            children: <Widget>[
              ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  child:Image.asset('assets/images/user_images/hund_$iBild.jpg',
                    scale: 800 / _imageHeight * 0.8,
                    height: _imageHeight,
                    fit: BoxFit.none,
                    alignment: Alignment(-(pageOffset.abs() - iBild.toDouble()), 0), )),
              SizedBox(height: 8),
              Text(
                dataHandler.hero.iBild != -1
                    ? dataHandler.hero.name
                    : '',
                style: titleBlackStyle,
              ),
              SizedBox(height: 8),
              dataHandler.hero.iBild != -1
                  ? new Text(
                  dataHandler.hero.berufe[dataHandler.hero.iBild][dataHandler
                      .hero.geschlecht],
                  style: subTitleBlackStyle)
                  : Container(),
            ]
        )
    );
  }
}

class RotatedGenderIcon extends AnimatedWidget {
  final String geschlecht;
  final Function changeGender;
  final int duration, iconIndex;
  final Listenable animationController;

  RotatedGenderIcon({@required this.geschlecht, @required this.iconIndex,
    @required this.animationController, @required this.changeGender,
    @required this.duration}):super(listenable: animationController);

  Widget _rotatingIcon(double _angle){
    return Transform.rotate(
      //This makes sure we turn the selection properly
        angle: _angle,
        child: GestureDetector(
            onTap: () => changeGender(geschlecht),
            child: Image.asset('assets/images/${geschlecht=='m'?'girl':'boy'}_$iconIndex.png'),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    Animation animation = animationController;
    return AnimatedCrossFade(
        duration: Duration(milliseconds: duration),
        crossFadeState: animation.value == 0.0
            ?CrossFadeState.showFirst
            :CrossFadeState.showSecond,
        firstChild: _rotatingIcon(animation.value),
        secondChild: _rotatingIcon(animation.value)
    );
  }
}

class RotatedIcon extends AnimatedWidget {
  final String geschlecht;
  final double height, rotAngle;
  final Function changeGender;
  final Listenable listenable;
  final Held hero;
  //Even though they have the same size - male symbol looks larger
  //This scaling fixes that
  final Map<String,double> _iconSize = {'m': 40,'w':50};


  RotatedIcon({@required this.geschlecht, @required this.height,
    @required this.listenable, @required this.rotAngle, @required this.changeGender,
    @required this.hero}):super(listenable: listenable);

  @override
  Widget build(BuildContext context) {
    Animation animation = listenable;
    return Transform.rotate(
      //This makes sure we turn the selection properly
        angle: animation.value + (geschlecht == 'w' ? 0.0 : rotAngle),
        child: Transform.translate(
            offset: Offset(0.0, -height / 3),
            child: Transform.rotate(
                angle: -(animation.value + (geschlecht == 'w' ? 0.0 : rotAngle)),
                child: IconButton(
                iconSize: _iconSize[geschlecht],
                onPressed: () => changeGender(geschlecht),
                //Choses the right icon based on which gender is currently selected
                  icon: Image.asset('assets/images/symbol_$geschlecht${hero.geschlecht==geschlecht?'':'_b'}.png'),
            )
            )
        )
    );
  }
}

class UserNameField extends StatefulWidget{
  final DataHandler dataHandler;
  final Function updateData;

  UserNameField({@required this.dataHandler, @required this.updateData});

  @override
  UserNameFieldState createState() =>
      new UserNameFieldState(dataHandler: dataHandler, updateData: updateData);
}

class UserNameFieldState extends State<UserNameField>{
  DataHandler dataHandler;
  Function updateData;
  TextEditingController _controller;

  UserNameFieldState({@required this.dataHandler, @required this.updateData});

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: dataHandler.hero.name);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
          width: 200.0,
          child: TextField(
        //This should make it more comfortable to write names
          textCapitalization: TextCapitalization.words,
          decoration: new InputDecoration(
              labelText: 'Name',
          ),
          maxLength: 15,
          style: textStyle,
          maxLengthEnforced: true,
          controller: _controller,
          onChanged: (name){
            dataHandler.hero.name = name;
            updateData(newData: dataHandler);},
        )
    ));
  }
}