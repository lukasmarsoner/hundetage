import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'main.dart';

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

class UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback;

  const UserPage({Key key, this.hero, this.heroCallback}) : super(key: key);

  @override
  UserPageState createState() => new UserPageState(hero: hero, heroCallback: heroCallback);
}

class UserPageState extends State<UserPage> {
  Held hero;
  Function heroCallback;
  double _imageHeight = 200.0;
  double _screenHeight;

  UserPageState({this.hero, this.heroCallback});

  void updateHero({Held newHero}){
    setState(() {
      hero = newHero;
      heroCallback(newHero: hero);
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
                TopPanel(imageHeight: _imageHeight),
                ProfileRow(imageHeight: _imageHeight, hero: hero),
                UserButton(screenHeight:_screenHeight,updateHero:updateHero,hero:hero)],
            )
        )
    );
  }
}

class UserButton extends StatelessWidget {
  final Function updateHero;
  final Held hero;
  final double screenHeight;

  UserButton({this.screenHeight, this.updateHero, this.hero});

  @override
  Widget build(BuildContext context) {
    double _fromTop = screenHeight - 165.0;
    return new Positioned(
        top: _fromTop,
        right: -75.0,
        child: new AnimatedButton(
          hero: hero,
          updateHero: updateHero,
        )
    );
  }
}

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
            new CircleAvatar(
                minRadius: 64.0,
                maxRadius: 64.0,
                backgroundColor: (hero.geschlecht == 'w') ? Colors.red : Colors
                    .blue,
                child: Center(child: new CircleAvatar(
                    backgroundImage: new AssetImage(
                        'images/user_images/dog_${hero.iBild}.jpg'),
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
                    'Beruf: ' + ((hero.geschlecht == 'w') ? 'Abenteurerin' : 'Abenteurer'),
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

class AnimatedButton extends StatefulWidget {
  final Function updateHero;
  final Held hero;

  const AnimatedButton({this.updateHero, this.hero});

  @override
  AnimatedButtonState createState() => new AnimatedButtonState(
      hero: hero,
      updateHero: updateHero);
}

class AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin  {
  AnimationController _animationController;
  Animation<Color> _colorAnimation;
  Function updateHero;
  Held hero;
  final double _expandedSize = 240.0;
  final double _hiddenSize = 70.0;
  Color _unselectedColor = Colors.amber[200];
  Color _selectedColor = Colors.amber;

  AnimatedButtonState({this.updateHero, this.hero});

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
              ExpandedBackground(hero: hero, animationController: _animationController,
              hiddenSize: _hiddenSize, expandedSize: _expandedSize,),
              OptionButton(icon: Icons.cloud_queue, angle: 0.0,
                  animationController: _animationController, onIconClick: _onIconClick),
              OptionButton(icon: Icons.account_circle, angle: -math.pi / 4,
                  animationController: _animationController, onIconClick: _onIconClick),
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
    updateHero(newHero: hero);
    close();
  }
}

class OptionButton extends StatelessWidget {
  final AnimationController animationController;
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

    double iconSize = 40.0 * animationController.value;

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

class ExpandedBackground extends StatelessWidget {
  final AnimationController animationController;
  final Held hero;
  final double hiddenSize, expandedSize;

  ExpandedBackground({this.hero, this.animationController, this.hiddenSize, this.expandedSize});

  @override
  Widget build(BuildContext context) {
    double size = hiddenSize +
        (expandedSize - hiddenSize) * animationController.value;
    return new Container(
      height: size,
      width: size,
      decoration: new BoxDecoration(
          shape: BoxShape.circle,
          color: (hero.geschlecht == 'w') ? Colors.red : Colors.blue
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final AnimationController animationController;
  final Animation colorAnimation;
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
            child: new Icon(
                animationController.value > 0.5
                    ? Icons.supervisor_account
                    : Icons.settings,
                color: Colors.black, size: 50.0),
          ),
          backgroundColor: colorAnimation.value,
        )
    );
  }
}