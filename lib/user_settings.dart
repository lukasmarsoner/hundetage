import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';

//User settings main class
class UserPage extends StatefulWidget {
  final Held hero;
  final Function heroCallback;
  final int nImages;
  final double screenHeight, screenWidth;

  const UserPage({Key key, this.hero, this.heroCallback,
    this.screenHeight, this.screenWidth, this.nImages}) : super(key: key);

  @override
  UserPageState createState() => new UserPageState(
      hero: hero,
      heroCallback: heroCallback,
      nImages: nImages,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      iImage: 0);
}

class UserPageState extends State<UserPage>{
  Held hero;
  Function heroCallback;
  double screenHeight, screenWidth;
  int nImages, iImage;
  //Gets turned on and of when the user clicks on the image
  bool isPageViewVisible = false;

  UserPageState({this.hero, this.heroCallback, this.nImages, this.iImage,
  this.screenHeight,this.screenWidth});

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
        body: new Container(
            height: screenHeight,
            width: screenWidth,
            child: new Stack(
              //make sure to build the Image selection (Page View) on top of everything else
              children: <Widget>[
                userImageRow(),
                //userImagePage()
                ],
            )
        )
    );
  }

  Widget userImageRow(){
    //Handler for paging through the user images
    _clickHandler(bool left){
      if(left){
        (iImage==0)?iImage=nImages:iImage-=1;
      }
      else{
        (iImage==nImages)?iImage=0:iImage+=1;
      }
    }

    Widget _rightButton = new IconButton(
        icon: new Icon(Icons.arrow_forward_ios),
        onPressed: () => _clickHandler(false));
    Widget _leftButton = new IconButton(
        icon: new Icon(Icons.arrow_back_ios),
        onPressed: () => _clickHandler(true));
    Widget _userImage = new GestureDetector(
        onTap: () => _setPageViewVisible(true),
        child: new Image.asset('images/user_images/hund_$iImage.jpg'));

    return Container(
      height: screenHeight / 4,
      width: screenWidth,
      padding: EdgeInsets.only(top: 20.0, right: 12.0),
      child: Row(children: <Widget>[
      _leftButton,
      _userImage,
      _rightButton
    ]));
  }

  //Page view for user page selection
  Widget userImagePage() {
    return WillPopScope(
      //When we hit the back button we want to either go back to the main screen
      //or the previous one - depending on if the page view is visible or not
      onWillPop: () async {
        if (isPageViewVisible) {
          _setPageViewVisible(false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body:
        _buildPageView(),
      ),
    );
  }

  Widget _buildPageView() {
    PageView pageView = PageView.builder(
      itemCount: nImages,
      itemBuilder: (context, i) {
        return Center(
          child: Image.asset('images/user_images/hund_$i.jpg'),
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

  void _setPageViewVisible(bool visible) {
    setState(() => isPageViewVisible = visible);
  }

}


