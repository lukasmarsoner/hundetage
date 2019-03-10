import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState(){
    // Implement reading from file here
    return new _MyAppState(new Held.initial());
  }
}

class _MyAppState extends State<MyApp> {
  Held hero;

  _MyAppState(this.hero);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: new UserPage(this.hero),
    );
  }
}

class DialogonalClipper extends CustomClipper<Path> {
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

class UserPage extends StatefulWidget {
  final Held hero;

  UserPage(this.hero,{Key key}) : super(key: key);

  @override
  _UserPageState createState() => new _UserPageState(hero);
}

class _UserPageState extends State<UserPage> {
  Held hero;
  _UserPageState(this.hero);

  double _imageHeight = 200.0;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        height: 300.0,
        width: MediaQuery.of(context).size.width,
        child: new Stack(
          children: <Widget>[
            _buildTopPanel(),
            _buildProfileRow(this.hero)],
        )
      )
    );
  }

  Widget _buildTopPanel() {
    return new Positioned.fill(
      bottom: null,
      child: new ClipPath(
        clipper: new DialogonalClipper(),
        child: Container(
            height: _imageHeight,
            width: MediaQuery.of(context).size.width,
            color: Colors.amber)
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
            backgroundColor: (this.hero.geschlecht == 'w')?Colors.red:Colors.blue,
            child: Center(child: new CircleAvatar(
              backgroundImage: new AssetImage('images/user_images/dog_${this.hero.iBild}.jpg'),
              minRadius: 60.0,
              maxRadius: 60.0))),
        new Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(
                this.hero.name,
                style: new TextStyle(
                    fontSize: 32.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              new Text(
                (this.hero.geschlecht=='w')?'Abenteurerin':'Abenteurer',
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