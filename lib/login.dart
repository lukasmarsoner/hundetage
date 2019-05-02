import 'package:flutter/material.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'main.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginSignUpPage extends StatefulWidget{
  final Function updateHero;
  final Authenticator authenticator;
  final Held hero;
  final Firestore firestore;

  LoginSignUpPage({@required this.updateHero, @required this.authenticator,
  @required this.hero, @required this.firestore});

  @override
  LoginSignUpPageState createState() => new LoginSignUpPageState(
      authenticator: authenticator, updateHero: updateHero, hero: hero,
      firestore: firestore);
}

enum FormMode { LOGIN, SIGNUP, SIGNOUT }

class LoginSignUpPageState extends State<LoginSignUpPage> {
  bool _isIos, _isLoading;
  Function updateHero;
  Authenticator authenticator;
  double _circleSize;
  Held hero;
  Firestore firestore;
  String _email, _password, _errorMessage;
  FormMode _formMode = FormMode.LOGIN;

  LoginSignUpPageState({@required this.hero, @required this.authenticator,
    @required this.updateHero, @required this.firestore});

  final _formKey = new GlobalKey<FormState>();

  // Check if form is valid before perform login or sign-up
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _loadAndUpdateHero() async{
    Held _newHero = await hero.load(authenticator:authenticator, signedIn: true, firestore: firestore);
    if(_newHero==null){_newHero=hero;}
    setState((){
      //If we are currently logged-in we should log-out the user and set the hero
      //to it's initial values
      //If not - we get the data from the load-function
      //If we don't have anything we use default values
      //All this happens in the load function of the Held-class
      hero = _newHero;
      hero.signedIn = true;
    });
    _changeFormToSignOut();
  }


  //Sign user out
  _signOut() {
    setState(() {
      authenticator.signOut();
      hero.signedIn = false;
      updateHero(newHero:hero);
      _changeFormToLogin();
    });
  }

  @override
  void initState() {
    // Initial form is login form if user is not already logged-in
    _formMode = hero.signedIn?FormMode.SIGNOUT:FormMode.LOGIN;
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  void _changeFormToSignOut() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNOUT;
    });
    updateHero(newHero: hero);
  }

  Future<void> _deleteUserData() async{
    FirebaseUser user = await authenticator.getCurrentUser();
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    try {
      //Deleting requires the user to have logged-in only recently
      //We catch the error here and log the user out, should he/she not
      //have signed-in recently. If the user is not - we sign him/her out
      deleteFirestoreUserData(firestore: firestore, user: user);
      _showDeletionDialog();
      _signOut();
    }
      catch (e) {
      setState(() {
      _isLoading = false;
      if (_isIos) {
        _changeFormToLogin();
        _showDeletionLogoutDialog();
        _errorMessage = e.details;
      } else
        _changeFormToLogin();
        _showDeletionLogoutDialog();
        _errorMessage = e.message;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _resetPassword(){
    if(_validateAndSave()){
      authenticator.sendPasswordReset(_email);
    }
  }

  void _createUserdataInFirebase(String uid){
    updateCreateFirestoreUserData(firestore: firestore, uid: uid, hero: hero);
  }

  // Perform login or sign-up
  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (_validateAndSave()) {
      String uid = "";
      try {
        if (_formMode == FormMode.LOGIN) {
          uid = await authenticator.signIn(_email, _password);
        }
        else {
          uid = await authenticator.signUp(_email, _password);
          authenticator.sendEmailVerification();
          _createUserdataInFirebase(uid);
          _showVerifyEmailSentDialog();
        }
        if (uid.length > 0 && uid != null && _formMode == FormMode.LOGIN) {
          hero.signedIn = true;
          _loadAndUpdateHero();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          if (_isIos) {
            _errorMessage = e.details;
          } else
            _errorMessage = e.message;
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _circleSize = 80.0;

    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        body: Stack(
                  children: <Widget>[
                    _showBody(),
                    _showCircularProgress(),
                  ]),
        );
  }

  Widget _showCircularProgress(){
    return _isLoading
        ?Center(child: CircularProgressIndicator())
        :Container(height: 0.0, width: 0.0,);
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Bitte bestätige deinen Account"),
          content: new Text("Eine Bestätigungsmail wurde verschickt"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Schließen"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Held löschen"),
          content: new Text("Bist du dir sicher, dass du deinen Helden löschen möchtest?"
          "All dein Fortschritt geht dadurch verlohren."),
          actions: <Widget>[
            new RaisedButton(
              key: Key('zurück'),
              child: new Text("Zurück", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              key: Key('Löschen'),
              child: new Text("Löschen"),
              onPressed: () {
                _deleteUserData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showResetMailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Passwort zurücksetzen"),
          content: new Text("Möchtest du dein Passwort zurücksetzen?"),
          actions: <Widget>[
            new RaisedButton(
              key: Key('zurücksetzen'),
              child: new Text("Zurücksetzen", style: TextStyle(color: Colors.white)),
              onPressed: () {
                _resetPassword();
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              key: Key('Schließen'),
              child: new Text("Schließen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Account gelöscht"),
          content: new Text("Dein Account wurde erfogreich gelöscht."),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Schließen"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeletionLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Bitte logge dich erneut ein"),
          content: new Text("Dein letzter Login ist zu lange her."
              "Bitte logge dich erneut ein um deinen Account zu löschen"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Schließen"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _showUser(){
    return new Hero(
                tag: 'userImage',
                child: new Material(
                    color: Colors.transparent,
                    child: InkWell(
                        child: CircleAvatar(
                            minRadius: _circleSize,
                            maxRadius: _circleSize,
                            backgroundColor:hero.geschlecht == 'm' ?Colors.blueAccent:Colors.redAccent,
                            child: Center(child: new CircleAvatar(
                                minRadius: _circleSize * 0.95,
                                maxRadius: _circleSize * 0.95,
                                backgroundImage: new AssetImage(
                                    hero.iBild!=-1?'images/user_images/hund_${hero.iBild}.jpg'
                                        :'images/user_images/fragezeichen.jpg')
                            )
                            )
                        )
                    ),
                )
    );
  }

  Widget _showUsername() {
    return Center(
        child: new Container(
        padding: EdgeInsets.only(top: 20.0),
        key: Key('username'),
        child: new
        Text(
          hero.name,
          style: new TextStyle(
              fontSize: 20.0,
              color: Colors.black,
              fontWeight: FontWeight.w500),
        )
        )
    );
  }

  Widget _showBody(){
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: _showInputLoginMessage()
        ));
  }

  //Showes either login fields or a message that the user is already logged-in
  ListView _showInputLoginMessage(){
    if(hero.signedIn){
      return new ListView(
        shrinkWrap: true,
        children: <Widget>[
          _showUser(),
          _showUsername(),
          _showLogedInMessage(),
          _showPrimaryButton(),
          _showErrorMessage(),
          _showResetDeleteButton()
        ],
      );
    }
    else{
      return new ListView(
        shrinkWrap: true,
        children: <Widget>[
          _showUser(),
          _showUsername(),
          _showEmailInput(),
          _showPasswordInput(),
          _showPrimaryButton(),
          _showSecondaryButton(),
          _showErrorMessage(),
          _showResetDeleteButton()
        ],
      );
    }
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 20.0,
            color: hero.geschlecht == 'm' ? Colors.blueAccent : Colors.redAccent,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget _showEmailInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0.0, 75.0, 0.0, 0.0),
      child: new TextFormField(
        key: Key('email'),
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'E-Mail',
            icon: new Icon(
              Icons.mail,
            )),
        validator: (value) => value.isEmpty ? 'E-Mail Adresse darf nicht leer sein' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        key: Key('password'),
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Passwort',
            icon: new Icon(
              Icons.lock,
            )),
        validator: (value) => value.isEmpty ? 'Passwort darf nicht leer sein' : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  Widget _showLogedInMessage() {
    return new Container(
        padding: EdgeInsets.only(top: 50.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.cloud_done),
            Container(
                padding: EdgeInsets.all(10.0),
                child: Text('Du bist jetzt eingelogged',
                    style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300)))
          ]
        )
    );
  }

  Widget _showSecondaryButton() {
    Text _buttonText = Text('');
    if(_formMode != FormMode.SIGNUP){
      _buttonText = new Text('Registrieren',
          style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300));}
    else{
      _buttonText = new Text('Anmelden',
          style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300));}
    return new FlatButton(
      key: Key('secondaryButton'),
      child: _buttonText,
      onPressed:_formMode==FormMode.SIGNUP?_changeFormToLogin:_changeFormToSignUp
    );
  }

  Widget _showResetDeleteButton() {
    double topPadding = hero.signedIn?30.0:0.0;
    double _iconSize = 40.0;
    IconData _buttonIcon;
    hero.signedIn?_buttonIcon = Icons.delete:_buttonIcon = Icons.cached;
    return new IconButton(
        key: Key('resetDelete'),
        padding: EdgeInsets.only(top:topPadding),
        icon: Icon(_buttonIcon, size: _iconSize),
        onPressed:hero.signedIn?_showDeleteUserDialog:_showResetMailDialog
    );
  }

  Widget _showPrimaryButton() {
    Text _buttonText = Text('');
    if(hero.signedIn){
      _buttonText = new Text('Abmelden',
          style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300));
    }
    else {
      if (_formMode == FormMode.SIGNUP) {
        _buttonText = new Text('Neu registrieren',
            style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300));
      }
      else {
        _buttonText = new Text('Anmelden',
            style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300));
      }
    }
    return new Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            key: Key('primaryButton'),
            elevation: 5.0,
            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            color: hero.geschlecht == 'm' ? Colors.blueAccent : Colors.redAccent,
            child: _buttonText,
            onPressed:_formMode==FormMode.SIGNOUT?_signOut:_validateAndSubmit
          ),
        ));
  }
}