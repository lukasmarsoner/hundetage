import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'user_settings.dart';
import 'dart:math' as math;
import 'main.dart';

//Cuts the square box on the top of the screen diagonally
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = new Path();
    path.lineTo(0.0, size.height - 40.0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

//Main page class
class MainPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback;
  final int nImages;

  const MainPage({Key key, this.hero, this.heroCallback, this.nImages}) : super(key: key);

  @override
  MainPageState createState() => new MainPageState(
      hero: hero,
      heroCallback: heroCallback,
      nImages: nImages);
}

class MainPageState extends State<MainPage> {
  Held hero;
  Function heroCallback;
  double _imageHeight = 200.0;
  double screenHeight, screenWidth;
  int nImages;

  MainPageState({this.hero, this.heroCallback, this.nImages});

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
    return new Scaffold(
      //Add new screen elements here
        body: new Container(
            height: screenHeight,
            width: MediaQuery.of(context).size.width,
            child: new Stack(
              children: <Widget>[
                TopPanel(imageHeight: _imageHeight),
                ProfileRow(imageHeight: _imageHeight, hero: hero),
                License(screenHeight: screenHeight),
                UserButton(screenHeight:screenHeight,
                    screenWidth: screenWidth,
                    updateHero:updateHero,
                    hero:hero,
                    nImages: nImages)],
            )
        )
    );
  }
}

//Builds the license information button for the app
class License extends StatelessWidget{
  final screenHeight, screenWidth;

  License({this.screenHeight, this.screenWidth});

  @override
  Widget build(BuildContext context) {
    double _fromTop = screenHeight - 65.0;
    Positioned license = new Positioned(
        top: _fromTop,
        left: 5.0,
        child: new IconButton(
            iconSize: 40.0,
            icon: new Icon(Icons.assignment),
            onPressed:() => showLicensePage(
                context: context,
                applicationName: 'Hundetage',
                applicationVersion: '1.0',
                applicationIcon: Image.asset('images/icon.png')))
    );
    return license;
  }
}

//Button for main menu
class UserButton extends StatelessWidget {
  final Function updateHero;
  final Held hero;
  final int nImages;
  final double screenHeight, screenWidth;

  UserButton({this.screenHeight, this.screenWidth, this.updateHero,
    this.hero, this.nImages});

  @override
  Widget build(BuildContext context) {
    double _fromTop = screenHeight - 165.0;
    return new Positioned(
        top: _fromTop,
        right: -75.0,
        child: new AnimatedButton(
          hero: hero,
          nImages: nImages,
          updateHero: updateHero,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        )
    );
  }
}

//Builds empty panel on top of the screen
class TopPanel extends StatelessWidget {
  final double imageHeight;

  TopPanel({this.imageHeight});
  @override
  Widget build(BuildContext context) {
    return new Positioned.fill(
      bottom: null,
      child: new ClipPath(
          clipper: new _DiagonalClipper(),
          child: Container(
              height: imageHeight,
              width: MediaQuery.of(context).size.width,
              color: Colors.amber[200])
      ),
    );
  }
}

//Builds the user image and name to show in top panel
class ProfileRow extends StatelessWidget {
  final Held hero;
  final double imageHeight;

  ProfileRow({this.imageHeight, this.hero});

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: new EdgeInsets.only(left: 16.0, top: imageHeight / 2.3),
        child: new Row(
          children: [
            //Here we set the avatar image - the image is taken from hero
            new CircleAvatar(
                minRadius: 64.0,
                maxRadius: 64.0,
                backgroundColor: (hero.geschlecht == 'w') ? Colors.red : Colors
                    .blue,
                child: Center(child: new CircleAvatar(
                    backgroundImage: new AssetImage(
                        'images/user_images/hund_${hero.iBild}.jpg'),
                    minRadius: 60.0,
                    maxRadius: 60.0))),
            //Add some padding and then put in user name and description
            new Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Text(
                    hero.name,
                    style: new TextStyle(
                        fontSize: 32.0,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                        fontWeight: FontWeight.w500),
                  ),
                  new Text(
                    (hero.geschlecht == 'w') ? 'Abenteurerin' : 'Abenteurer',
                    style: new TextStyle(
                        fontSize: 14.0,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                        fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}

//Animated button for main menu
class AnimatedButton extends StatefulWidget {
  final Function updateHero;
  final Held hero;
  final int nImages;
  final double screenWidth, screenHeight;

  const AnimatedButton({this.updateHero, this.hero, this.nImages,
  this.screenWidth, this.screenHeight});

  @override
  AnimatedButtonState createState() => new AnimatedButtonState(
      hero: hero,
      updateHero: updateHero,
      nImages: nImages,
      screenHeight: screenHeight,
      screenWidth: screenWidth);
}

class AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin  {
  AnimationController _animationController;
  Animation<Color> _colorAnimation;
  Function updateHero;
  Held hero;
  int nImages;
  double screenWidth, screenHeight;
  //Define parameters for button size and menu size here
  final double _expandedSize = 240.0;
  final double _hiddenSize = 70.0;
  //Colors for when menu is clicked and when it is not
  Color _unselectedColor = Colors.amber[200];
  Color _selectedColor = Colors.amber;

  AnimatedButtonState({this.updateHero, this.hero, this.nImages,
  this.screenWidth, this.screenHeight});

  @override
  void initState() {
    super.initState();
    //Animation controller for manu expansion
    _animationController = new AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200));
    //Animation for color change of menu when clicked
    _colorAnimation = new ColorTween(begin: _unselectedColor, end: _selectedColor)
        .animate(_animationController);
  }

  //Makr sure to kill the animation controller when the widget is disposed off
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new SizedBox(
      width: _expandedSize,
      height: _expandedSize,
      child: new AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget child) {
          return new Stack(
            alignment: Alignment.center,
            //Here we add the menu options: to-do: add actual functions via _onIconClick
            children: <Widget>[
              ExpandedBackground(hero: hero, animationController: _animationController,
              hiddenSize: _hiddenSize, expandedSize: _expandedSize,),
              OptionButton(icon: Icons.cloud_queue, angle: 0.0,
                  animationController: _animationController, onIconClick: _onIconClick),
              OptionButton(icon: Icons.account_circle, angle: -math.pi / 4,
                  animationController: _animationController, onIconClick: _launchUserSettings),
              OptionButton(icon: Icons.add_a_photo, angle: -2 * math.pi / 4,
                  animationController: _animationController, onIconClick: _onIconClick),
              MenuButton(animationController: _animationController, onButtonTap: _onButtonTap,
              colorAnimation: _colorAnimation, hiddenSize: _hiddenSize)
            ],
          );
        },
      ),
    );
  }

  //When menu is closed - play the animation forward
  open() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    }
  }

  //when it is open - play it backwards
  close() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  //Call functions above
  _onButtonTap() {
    if (_animationController.isDismissed) {
      open();
    } else {
      close();
    }
  }

  _launchUserSettings(){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserPage(
          hero: hero,
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          heroCallback: updateHero,
          nImages: nImages)));
  }

  //This is just a dummy function now - need to add actual functionality
  _onIconClick() {
    (hero.geschlecht=='w')?hero.geschlecht='m':hero.geschlecht='w';
    updateHero(newHero: hero);
    close();
  }
}

//Class for menu options
class OptionButton extends StatelessWidget {
  final AnimationController animationController;
  //Functions to be called are passed as onIconClick
  final Function onIconClick;
  final double angle;
  final IconData icon;

  OptionButton({this.animationController, this.onIconClick, this.angle, this.icon});

  @override
  Widget build(BuildContext context) {
    // Create no buttons if the menu is not expanded
    if (animationController.isDismissed) {
      return Container();
    }

    //Size-in icons when the menu is expanded
    double iconSize = 40.0 * animationController.value;

    //Rotate widgets on circular menu - then rotate them to al be straight
    return new Transform.rotate(
      angle: angle,
      child: new Align(
        alignment: Alignment.topCenter,
        child: new Padding(
          padding: new EdgeInsets.only(top: 8.0),
          child: new IconButton(
            onPressed: onIconClick,
            icon: new Transform.rotate(
              angle: -angle,
              child: new Icon(icon,
                color: Colors.white,
              ),
            ),
            iconSize: iconSize,
            alignment: Alignment.center,
            padding: new EdgeInsets.all(0.0),
          ),
        ),
      ),
    );
  }
}

//Class for expanding menu background
class ExpandedBackground extends StatelessWidget {
  final AnimationController animationController;
  final Held hero;
  //Parameters that determine menu size
  final double hiddenSize, expandedSize;

  ExpandedBackground({this.hero, this.animationController, this.hiddenSize, this.expandedSize});

  @override
  Widget build(BuildContext context) {
    double size = hiddenSize +
        (expandedSize - hiddenSize) * animationController.value;
    return new Container(
      height: size,
      width: size,
      //Color depends on user sex
      decoration: new BoxDecoration(
          shape: BoxShape.circle,
          color: (hero.geschlecht == 'w') ? Colors.red : Colors.blue
      ),
    );
  }
}

//Main Menu button
class MenuButton extends StatelessWidget {
  final AnimationController animationController;
  final Animation colorAnimation;
  //onButtonTap calls back to open/close function
  final Function onButtonTap;
  final double hiddenSize;

  MenuButton({this.animationController, this.hiddenSize, this.onButtonTap, this.colorAnimation});

  @override
  Widget build(BuildContext context) {
    double scaleFactor = 2 * (animationController.value - 0.5).abs();
    return Container(
        width: hiddenSize,
        height: hiddenSize,
        child:
        FloatingActionButton(
          onPressed: onButtonTap,
          child: new Transform(
            alignment: Alignment.center,
            transform: new Matrix4.identity()
              ..scale(1.0, scaleFactor),
            //Icon depends on the state of the animation
            child: new Icon(
                animationController.value > 0.5
                    ? Icons.supervisor_account
                    : Icons.settings,
                color: Colors.black, size: 50.0),
          ),
          //Color will change with animation
          backgroundColor: colorAnimation.value,
        )
    );
  }
}