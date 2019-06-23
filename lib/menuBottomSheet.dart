import 'dart:math' as math;
import 'dart:ui';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:hundetage/utilities/styles.dart';
import 'package:flutter/material.dart';

const double minHeightBottomSheet = 60;

class MenuBottomSheet extends StatefulWidget {
  final DataHandler dataHandler;
  final Function homeButtonFunction;

  MenuBottomSheet({@required this.dataHandler, @required this.homeButtonFunction});

  @override
  MenuBottomSheetState createState() => MenuBottomSheetState(
  dataHandler: dataHandler, homeButtonFunction: homeButtonFunction);
}

class MenuBottomSheetState extends State<MenuBottomSheet>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Function homeButtonFunction;
  double get getWidth => MediaQuery.of(context).size.width;
  double get getHeight => MediaQuery.of(context).size.height;
  DataHandler dataHandler;

  MenuBottomSheetState({@required this.dataHandler, @required this.homeButtonFunction});

  double get headerTopMargin =>
      lerp(8, 8 + MediaQuery.of(context).padding.top);

  TextStyle get headerTextStyle => TextStyleTween(begin: subTitleStyle, end: titleStyle).animate(_controller).value;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double lerp(double min, double max) =>
      lerpDouble(min, max, _controller.value);

  @override
  Widget build(BuildContext context) {
    return new AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Positioned(
            height: lerp(minHeightBottomSheet, getHeight-30),
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _toggle,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
          child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xDC00688B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: <Widget>[
                    _buildErlebnisseList(),
                    Padding(padding: EdgeInsets.only(top: headerTopMargin),
                        child: Row(children: <Widget>[
                          HomeButton(homeButtonFunction: homeButtonFunction),
                          SheetHeader(fontStyle: subTitleStyle),
                          Spacer(),
                          MenuButton()
                        ]
                        )
                    )
                  ],
              ),
            ),
          )
        );
      },
    );
  }

  Widget _buildErlebnisseList(){
    List<Widget> _erlebnisseList = new List<Widget>();

    for(String title in dataHandler.hero.erlebnisse.toSet()){
      _erlebnisseList.add(_buildItem(erlebniss: dataHandler.generalData.erlebnisse[title]));
    }

    return Container(
        padding: EdgeInsets.only(top: 70.0),
        child:GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _erlebnisseList)
    );
  }

  Widget _buildItem({Erlebniss erlebniss}) {
    return ExpandedErlebniss(
        visibility: _controller.value,
            onTap: () => _openDialog(ShowErlebniss(erlebniss: erlebniss, dataHandler: dataHandler,
                getWidth: getWidth, getHeight: getHeight),
                context),
            erlebniss: erlebniss);
  }

  _openDialog(Widget _dialog, BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return _dialog;
        }
    );
  }

  void _toggle() {
    final bool isOpen = _controller.status == AnimationStatus.completed;
    _controller.fling(velocity: isOpen ? -2 : 2);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value -= details.primaryDelta / getHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    final double flingVelocity =
        details.velocity.pixelsPerSecond.dy / getHeight;
    if (flingVelocity < 0.0)
      _controller.fling(velocity: math.max(2.0, -flingVelocity));
    else if (flingVelocity > 0.0)
      _controller.fling(velocity: math.min(-2.0, -flingVelocity));
    else
      _controller.fling(velocity: _controller.value < 0.5 ? -2.0 : 2.0);
  }
}

class ExpandedErlebniss extends StatelessWidget {
  final double visibility;
  final Function onTap;
  final Erlebniss erlebniss;

  const ExpandedErlebniss(
      {@required this.visibility,
        @required this.onTap,
        @required this.erlebniss});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
          opacity: visibility,
          duration: Duration(milliseconds: 600),
          child:GestureDetector(
            onTap: () => onTap(),
              child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: erlebniss.image),
          )
    );
  }
}

class ShowErlebniss extends StatelessWidget{
  final Erlebniss erlebniss;
  final DataHandler dataHandler;
  final double getWidth, getHeight;

  ShowErlebniss({@required this.erlebniss, @required this.dataHandler,
    @required this.getHeight, @required this.getWidth});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: 200, maxWidth: getWidth * 4/5,
              minWidth: 250, maxHeight: getHeight * 3/4),
            child: ListView(
                children: <Widget>[
                  Center(child: Container(
                      padding: EdgeInsets.fromLTRB(15,10,15,0),
                      child: Text(erlebniss.title, style: subTitleBlackStyle)
                  )),
                  SizedBox(height: 10,),
                  Container(
                      padding: EdgeInsets.only(left: 15, right: 15),
                      height: 160,
                      width: 160,
                      child: ClipRRect(
                          borderRadius: new BorderRadius.circular(30.0),
                          child: erlebniss.image)),
                  SizedBox(height: 10,),
                  Container(
                      padding: EdgeInsets.fromLTRB(15,10,15,10),
                      child: Text(dataHandler.substitution.applyAllSubstitutions(erlebniss.text),
                          style: textStyle))
                ]
            )
        )
    );
  }
}


class SheetHeader extends StatelessWidget {
  final TextStyle fontStyle;

  const SheetHeader({@required this.fontStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 15),
          child: Text(
            'Erlebnisse',
            style: fontStyle,
          ),
    );
  }
}

class MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
        Icons.menu,
        color: Colors.white,
        size: 35,
    );
  }
}

class HomeButton extends StatelessWidget {
  final Function homeButtonFunction;

  HomeButton({@required this.homeButtonFunction});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => homeButtonFunction(),
      iconSize: 35,
      icon: Icon(Icons.face, color: Colors.white)
    );
  }
}