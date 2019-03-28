import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'main.dart';

//Cuts the square box on the top of the screen diagonally
class _DiagonalClipperErlebnisse extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = new Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height - 40.0);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

//Builds empty panel on top of the screen
class TopPanelErlebnisse extends StatelessWidget {
  final double imageHeight;
  final Held hero;

  TopPanelErlebnisse({this.imageHeight, this.hero});
  @override
  Widget build(BuildContext context) {
    return new Positioned.fill(
      bottom: null,
      child: new ClipPath(
          clipper: new _DiagonalClipperErlebnisse(),
          child: Container(
              height: imageHeight,
              width: MediaQuery.of(context).size.width,
              color: hero.geschlecht == 'm'? Colors.blueAccent : Colors.redAccent)
      ),
    );
  }
}

//Builds the user image and name to show in top panel
class ProfileRowErlebnisse extends StatelessWidget {
  final Held hero;
  final double imageHeight;

  ProfileRowErlebnisse({this.imageHeight, this.hero});

  @override
  Widget build(BuildContext context) {
    double screenWidth  = MediaQuery.of(context).size.width;
    return new Padding(
        padding: new EdgeInsets.only(left: screenWidth - (imageHeight/2+16.0*3),
            top: imageHeight / 2.3),
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
                                    'images/user_images/hund_${hero.iBild}.jpg'),
                                minRadius: 60.0,
                                maxRadius: 60.0))))))
          ],
        ));
  }
}

class Erlebnisse extends StatelessWidget{
  final Held hero;
  final GeneralData generalData;

  Erlebnisse({this.hero, this.generalData});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth  = MediaQuery.of(context).size.width;
    double _imageHeight = 200.0;
    return Scaffold(
      body:new Container(
          height: screenHeight,
          width: screenWidth,
          child: new Stack(
              children: <Widget>[
                TopPanelErlebnisse(imageHeight: _imageHeight, hero: hero),
                ProfileRowErlebnisse(imageHeight: _imageHeight, hero: hero),
                _buildTiledSelection(context, generalData.erlebnisse)]
          ),
      )
    );
  }

  //Builds the tiled list for Erlebnisse selection
  Widget _buildTiledSelection(BuildContext context, Map<String,Map<String,String>> erlebnisse) {
    final double _screenHeight = MediaQuery.of(context).size.height;
    List<String> _erlebt = erlebnisse.keys.toList();
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.only(top: _screenHeight / 3, left: 10.0),
      children: _erlebt.map((key) => _buildTile(context, erlebnisse[key])).toList(),
    );
  }

  Widget _buildTile(BuildContext context, Map<String,String> data) {
    final record = Erlebniss.fromMap(data);
    return GridTile(
      child: Card(
        child: MaterialButton(onPressed: () => print('here'),
            child: record.image),
      ),
    );
  }
}

class Erlebniss {
  final String text;
  Image image;

  Erlebniss.fromMap(Map<String, String> map)
      : assert(map['text'] != null),
        assert(map['image'] != null),
        text = map['text'],
        image = Image.network(map['image'], fit: BoxFit.cover);
}