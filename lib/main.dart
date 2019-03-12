import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState(){
    // Implement reading from file here
    return new _MyAppState(hero: new Held.initial());
  }
}

class _MyAppState extends State<MyApp> {
  Held hero;

  _MyAppState({this.hero});

  void updateHeld({Held updatedHero}){
    setState(() {hero = updatedHero;});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: new _UserPage(hero: this.hero, heroCallback: this.updateHeld),
    );
  }
}

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

class _UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback;

  const _UserPage({Key key, this.hero, this.heroCallback}) : super(key: key);

  @override
  _UserPageState createState() => new _UserPageState(hero: this.hero, heroCallback: this.heroCallback);
}

class _UserPageState extends State<_UserPage> {
  Held hero;
  Function heroCallback;
  double _imageHeight = 200.0;
  double _screenHeight;

  _UserPageState({this.hero, this.heroCallback});

  void updateHero({Held newHero}){
    setState(() {
      hero = newHero;
      heroCallback(hero);
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;
    return new Scaffold(
      body: new Container(
        height: _screenHeight,
        width: MediaQuery.of(context).size.width,
        child: new Stack(
          children: <Widget>[
            _buildTopPanel(),
            _buildProfileRow(hero),
            _buildUserButton(hero, updateHero)],
        )
      )
    );
  }

  Widget _buildUserButton(Held hero, Function updateHero) {
    double _fromTop = _screenHeight - 165.0;
    return new Positioned(
        top: _fromTop,
        right: -75.0,
        child:new _AnimatedButton(
          hero: hero,
          heroCallback: updateHero,
        )
    );
  }

  Widget _buildTopPanel() {
    return new Positioned.fill(
      bottom: null,
      child: new ClipPath(
        clipper: new _DiagonalClipper(),
        child: Container(
            height: _imageHeight,
            width: MediaQuery.of(context).size.width,
            color: Colors.amber[200])
      ),
    );
  }

  Widget _buildProfileRow(Held hero) {
    return new Padding(
      padding: new EdgeInsets.only(left: 16.0, top: _imageHeight/2.3),
      child: new Row(
      children: [
        new CircleAvatar(
            minRadius: 64.0,
            maxRadius: 64.0,
            backgroundColor: (hero.geschlecht == 'w')?Colors.red:Colors.blue,
            child: Center(child: new CircleAvatar(
              backgroundImage: new AssetImage('images/user_images/dog_${hero.iBild}.jpg'),
              minRadius: 60.0,
              maxRadius: 60.0))),
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
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              new Text(
                (hero.geschlecht=='w')?'Abenteurerin':'Abenteurer',
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

class Held{
  // Properties of users
  String _name, _geschlecht;
  int _iBild, _maxImages;
  List<String> _erlebnisse;

  // Default values for user
  Map<String,dynamic> _defaults = {
    'name': 'Teemu',
    'geschlecht': 'w',
    'iBild': 0,
    'maxImages': 5,
    'erlebnisse': <String>[]};

  Held(this._name,this._geschlecht,this._iBild,this._maxImages,this._erlebnisse);

  // Initialize new User with defaults
  Held.initial(){
    _name = _defaults['name'];
    _geschlecht = _defaults['geschlecht'];
    _iBild = _defaults['iBild'];
    _maxImages = _defaults['maxImages'];
    _erlebnisse = _defaults['erlebnisse'];
  }

  // Setters with sanity-checks
  set name(String valIn){
    (valIn != null && valIn.length != 0)?_name = valIn:throw new Exception('Invalid name!');
  }
  set geschlecht(String valIn){
    (valIn=='m' || valIn=='w')?_geschlecht = valIn:throw new Exception('Invalid sex!');
  }
  set iBild(int valIn){
    (valIn != null && valIn >=0 && valIn < maxImages)?_iBild = valIn:throw new Exception('Invalid imange index!');
  }
  set maxImages(int valIn){
    (valIn!=null && valIn>iBild && valIn!=0)?_maxImages=valIn:throw new Exception('Invalid number of images!');
  }
  set addErlebniss(String valIn){
    if(valIn != null && valIn != '' && !_erlebnisse.contains(valIn)){_erlebnisse.add(valIn);}
  }

  // Getters
  String get name => _name;
  int get iBild => _iBild;
  int get maxImages => _maxImages;
  String get geschlecht => _geschlecht;
  List<String> get erlebnisse => _erlebnisse;
  // This getter is only for testing
  Map<String,dynamic> get defaults => _defaults;
}

class _AnimatedButton extends StatefulWidget {
  final Function heroCallback;
  final Held hero;

  const _AnimatedButton({this.heroCallback, this.hero});

  @override
  _AnimatedButtonState createState() => new _AnimatedButtonState(
      hero: this.hero,
      heroCallback: this.heroCallback);
}

class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin  {
  AnimationController _animationController;
  Animation<Color> _colorAnimation;
  final Function heroCallback;
  final Held hero;
  final double _expandedSize = 240.0;
  final double _hiddenSize = 70.0;
  Color _unselectedColor = Colors.amber[200];
  Color _selectedColor = Colors.amber;

  _AnimatedButtonState({this.heroCallback, this.hero});

  @override
  void initState() {
    super.initState();
    _animationController = new AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200));
    _colorAnimation = new ColorTween(begin: _unselectedColor, end: _selectedColor)
        .animate(_animationController);
  }

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
            children: <Widget>[
              _buildExpandedBackground(),
              _buildOption(Icons.cloud_queue, 0.0),
              _buildOption(Icons.account_circle, -math.pi / 4),
              _buildOption(Icons.add_a_photo, -2 * math.pi / 4),
              _buildButtonCore()
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(IconData icon, double angle) {
    // Create no buttons if the menu is not expanded
    if (_animationController.isDismissed) {
      return Container();
    }

    double iconSize = 40.0 * _animationController.value;

    return new Transform.rotate(
      angle: angle,
      child: new Align(
        alignment: Alignment.topCenter,
        child: new Padding(
          padding: new EdgeInsets.only(top: 8.0),
          child: new IconButton(
            onPressed: _onIconClick,
            icon: new Transform.rotate(
              angle: -angle,
              child: new Icon(
                icon,
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

  Widget _buildExpandedBackground() {
    double size = _hiddenSize + (_expandedSize - _hiddenSize) * _animationController.value;
    return new Container(
      height: size,
      width: size,
      decoration: new BoxDecoration(
          shape: BoxShape.circle,
          color: (hero.geschlecht=='w')?Colors.red:Colors.blue
      ),
    );
  }

  Widget _buildButtonCore() {
    double scaleFactor = 2 * (_animationController.value - 0.5).abs();
    return Container(
          width: _hiddenSize,
          height: _hiddenSize,
          child:
              FloatingActionButton(
                onPressed: _onButtonTap,
                child: new Transform(
                  alignment: Alignment.center,
                  transform: new Matrix4.identity()..scale(1.0, scaleFactor),
                  child: new Icon(
                    _animationController.value > 0.5 ? Icons.supervisor_account : Icons.settings,
                    color: Colors.black, size: 50.0),
                ),
                backgroundColor: _colorAnimation.value,
              )
          );
  }

  open() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    }
  }

  close() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  _onButtonTap() {
    if (_animationController.isDismissed) {
      open();
    } else {
      close();
    }
  }

  _onIconClick() {
    (hero.geschlecht=='w')?hero.geschlecht='m':hero.geschlecht='w';
    heroCallback(hero);
    close();
  }
}

