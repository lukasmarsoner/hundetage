import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';
import 'dart:math' as math;

//User settings main class
class UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback;
  final Substitution substitution;

  const UserPage({@required this.substitution, @required this.hero,
    @required this.heroCallback});

  @override
  UserPageState createState() => new UserPageState(
      hero: hero,
      substitution: substitution,
      heroCallback: heroCallback);
}

class UserPageState extends State<UserPage> with SingleTickerProviderStateMixin{
  Held hero;
  Function heroCallback;
  Substitution substitution;
  List pageKeys;
  GlobalKey userKey;
  double screenHeight, screenWidth;

  UserPageState({@required this.hero, @required this.substitution,
    @required this.heroCallback});

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth  = MediaQuery.of(context).size.width;
    //When we hit the back button we want to either go back to the main screen
    //or the previous one - depending on if the page view is visible or not
    return MaterialApp(home:
        Scaffold(
        //Avoid shifting the text field over other things in the stack when it has focus
        resizeToAvoidBottomPadding: false,
      //Add new screen elements here
        body: new Container(
            height: screenHeight,
            width: screenWidth,
            child: new Column(
              //make sure to build the Image selection (Page View) on top of everything else
                children: <Widget>[
                  //User image - wrapped to allow for hero transition from main page
                  Container(
                      width: screenWidth,
                      height: screenHeight/2.3,
                      child: UserImageRow(hero: hero,heroCallback: heroCallback)),
                  //Username
                  Container(
                      padding: EdgeInsets.only(top: 10.0),
                      width: screenWidth/2,
                      child: UserNameField(hero:hero, heroCallback: heroCallback)),
                  //User gender
                  Container(
                    padding: EdgeInsets.only(top: screenHeight/10),
                    child:GenderSelector(hero: hero, heroCallback: heroCallback),
                  ),
            ]
         )
        )
      )
    );
  }

}

//All the user image stuff goes here
class UserImageRow extends StatefulWidget{
  final Held hero;
  final Function heroCallback;

  UserImageRow({@required this.hero, @required this.heroCallback});

  @override
  UserImageRowState createState() => new UserImageRowState(hero: hero, heroCallback: heroCallback);
}

class UserImageRowState extends State<UserImageRow> {
  Held hero;
  Function heroCallback;

  UserImageRowState({@required this.hero, @required this.heroCallback});

  updateHero({Held newHero}){
    setState(() {
      hero = newHero;
      heroCallback(newHero: hero);
    });
  }

  @override
  Widget build(BuildContext context) {
    double _screenWidth  = MediaQuery.of(context).size.width;
    //Handler for paging through the user images
    _clickHandler(bool left) {
      if (left) {
        (hero.iBild == 0) ? hero.iBild = hero.maxImages : hero.iBild -= 1;
        updateHero(newHero: hero);
      }
      else {
        (hero.iBild == hero.maxImages) ? hero.iBild = 0 : hero.iBild += 1;
        updateHero(newHero: hero);
      }
    }

    double _circleSize = _screenWidth / 3;
    double _arrowSize = _screenWidth / 10;
    double _selectionSize = _circleSize * 2 + _arrowSize * 3;
    double _leftPadding = (_screenWidth - _selectionSize) / 2;

    Widget _rightButton = new IconButton(
        iconSize: _arrowSize,
        icon: Opacity(opacity: 0.4, child: new Icon(Icons.arrow_forward_ios)),
        onPressed: () => _clickHandler(false));
    Widget _leftButton = new IconButton(
        iconSize: _arrowSize,
        icon: Opacity(opacity: 0.4, child: new Icon(Icons.arrow_back_ios)),
        onPressed: () => _clickHandler(true));

    return Container(
        padding: EdgeInsets.only(left: _leftPadding),
        width: _selectionSize,
        child: Row(children: <Widget>[
          _leftButton,
          GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                double dx = details.velocity.pixelsPerSecond.dx;
                if (dx > 0.0 && dx > 10.0) {
                  _clickHandler(true);
                }
                else if (dx < 0.0 && dx.abs() > 10.0) {
                  _clickHandler(false);
                }
              },
              child: new Hero(
                  tag: 'userImage',
                  child: new Material(
                      color: Colors.transparent,
                      child: InkWell(
                          child: CircleAvatar(
                              minRadius: _circleSize,
                              maxRadius: _circleSize,
                              backgroundColor: hero.geschlecht == 'm' ?Colors.blueAccent:Colors.redAccent,
                              child: Center(child: new CircleAvatar(
                                  minRadius: _circleSize * 0.95,
                                  maxRadius: _circleSize * 0.95,
                                  backgroundImage: new AssetImage(
                                      hero.iBild!=-1?'images/user_images/hund_${hero.iBild}.jpg'
                                          :'images/user_images/fragezeichen.jpg')
                              )
                              )
                          )
                      )
                  )
              )
          ),
          _rightButton
        ]
      )
    );
  }
}

class GenderSelector extends StatefulWidget {
  final Held hero;
  final Function heroCallback;

  GenderSelector({@required this.hero, @required this.heroCallback});

  @override
  GenderSelectorState createState() => new GenderSelectorState(hero: hero, heroCallback: heroCallback);
}

//We control the animation of the sex selection from here
class GenderSelectorState extends State<GenderSelector>
    with SingleTickerProviderStateMixin{
  AnimationController _animationController;
  Held hero;
  Function heroCallback;
  double _rotAngle = math.pi;

  GenderSelectorState({this.hero, this.heroCallback});

  //Here we mainly handle the animation
  @override
  void initState() {
    _animationController = new AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: _rotAngle,
      //Sets the selection in the right starting position
      value: hero.geschlecht=='w'?0.0:_rotAngle,
    );
    super.initState();
  }

  updateHero(Held newHero){
    setState(() {
      hero = newHero;
      heroCallback(newHero: hero);
    });
  }

  void changeGender(String geschlecht){
    //setState(() => null);
    hero.geschlecht = geschlecht;
    //Actually animate the selection - direction depends on the selected sex
    _animationController.animateTo(
      geschlecht=='w'?0.0:_rotAngle,
      duration: Duration(milliseconds: 500),
    );
    //Make sure to tell the parent widgets about the new sex
    updateHero(hero);
  }

  //Kill the animation controller when we no longer need it
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth  = MediaQuery.of(context).size.width;
    double circleWidth = screenWidth / 2.0;
    Widget maleIcon = RotatedIcon(geschlecht: 'm', height: circleWidth, hero: hero,
        listenable: _animationController, rotAngle: _rotAngle, changeGender: changeGender);
    Widget femaleIcon = RotatedIcon(geschlecht: 'w', height: circleWidth, hero: hero,
        listenable: _animationController, rotAngle: _rotAngle, changeGender: changeGender);
    return Container(
        width: circleWidth,
        height: circleWidth,
        child: Stack(
            children: [
              Container(
                  width: circleWidth,
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[BoxShadow(spreadRadius: 4)],
                      shape: BoxShape.circle,
                      color: hero.geschlecht=='m'?Colors.blueAccent:Colors.redAccent
                  )
              ),
              Center(child:maleIcon),
              Center(child:femaleIcon)
            ]
        )
    );
  }
}

class RotatedIcon extends AnimatedWidget
{
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
                icon: Image.asset('images/symbol_$geschlecht${hero.geschlecht==geschlecht?'':'_b'}.png'),
            )
            )
        )
    );
  }
}

class UserNameField extends StatefulWidget{
  final Held hero;
  final Function heroCallback;

  UserNameField({@required this.hero, @required this.heroCallback});

  @override
  UserNameFieldState createState() => new UserNameFieldState(hero: hero, heroCallback: heroCallback);
}

class UserNameFieldState extends State<UserNameField>{
  Held hero;
  Function heroCallback;
  TextEditingController _controller;

  UserNameFieldState({@required this.hero, @required this.heroCallback});

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: hero.name);
  }

  updateUser(String name){
    setState(() {
      hero.name = name;
    });
    heroCallback(newHero: hero);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      //This should make it more comfortable to write names
      textCapitalization: TextCapitalization.words,
      decoration: new InputDecoration(
          labelText: 'Name',
          enabledBorder: new OutlineInputBorder(
            borderSide: BorderSide(width: 3.0)
          )
      ),
      maxLength: 15,
      style: TextStyle(fontSize: 28.0,
          fontWeight: FontWeight.w500),
      maxLengthEnforced: true,
      controller: _controller,
      onChanged: (name) => updateUser(name),
    );
  }
}