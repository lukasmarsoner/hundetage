import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hundetage/login.dart';
import 'user_settings.dart';
import 'dart:math' as math;
import 'erlebnisse.dart';
import 'main.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'package:hundetage/adventures.dart';

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
  final Firestore firestore;
  final Authenticator authenticator;
  final Substitution substitution;

  const MainPage({@required this.substitution, @required this.authenticator,
    @required this.hero, @required this.heroCallback,
    @required this.generalData, @required this.firestore});

  @override
  MainPageState createState() => new MainPageState(
      hero: hero,
      authenticator: authenticator,
      generalData: generalData,
      substitution: substitution,
      firestore: firestore,
      heroCallback: heroCallback);
}

class MainPageState extends State<MainPage> {
  Held hero;
  Function heroCallback;
  GeneralData generalData;
  Firestore firestore;
  double _imageHeight = 200.0;
  Authenticator authenticator;
  Substitution substitution;
  Rect rect;

  MainPageState({@required this.substitution, @required this.authenticator,
    @required this.hero, @required this.heroCallback,
    @required this.generalData, @required this.firestore});

  //Update user page and hand change to hero to main function
  void updateHero({Held newHero}){
    setState(() {
      hero = newHero;
      heroCallback(newHero: hero);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      //Add new screen elements here
        body: new Stack(
              children: <Widget>[
                AbenteuerAuswahl(imageHeight: _imageHeight, firestore: firestore, generalData: generalData,
                    hero: hero, updateHero: updateHero, substitution: substitution),
                TopPanel(imageHeight: _imageHeight, hero: hero),
                ProfileRow(imageHeight: _imageHeight, hero: hero),
                License(),
                UserButton(
                    substitution: substitution,
                    authenticator: authenticator,
                    firestore: firestore,
                    generalData: generalData,
                    updateHero:updateHero,
                    hero:hero)],
            ),
    );
  }
}

//Builds the license information button for the app
class License extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    Positioned license = new Positioned(
        left: 0.0,
        bottom: 0.0,
        child: new IconButton(
            iconSize: 50.0,
            icon: new Icon(Icons.assignment),
            onPressed:() => showLicensePage(
                context: context,
                applicationName: 'Hundetage',
                applicationVersion: '0.6',
                applicationIcon: Image.asset('images/icon.png')))
    );
    return license;
  }
}

//Button for main menu
class UserButton extends StatelessWidget {
  final Function updateHero;
  final Held hero;
  final Firestore firestore;
  final Authenticator authenticator;
  final GeneralData generalData;
  final Substitution substitution;

  UserButton({@required this.updateHero, @required this.authenticator,
    @required this.generalData, @required this.substitution,
    @required this.hero, @required this.firestore});

  @override
  Widget build(BuildContext context) {
    return new Positioned(
        bottom: -75.0,
        right: -75.0,
        child: new AnimatedButton(
          hero: hero,
          authenticator: authenticator,
          generalData: generalData,
          updateHero: updateHero,
          firestore: firestore,
          substitution: substitution,
        )
    );
  }
}

//Builds empty panel on top of the screen
class TopPanel extends StatelessWidget {
  final double imageHeight;
  final Held hero;

  TopPanel({@required this.imageHeight, @required this.hero});
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

  ProfileRow({@required this.imageHeight, @required this.hero});

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
                                  hero.iBild!=-1?'images/user_images/hund_${hero.iBild}.jpg'
                                      :'images/user_images/fragezeichen.jpg'),
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
                        fontSize: 20.0,
                        color: hero.geschlecht=='m'?Colors.white:Colors.black,
                        fontWeight: FontWeight.w500),
                  ),
                  new Text(
                    hero.berufe[hero.iBild][hero.geschlecht],
                    style: new TextStyle(
                        fontSize: 13.0,
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
  final Function updateHero;
  final Held hero;
  final GeneralData generalData;
  final Substitution substitution;
  final Firestore firestore;
  final Authenticator authenticator;

  const AnimatedButton({@required this.updateHero, @required this.hero,
    @required this.generalData, @required this.authenticator,
    @required this.firestore, @required this.substitution});

  @override
  AnimatedButtonState createState() => new AnimatedButtonState(
      hero: hero,
      updateHero: updateHero,
      firestore: firestore,
      substitution: substitution,
      generalData: generalData,
      authenticator: authenticator);
}

class AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin  {
  AnimationController _animationController;
  Function updateHero;
  GeneralData generalData;
  Firestore firestore;
  Substitution substitution;
  Authenticator authenticator;
  Held hero;
  //Define parameters for button size and menu size here
  final double _expandedSize = 240.0;
  final double _hiddenSize = 70.0;

  AnimatedButtonState({@required this.updateHero, @required this.hero,
    @required this.generalData, @required this.authenticator,
    @required this.firestore, @required this.substitution});

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
              OptionButton(icon:hero.signedIn?Icons.cloud_done:Icons.cloud_queue, angle: 0.0,
                  animationController: _animationController,
                  onIconClick: () => _goToNextPage(nextPage: 'login')),
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
    else if(nextPage == 'login'){
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginSignUpPage(
            authenticator: authenticator, updateHero: updateHero, hero: hero,
              firestore: firestore))
    );}
  }
}

//Class for menu options
class OptionButton extends StatelessWidget {
  final AnimationController animationController;
  //Functions to be called are passed as onIconClick
  final Function onIconClick;
  final double angle;
  final IconData icon;

  OptionButton({@required this.animationController, @required this.onIconClick,
    @required this.angle, @required this.icon});

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

  ExpandedBackground({@required this.hero, @required this.animationController,
    @required this.hiddenSize, @required this.expandedSize});

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

  MenuButton({@required this.animationController, @required this.hiddenSize,
    @required this.onButtonTap, @required this.hero});

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
  final Firestore firestore;
  final double imageHeight;
  final Held hero;
  final GeneralData generalData;
  final Function updateHero;
  final Substitution substitution;

  AbenteuerAuswahl({@required this.imageHeight, @required this.firestore, @required this.generalData,
  @required this.hero, @required this.updateHero, @required this.substitution});

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.only(top: imageHeight-50.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('abenteuer').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return LinearProgressIndicator();
            return _buildTiledSelection(context: context, snapshot: snapshot.data.documents,
                hero: hero, substitution: substitution, updateHero: updateHero, firestore: firestore);
            },
        )
    );
  }

  //Builds the tiled list for adventure selection
  Widget _buildTiledSelection({BuildContext context, List<DocumentSnapshot> snapshot,
      Held hero, Substitution substitution, Function updateHero, Firestore firestore}) {
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.only(top: 80.0, left: 10.0),
      children: snapshot.map((data) => _buildTile(context: context, data: data,
      hero: hero, firestore: firestore, updateHero: updateHero, substitution: substitution)).toList(),
    );
  }

  Widget _buildTile({BuildContext context, DocumentSnapshot data, Held hero,
    Firestore firestore, Function updateHero, Substitution substitution}) {
    final record = Adventure.fromSnapshot(data);
    return GridTile(
        child: Card(
          child: MaterialButton(onPressed: () => _gotoAdventureScreen(
            context: context, data: data, hero: hero, firestore: firestore,
            updateHero: updateHero, substitution: substitution, storyname: record.name),
              child: record.image),
              ),
        );
  }

  _gotoAdventureScreen({BuildContext context, DocumentSnapshot data, Held hero,
    Firestore firestore, Function updateHero, Substitution substitution,
    String storyname}){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryLoadingScreen(
          hero: hero, updateHero: updateHero, firestore: firestore,
          storyname: storyname, substitution: substitution, generalData: generalData,
        geschichte: Geschichte(hero: hero, storyname: storyname)))
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

