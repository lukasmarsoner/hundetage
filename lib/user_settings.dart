import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';
import 'dart:math' as math;

//User settings main class
class UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback, closeMenu;

  const UserPage({Key key, this.hero, this.heroCallback, this.closeMenu}) : super(key: key);

  @override
  UserPageState createState() => new UserPageState(
      hero: hero,
      heroCallback: heroCallback);
}

class UserPageState extends State<UserPage> with SingleTickerProviderStateMixin{
  Held hero;
  Function heroCallback;
  List pageKeys;
  GlobalKey userKey;
  double screenHeight, screenWidth;

  UserPageState({this.hero, this.heroCallback});

  //Update user page and hand change to hero to main function
  void updateHero({Held newHero}){
    setState(() {
      hero = newHero;
      heroCallback(newHero: hero);
    });
  }

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
        body: new Container(height: screenHeight,
                 child: new Stack(
                //make sure to build the Image selection (Page View) on top of everything else
                children: <Widget>[
              Center(child: Container(
                  //Padding set so as to not squeeze the circle at the bottom which
                  //it has a height of screenHeight/1.8
                  padding: EdgeInsets.only(top:(1-1/2.8)*screenHeight),
                  child:Center(child: GenderSelector(hero: hero, heroCallback: heroCallback)),
              )),
              _userImageRow(),
              Center(child: Container(
                  width: screenWidth/2,
                  child: UserNameField(hero:hero, heroCallback: updateHero))),
            ]
         )
        )
      )
    );
  }

  //All the user image stuff goes here
  Widget _userImageRow(){
    //Handler for paging through the user images
    _clickHandler(bool left){
      if(left){
        (hero.iBild==0)?hero.iBild=hero.maxImages:hero.iBild-=1;
        updateHero(newHero: hero);
      }
      else{
        (hero.iBild==hero.maxImages)?hero.iBild=0:hero.iBild+=1;
        updateHero(newHero: hero);
      }
    }

    Widget _rightButton = new IconButton(
        iconSize: screenWidth / 10,
        icon: new Icon(Icons.arrow_forward_ios),
        onPressed: () => _clickHandler(false));
    Widget _leftButton = new IconButton(
        iconSize: screenWidth / 10,
        icon: new Icon(Icons.arrow_back_ios),
        onPressed: () => _clickHandler(true));
    Widget _userImage = Container(
        width: (1-3/10)*screenWidth,
        child: GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details){
              double dx = details.velocity.pixelsPerSecond.dx;
              if(dx>0.0&&dx>10.0)
                {_clickHandler(false);}
              else if(dx<0.0&&dx.abs()>10.0)
                {_clickHandler(true);}},
            child: new Image.asset('images/user_images/hund_${hero.iBild}.jpg')));

    return Container(
      height: screenHeight / 2.5,
      width: screenWidth,
      padding: EdgeInsets.only(top:50.0),
      child: Row(children: <Widget>[
      _leftButton,
      _userImage,
      _rightButton
    ]));
  }

}

class GenderSelector extends StatefulWidget {
  final Held hero;
  final Function heroCallback;

  GenderSelector({this.hero, this.heroCallback});

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
    double circleWidth = screenWidth / 1.8;
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
                      color: Colors.amber[200]
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
  final Map<String,double> _iconSize = {'m': 50,'w':60};


  RotatedIcon({this.geschlecht, this.height, this.listenable,
    this.rotAngle, this.changeGender, this.hero}):super(listenable: listenable);

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

  UserNameField({this.hero, this.heroCallback});

  @override
  UserNameFieldState createState() => new UserNameFieldState(hero: hero, heroCallback: heroCallback);
}

class UserNameFieldState extends State<UserNameField>{
  Held hero;
  Function heroCallback;
  TextEditingController _controller;

  UserNameFieldState({this.hero, this.heroCallback});

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
      maxLength: 10,
      style: TextStyle(fontSize: 32.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500),
      maxLengthEnforced: true,
      controller: _controller,
      onChanged: (name) => updateUser(name),
    );
  }
}