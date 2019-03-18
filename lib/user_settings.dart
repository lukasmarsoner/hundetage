import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';

//User settings main class
class UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback;

  const UserPage({Key key, this.hero, this.heroCallback}) : super(key: key);

  @override
  UserPageState createState() => new UserPageState(
      hero: hero,
      heroCallback: heroCallback);
}

class UserPageState extends State<UserPage>{
  Held hero;
  Function heroCallback;
  double screenHeight, screenWidth;
  //Gets turned on and of when the user clicks on the image
  bool isPageViewVisible = false;
  PageController _pageController = PageController();

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
    return WillPopScope(
        onWillPop: () async {
          if (isPageViewVisible) {
            _setPageViewVisible(false, hero.iBild);
            return false;
          }
          return true;
        },
      child: MaterialApp(home:
        Scaffold(
      //Add new screen elements here
        body: new Container(
            width: screenWidth,
             child: new Stack(
              //make sure to build the Image selection (Page View) on top of everything else
              children: <Widget>[
                userImageRow(),
                _buildPageView()
                ],
            )
        )
      )
    )
   );
  }

  Widget userImageRow(){
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
        iconSize: screenHeight / 13,
        icon: new Icon(Icons.arrow_forward_ios),
        onPressed: () => _clickHandler(false));
    Widget _leftButton = new IconButton(
        iconSize: screenHeight / 13,
        icon: new Icon(Icons.arrow_back_ios),
        onPressed: () => _clickHandler(true));
    Widget _userImage = new GestureDetector(
        onTap: () => _setPageViewVisible(true, hero.iBild),
        child: new Image.asset('images/user_images/hund_${hero.iBild}.jpg'));

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

  Widget _buildPageView() {
    PageView pageView = PageView.builder(
      controller: _pageController,
      itemBuilder: (context, i) {
        return Center(
          child: Image.asset('images/user_images/hund_${i%(hero.maxImages+1)}.jpg'),
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

  void _setPageViewVisible(bool visible, int index) {
    _pageController.jumpToPage(index);
    setState(() => isPageViewVisible = visible);
  }

}


