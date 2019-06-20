import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hundetage/screens/userSettings.dart';
import 'package:flutter/services.dart';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:hundetage/menuBottomSheet.dart';
import 'package:hundetage/utilities/styles.dart';
import 'package:hundetage/screens/adventures.dart';

//Main page class
class MainPage extends StatefulWidget {
  final DataHandler dataHandler;

  const MainPage({@required this.dataHandler});

  @override
  MainPageState createState() => new MainPageState(
      dataHandler: dataHandler);
}

class MainPageState extends State<MainPage> {
  DataHandler dataHandler;
  double get getWidth => MediaQuery.of(context).size.width;
  double get getHeight => MediaQuery.of(context).size.height;

  MainPageState({@required this.dataHandler});

  //Update user page and hand change to hero to main function
  void updateData({DataHandler newData}){
    setState(() {
      dataHandler.updateData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Stack(
      children: <Widget>[
        Background(getWidth: getWidth, getHeight: getHeight),
        Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ProfileRow(dataHandler: dataHandler, login: false),
              AbenteuerAuswahl(dataHandler: dataHandler, getHeight: getHeight),
            ]),
        MenuBottomSheet(getHeight: getHeight, dataHandler: dataHandler,
            getWidth: getWidth, icon: 'assets/images/logout.png',
            homeButtonFunction: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'))
      ],
    );
  }
}

class ProfileRow extends StatelessWidget{
  final DataHandler dataHandler;
  final bool login;

  ProfileRow({@required this.dataHandler, @required this.login});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(dataHandler: dataHandler))),
      child: Padding(padding: EdgeInsets.only(left: 20.0, top: 30.0),
        child: Row(
            children: <Widget>[
              dataHandler.hero.iBild!=-1
                  ?new CircleAvatar(
                  backgroundImage:
                  new AssetImage('assets/images/user_images/hund_${dataHandler.hero.iBild}.jpg'),
                  minRadius: 56.0,
                  maxRadius: 56.0)
                  :new Container(),
              new Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: login
                        ?<Widget>[new Text(
                        'Erstelle ein Profil', style: titleStyle)]
                        :<Widget>[
                          new Text(
                            dataHandler.hero.iBild==-1
                                ?'Wilkommen bei Hundetage!'
                                :'Willkommen zurück!', style: titleStyle),
                      dataHandler.hero.iBild==-1
                          ?new Text('Tippe hier um deinen Helden zu erstellen',style: subTitleStyle)
                          :Container()
                    ]
                ),
              ),
            ]
        ),
      ),
    );
  }
}

//Adventure-Selection Stream builder
class AbenteuerAuswahl extends StatelessWidget{
  final DataHandler dataHandler;
  final double getHeight;

  AbenteuerAuswahl({@required this.dataHandler, @required this.getHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getHeight - 220.0,
        padding: EdgeInsets.only(left: 15, right: 15),
        child: _buildTiledSelection(context: context,
            storyList: dataHandler.stories.keys.toList())
        );
      }

  //Builds the tiled list for adventure selection
  Widget _buildTiledSelection({BuildContext context, List<String> storyList}) {
    return PageView(
      children: storyList.map((storyname) => _buildCard(context: context,
          storyname: storyname)).toList(),
    );
  }

  Widget _buildCard({BuildContext context, String storyname}) {
    dataHandler.currentStory = storyname;
    return new GestureDetector(
        onTap: () => _gotoAdventureScreen(context: context, dataHandler: dataHandler),
        child: new Card(margin: EdgeInsets.only(left: 8, right: 8, top: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      child: dataHandler.getCurrentStory.image),
                  SizedBox(height: 20),
                  Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text(storyname,
                          style: titleBlackStyle)),
                  SizedBox(height: 10),
                  Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(dataHandler.stories[storyname].zusammenfassung,
                          style: textStyle))
                ]
            )
        )
    );
  }

  _gotoAdventureScreen({BuildContext context, DataHandler dataHandler}){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GeschichteMainScreen(
          dataHandler: dataHandler))
    );
  }
}

