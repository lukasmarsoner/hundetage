import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rect_getter/rect_getter.dart';
import 'dart:math' as math;
import 'main.dart';

//User settings main class
class UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback, closeMenu;

  const UserPage({Key key, this.hero, this.heroCallback, this.closeMenu}) : super(key: key);

  @override
  UserPageState createState() => new UserPageState(
      hero: hero,
      heroCallback: heroCallback,
      closeMenu: closeMenu);
}

class UserPageState extends State<UserPage> with SingleTickerProviderStateMixin{
  Held hero;
  Function heroCallback, closeMenu;
  List pageKeys;
  GlobalKey userKey;
  double screenHeight, screenWidth;
  //Gets turned on and of when the user clicks on the image
  bool isPageViewVisible = false;
  AnimationController _animationController;
  Animation<Rect> rectAnimation;
  //Used to build the image along the animation from main screen to page view
  OverlayEntry transitionOverlayEntry;
  PageController _pageController = PageController();
  //Getter for the Page View index
  int get currentIndex => _pageController.page.round();

  UserPageState({this.hero, this.heroCallback, this.closeMenu});

  //Create stuff properly...
  @override
  void initState() {
    super.initState();
    transitionOverlayEntry = _createOverlayEntry();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        transitionOverlayEntry.remove();
      }
      if (status == AnimationStatus.completed) {
        _setPageViewVisible(true);
      } else if (status == AnimationStatus.reverse) {
        _setPageViewVisible(false);
      }
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        //Builds image along the path of the animation
        return AnimatedBuilder(
          animation: rectAnimation,
          builder: (context, child) {
            return Positioned(
              //Position is controlled by the animation state...
              top: rectAnimation.value.top,
              left: rectAnimation.value.left,
              child: Image.asset(
                'images/user_images/hund_${hero.iBild}.jpg',
                //...size as well
                height: rectAnimation.value.height,
                width: rectAnimation.value.width,
              ),
            );
          },
        );
      },
    );
  }

  //...and get rid of it
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  //Update user page and hand change to hero to main function
  void updateHero({Held newHero}){
    setState(() {
      hero = newHero;
      heroCallback(newHero: hero);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Get positions of images in animation
    pageKeys = List.generate(hero.maxImages, (i) => RectGetter.createGlobalKey());
    userKey = RectGetter.createGlobalKey();
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth  = MediaQuery.of(context).size.width;
    //When we hit the back button we want to either go back to the main screen
    //or the previous one - depending on if the page view is visible or not
    return WillPopScope(
        onWillPop: () async {
          if (isPageViewVisible) {
            hero.iBild = currentIndex % (hero.maxImages+1);
            updateHero(newHero: hero);
            _hidePageView(hero.iBild);
            return false;
          }
          closeMenu();
          return true;
        },
      child: MaterialApp(home:
        Scaffold(
      //Add new screen elements here
        body: new Container(
            width: screenWidth,
             child: Column(
             children: <Widget>[
               new Stack(
              //make sure to build the Image selection (Page View) on top of everything else
                children: <Widget>[
                  _userImageRow(),
                  //Covers the background when page view is launched
                  _buildWhiteCurtain(),
                  _buildPageView()
                ],
               ),
               //Add stuff here!!!
           ]
          )
        )
      )
    )
   );
  }

  AnimatedBuilder _buildWhiteCurtain() {
    //Rebuild on animation changes
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return _animationController.isDismissed
            //Replace the curtain with empty container if controller is dismissed
            ? Container()
            : Positioned.fill(
          child: Opacity(
            //Never fully cover the background
            opacity: _animationController.value*0.9,
            child: Container(color: Colors.white),
          ),
        );
      },
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
        child: RectGetter(
            key: userKey,
            child: new GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details){
              double dx = details.velocity.pixelsPerSecond.dx;
              if(dx>0.0&&dx>10.0)
                {_clickHandler(false);}
              else if(dx<0.0&&dx.abs()>10.0)
                {_clickHandler(true);}},
            onTap: () => _showPageView(hero.iBild),
            child: new Image.asset('images/user_images/hund_${hero.iBild}.jpg'))));

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

  //All the page view stuff goes here
  Widget _buildPageView() {
    PageView pageView = PageView.builder(
      controller: _pageController,
      itemBuilder: (context, i) {
        return Center(
          child: RectGetter(
            key: pageKeys[i],
            child: Image.asset('images/user_images/hund_${i%(hero.maxImages+1)}.jpg')),
        );
      },
    );

    return Opacity(
      //Hides Page view by making it transparent
      opacity: isPageViewVisible ? 1 : 0,
      child: IgnorePointer(
        //Make sure the page view ignores clicks when it is hidden
        ignoring: !isPageViewVisible,
        child: pageView,
      ),
    );
  }

  //Starts animation
  void _showPageView(int index) async {
    _pageController.jumpToPage(index);
    await Future.delayed(Duration(milliseconds: 50));
    _startTransition(true);
  }

  //Ends animation
  void _hidePageView(int index) async {
    updateHero(newHero: hero);
    await Future.delayed(Duration(milliseconds: 50));
    _startTransition(false);
  }

  //Controls the animation between Page View and the main image
  void _startTransition(bool toPageView) {
    Rect userRect = RectGetter.getRectFromKey(userKey);
    Rect pageRect = RectGetter.getRectFromKey(pageKeys[hero.iBild]);

    rectAnimation = RectTween(
      begin: userRect,
      end: pageRect,
    ).animate(_animationController);

    //Add entry to overlay
    Overlay.of(context).insert(transitionOverlayEntry);

    if (toPageView) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  //Sets Page View to visible
  void _setPageViewVisible(bool visible) {
    setState(() => isPageViewVisible = visible);
  }

}


class GenderSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth  = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth / 6,
      height: screenWidth / 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(244, 244, 244, 1.0),
      ),
    );
  }
}

class GenderLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth  = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(
        bottom: screenWidth / 8,
        top: screenWidth / 8,
      ),
      child: Container(
        height: screenWidth / 8,
        width: 1.0,
        color: Color.fromRGBO(216, 217, 223, 0.54),
      ),
    );
  }
}


const double _defaultGenderAngle = math.pi / 4;
const Map<Gender, double> _genderAngles = {
  Gender.female: -_defaultGenderAngle,
  Gender.other: 0.0,
  Gender.male: _defaultGenderAngle,
};

//This moves the gender icons into position
//Here the full comments from Marcin's blog
class GenderIconTranslated extends StatelessWidget {
  static final Map<Gender, String> _genderImages = {
    Gender.female: "images/gender_female.svg",
    Gender.other: "images/gender_other.svg",
    Gender.male: "images/gender_male.svg",
  };

  final Gender gender;

  const GenderIconTranslated({Key key, this.gender}) : super(key: key);

  bool get _isOtherGender => gender == Gender.other;

  String get _assetName => _genderImages[gender];

  @override
  Widget build(BuildContext context) {
    double screenWidth  = MediaQuery.of(context).size.width;
    Widget icon = Padding(
      padding: EdgeInsets.only(left: screenWidth / 3),
      child: SvgPicture.asset(
        _assetName,
        height: 10.0,
        width: 10.0,
      ),
    );

    Widget rotatedIcon = Transform.rotate(
      angle: -_genderAngles[gender],
      child: icon,
    );

    Widget iconWithALine = Padding(
      padding: EdgeInsets.only(bottom: screenWidth / 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          rotatedIcon,
          GenderLine(),
        ],
      ),
    );

    Widget rotatedIconWithALine = Transform.rotate(
      alignment: Alignment.bottomCenter,
      angle: _genderAngles[gender],
      child: iconWithALine,
    );

    Widget centeredIconWithALine = Padding(
      padding: EdgeInsets.only(bottom: screenWidth / 8),
      child: rotatedIconWithALine,
    );

    return centeredIconWithALine;
  }
}