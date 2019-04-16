import 'package:flutter/material.dart';
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

  TopPanelErlebnisse({@required this.imageHeight, @required this.hero});
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

  ProfileRowErlebnisse({@required this.imageHeight, @required this.hero});

  @override
  Widget build(BuildContext context) {
    return new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.only(right: 10.0, top: imageHeight / 2.3),
              child: new Text('Erlebnisse',
                  style: new TextStyle(
                      fontSize: 20.0,
                      color: hero.geschlecht=='m'?Colors.white:Colors.black,
                      fontWeight: FontWeight.w500)),
            ),
            //Here we set the avatar image - the image is taken from hero
            new Container(
                padding: EdgeInsets.only(right: 10.0, top: imageHeight / 2.3),
                child: new CircleAvatar(
                minRadius: 64.0,
                maxRadius: 64.0,
                backgroundColor: Colors.black,
                //Used to transition the image to other screens
                child: new Hero(
                    tag: 'userImage',
                    child: new Material(
                        color: Colors.transparent,
                        child: InkWell(
                            child: Center(
                                child: new CircleAvatar(
                                    backgroundImage: new AssetImage(
                                        hero.iBild!=-1?'images/user_images/hund_${hero.iBild}.jpg'
                                            :'images/user_images/fragezeichen.jpg'),
                                    minRadius: 60.0,
                                    maxRadius: 60.0))
                        )
                    )
                )
            ))
          ],
        );
  }
}

class Erlebnisse extends StatelessWidget{
  final Held hero;
  final GeneralData generalData;
  final Substitution substitution;

  Erlebnisse({@required this.hero, @required this.substitution,
    @required this.generalData});

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
                buildTiledSelection(context, generalData.erlebnisse, substitution),
                TopPanelErlebnisse(imageHeight: _imageHeight, hero: hero),
                ProfileRowErlebnisse(imageHeight: _imageHeight, hero: hero)]
          ),
      )
    );
  }

  //Builds the tiled list for Erlebnisse selection
  Widget buildTiledSelection(BuildContext context, Map<String,Map<String,String>> erlebnisse,
      Substitution substitution) {
    final double _screenHeight = MediaQuery.of(context).size.height;
    List<String> _erlebt = hero.erlebnisse;
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.only(top: _screenHeight / 3, left: 10.0),
      children: _erlebt.map((key) => _buildTile(context, erlebnisse[key], substitution)).toList(),
    );
  }

  Widget _buildTile(BuildContext context, Map<String,String> data, substitution) {
    final record = Erlebniss.fromMap(data: data, substitution: substitution);
    return GridTile(
      child: Card(
        child: MaterialButton(
            child: record.image,
            onPressed: () => _openDialog(ShowErlebniss(image: record.image, text: record.text), context))
        ),
      );
  }

  _openDialog(Widget _dialog, BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return _dialog;
        }
    );
  }
}

class ShowErlebniss extends StatelessWidget{
  final Image image;
  final String text;

  ShowErlebniss({this.image, this.text});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
              key: Key('PopUp'),
              contentPadding: EdgeInsets.all(30.0),
              children: <Widget>[
                image,
                Container(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Text(text,
                        style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                            fontWeight: FontWeight.w300)))
              ]
          );
    }
}

class Erlebniss {
  final String text;
  Image image;
  Substitution substitution;

  Erlebniss({this.text, this.image, this.substitution});

  Erlebniss.fromMap({Map<String, String> data, Substitution substitution})
      : assert(data['text'] != null),
        assert(data['image'] != null),
        text = substitution.applyAllSubstitutions(data['text']),
        image = Image.network(data['image'], fit: BoxFit.cover);
}