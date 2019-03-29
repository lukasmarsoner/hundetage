import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_settings.dart';
import 'dart:math' as math;
import 'erlebnisse.dart';
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
  final GeneralData generalData;
  final Function heroCallback;
  final Substitution substitution;

  const MainPage({this.substitution, this.hero, this.heroCallback, this.generalData});

  @override
  MainPageState createState() => new MainPageState(
      hero: hero,
      generalData: generalData,
      substitution: substitution,
      heroCallback: heroCallback);
}

class MainPageState extends State<MainPage> {
  Held hero;
  Function heroCallback;
  GeneralData generalData;
  double _imageHeight = 200.0;
  double screenHeight, screenWidth;
  Substitution substitution;
  Rect rect;

  MainPageState({this. substitution, this.hero, this.heroCallback, this.generalData});

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
    Firestore firestore = new Firestore();
    return Stack(children: <Widget>[
      new Scaffold(
      //Add new screen elements here
        body: new Container(
            height: screenHeight,
            width: screenWidth,
            child: new Stack(
              children: <Widget>[
                AbenteuerAuswahl(screenHeight: screenHeight, firestore: firestore),
                TopPanel(imageHeight: _imageHeight, hero: hero),
                ProfileRow(imageHeight: _imageHeight, hero: hero),
                License(screenHeight: screenHeight),
                UserButton(screenHeight:screenHeight,
                    substitution: substitution,
                    screenWidth: screenWidth,
                    generalData: generalData,
                    updateHero:updateHero,
                    hero:hero)],
            )
        )
      ),
    ]
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
  final Function updateHero, updateRipple;
  final Held hero;
  final GeneralData generalData;
  final double screenHeight, screenWidth;
  final Substitution substitution;

  UserButton({this.screenHeight, this.screenWidth, this.updateHero,
    this.generalData, this.substitution, this.hero, this.updateRipple});

  @override
  Widget build(BuildContext context) {
    double _fromTop = screenHeight - 165.0;
    return new Positioned(
        top: _fromTop,
        right: -75.0,
        child: new AnimatedButton(
          hero: hero,
          generalData: generalData,
          updateHero: updateHero,
          screenWidth: screenWidth,
          substitution: substitution,
          screenHeight: screenHeight,
            updateRipple: updateRipple
        )
    );
  }
}

//Builds empty panel on top of the screen
class TopPanel extends StatelessWidget {
  final double imageHeight;
  final Held hero;

  TopPanel({this.imageHeight, this.hero});
  @override
  Widget build(BuildContext context) {
    return new Positioned.fill(
      bottom: null,
      child: new ClipPath(
          clipper: new _DiagonalClipper(),
          child: Container(
              height: imageHeight,
              width: MediaQuery.of(context).size.width,
              color: hero.geschlecht == 'm'? Colors.blueAccent : Colors.redAccent)
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
                backgroundColor: Colors.black,
                //Used to transition the image to other screens
                child: new Hero(
                  tag: 'userImage',
                  child: new Material(
                      color: Colors.transparent,
                      child: InkWell(
                          child: Center(child: new CircleAvatar(
                              backgroundImage: new AssetImage(
                                  'images/user_images/hund_${hero.iBild}.jpg'),
                              minRadius: 60.0,
                              maxRadius: 60.0)))))),
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
                        fontSize: 28.0,
                        color: hero.geschlecht=='m'?Colors.white:Colors.black,
                        fontWeight: FontWeight.w500),
                  ),
                  new Text(
                    hero.berufe[hero.iBild][hero.geschlecht],
                    style: new TextStyle(
                        fontSize: 14.0,
                        fontStyle: FontStyle.italic,
                        color: hero.geschlecht=='m'?Colors.white:Colors.black,
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
  final Function updateHero, updateRipple;
  final Held hero;
  final GeneralData generalData;
  final Substitution substitution;
  final double screenWidth, screenHeight;

  const AnimatedButton({this.updateHero, this.hero, this.generalData,
  this.screenWidth, this.substitution, this.screenHeight, this.updateRipple});

  @override
  AnimatedButtonState createState() => new AnimatedButtonState(
      hero: hero,
      updateHero: updateHero,
      screenHeight: screenHeight,
      screenWidth: screenWidth,
      substitution: substitution,
      generalData: generalData,
      updateRipple: updateRipple);
}

class AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin  {
  AnimationController _animationController;
  Function updateHero, updateRipple;
  GeneralData generalData;
  Substitution substitution;
  Held hero;
  double screenWidth, screenHeight;
  //Define parameters for button size and menu size here
  final double _expandedSize = 240.0;
  final double _hiddenSize = 70.0;

  AnimatedButtonState({this.updateHero, this.hero, this.generalData,
  this.screenWidth, this.substitution, this.screenHeight, this.updateRipple});

  @override
  void initState() {
    super.initState();
    //Animation controller for menu expansion
    _animationController = new AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200));
  }

  //Makes sure to kill the animation controller when the widget is disposed off
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
                  animationController: _animationController, onIconClick: () => _onIconClick),
              OptionButton(icon: Icons.account_circle, angle: -math.pi / 4,
                    animationController: _animationController,
                    onIconClick: () => _goToNextPage(nextPage: 'user')),
              OptionButton(icon: Icons.add_a_photo, angle: -2 * math.pi / 4,
                  animationController: _animationController,
                  onIconClick: () => _goToNextPage(nextPage: 'erlebnisse')),
              MenuButton(animationController: _animationController, onButtonTap: _onButtonTap,
              hero: hero, hiddenSize: _hiddenSize)
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

  _goToNextPage({String nextPage}){
    close();
    //Chose which page to go to
    if(nextPage == 'user'){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserPage(
          hero: hero,
          substitution: substitution,
          heroCallback: updateHero))
    );}
    else if(nextPage == 'erlebnisse'){
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Erlebnisse(
              hero: hero,
              substitution: substitution,
              generalData: generalData,))
      );}
  }

  //This is just a dummy function now - need to add actual functionality
  _onIconClick() {
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
          color: hero.geschlecht == 'm' ? Colors.blueAccent : Colors.redAccent
      ),
    );
  }
}

//Main Menu button
class MenuButton extends StatelessWidget {
  final AnimationController animationController;
  //onButtonTap calls back to open/close function
  final Function onButtonTap;
  final double hiddenSize;
  final Held hero;

  MenuButton({this.animationController, this.hiddenSize, this.onButtonTap,
    this.hero});

  @override
  Widget build(BuildContext context) {
    //Colors for when menu is clicked and when it is not
    Color _unselectedColor = hero.geschlecht == 'm'? Colors.blueAccent : Colors.redAccent;
    Color _selectedColor = hero.geschlecht=='m'?Colors.white:Colors.black;
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
            child: animationController.value > 0.5
            ?new Icon(Icons.supervisor_account,
                color: hero.geschlecht=='m'?Colors.black:Colors.white,
                size: 50.0)
            :new Icon(Icons.settings,
                color: hero.geschlecht=='m'?Colors.white:Colors.black,
                size: 50.0)
          ),
          //Color will change with animation
          backgroundColor: animationController.value > 0.5?_selectedColor:_unselectedColor
        )
    );
  }
}

//Adventure-Selection Stream builder
class AbenteuerAuswahl extends StatelessWidget{
  final double screenHeight;
  final Firestore firestore;

  AbenteuerAuswahl({this.screenHeight, this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('abenteuer').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildTiledSelection(context, snapshot.data.documents);
        },
    );
  }

  //Builds the tiled list for adventure selection
  Widget _buildTiledSelection(BuildContext context, List<DocumentSnapshot> snapshot) {
    final double _screenHeight = MediaQuery.of(context).size.height;
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.only(top: _screenHeight / 3, left: 10.0),
      children: snapshot.map((data) => _buildTile(context, data)).toList(),
    );
  }

  Widget _buildTile(BuildContext context, DocumentSnapshot data) {
    final record = Adventure.fromSnapshot(data);
    return GridTile(
        child: Card(
        child: MaterialButton(onPressed: () => print(record.name),
              child: record.image),
              ),
        );
  }
}

class Adventure {
  final String name;
  final double version;
  Image image;

  Adventure.fromMap(Map<String, dynamic> map)
      : assert(map['name'] != null),
        assert(map['image'] != null),
        assert(map['version'] != null),
        name = map['name'],
        version = map['version'],
        image = Image.network(map['image'], fit: BoxFit.cover);

  Adventure.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data);
}

