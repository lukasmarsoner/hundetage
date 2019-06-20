import 'dart:math' as math;
import 'dart:ui';
import 'package:hundetage/utilities/dataHandling.dart';
import 'package:hundetage/utilities/styles.dart';

import 'package:flutter/material.dart';

const double minHeightBottomSheet = 60;

class MenuBottomSheet extends StatefulWidget {
  final double getHeight, getWidth;
  final DataHandler dataHandler;
  final String icon;
  final Function homeButtonFunction;

  MenuBottomSheet({@required this.getHeight, @required this.dataHandler,
  @required this.homeButtonFunction, @required this.getWidth, @required this.icon});

  @override
  MenuBottomSheetState createState() => MenuBottomSheetState(getHeight: getHeight,
  dataHandler: dataHandler, homeButtonFunction: homeButtonFunction,
  getWidth: getWidth, icon: icon);
}

class MenuBottomSheetState extends State<MenuBottomSheet>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  double getHeight, getWidth;
  String icon;
  Function homeButtonFunction;
  DataHandler dataHandler;

  MenuBottomSheetState({@required this.getHeight, @required this.dataHandler,
  @required this.homeButtonFunction, @required this.getWidth, @required this.icon});

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
            height: lerp(minHeightBottomSheet, getHeight),
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
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: <Widget>[
                    _buildErlebnisseList(),
                    Padding(padding: EdgeInsets.only(top: headerTopMargin),
                        child: Row(children: <Widget>[
                          HomeButton(homeButtonFunction: homeButtonFunction, icon: icon),
                          SheetHeader(fontStyle: headerTextStyle),
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

    for(String title in dataHandler.hero.erlebnisse){
      _erlebnisseList.add(_buildItem(erlebniss: dataHandler.generalData.erlebnisse[title]));
    }

    return Container(
        padding: EdgeInsets.only(top: 70.0),
        child:ListView(children: _erlebnisseList));
  }

  Widget _buildItem({Erlebniss erlebniss}) {
    return ExpandedErlebniss(
        visibility: _controller.value,
            onTap: () => _openDialog(ShowErlebniss(erlebniss: erlebniss, dataHandler: dataHandler),
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
        duration: Duration(milliseconds: 200),
        child:GestureDetector(
          onTap: () => onTap(),
            child: Container(
              decoration: BoxDecoration(
                  color: yellow,
                  borderRadius: BorderRadius.circular(10)),
              child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: erlebniss.image),
        )
        )
    );
  }
}

class ShowErlebniss extends StatelessWidget{
  final Erlebniss erlebniss;
  final DataHandler dataHandler;

  ShowErlebniss({this.erlebniss, this.dataHandler});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
            width: 120,
            height: 340,
            child: Row(
                children: <Widget>[
                  Container(
                      height: 20,
                      width: 20,
                      child: Image.asset('assets/images/event.png')),
                  Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(erlebniss.title, style: subTitleBlackStyle))
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
        size: 28,
    );
  }
}

class HomeButton extends StatelessWidget {
  final Function homeButtonFunction;
  final String icon;

  HomeButton({@required this.homeButtonFunction, @required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => homeButtonFunction(),
      child: Image.asset(icon,
        height: 45,
        width: 45,
      )
    );
  }
}