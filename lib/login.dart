import 'package:flutter/material.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'main.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginSignUpPage extends StatefulWidget {
  final VoidCallback logInLogOut;
  final bool signedIn;
  final Function updateHero;
  final Authenticator authenticator;
  final Held hero;
  final Firestore firestore;

  LoginSignUpPage({@required this.authenticator, @required this.logInLogOut,
    @required this.signedIn, @required this.hero, @required this.updateHero,
    @required this.firestore});

  @override
  State<StatefulWidget> createState() =>
      new _LoginSignUpPageState(signedIn: signedIn,logInLogOut: logInLogOut,
      authenticator: authenticator, updateHero: updateHero, hero: hero,
      firestore: firestore);
}

enum FormMode { LOGIN, SIGNUP, SIGNOUT }

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  bool signedIn, _isIos, _isLoading;
  VoidCallback logInLogOut;
  Function updateHero;
  Authenticator authenticator;
  double _circleSize, _screenWidth;
  Held hero;
  Firestore firestore;
  String _email, _password, _errorMessage;
  FormMode _formMode = FormMode.LOGIN;

  _LoginSignUpPageState({@required this.signedIn,@required this.logInLogOut,
    @required this.hero, @required this.authenticator, @required this.updateHero,
    @required this.firestore});

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
    _changeFormToSignOut();
    logInLogOut();
    Held _newHero = await hero.load(authenticator:authenticator, signedIn: true, firestore: firestore);
    if(_newHero==null){_newHero=hero;}
    setState((){
      //If we are currently logged-in we should log-out the user and set the hero
      //to it's initial values
      //If not - we get the data from the load-function
      //If we don't have anything we use default values
      //All this happens in the load function of the Held-class
      hero = _newHero;
      updateHero(newHero: hero);
      signedIn = true;
    });
  }


  //Sign user out
  _signOut() {
    setState(() {
      logInLogOut();
      _changeFormToLogin();
      updateHero(newHero: Held.initial());
    });
  }

  @override
  void initState() {
    // Initial form is login form if user is not already logged-in
    _formMode = signedIn?FormMode.SIGNOUT:FormMode.LOGIN;
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
  }

  void _deleteUserData(){
    //TODO: add a pop-up explaining what has happened to the user in this case
    setState(() {
      _isLoading = true;
    });
    authenticator.deleteUser().then((_success){if(_success)
        {deleteFirestoreUserData(firestore: firestore, authenticator: authenticator);
        _showDeletionDialog();}
        else{_changeFormToLogin();_showDeletionLogoutDialog();}
    });
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
      String userId = "";
      try {
        if (_formMode == FormMode.LOGIN) {
          print('here');
          print(authenticator);
          userId = await authenticator.signIn(_email, _password);
        } else {
          userId = await authenticator.signUp(_email, _password);
          authenticator.sendEmailVerification();
          _createUserdataInFirebase(userId);
          _showVerifyEmailSentDialog();
        }
        if (userId.length > 0 && userId != null && _formMode == FormMode.LOGIN) {
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
    _screenWidth  = MediaQuery.of(context).size.width;
    _circleSize = _screenWidth / 3;

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
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } return Container(height: 0.0, width: 0.0,);
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
    //Only show current user if we are logged-in
    Held _localHero;
    signedIn?_localHero=hero:_localHero=Held.initial();
    return new Container(
      child: Column(
        children: <Widget>[
          new Material(
              color: Colors.transparent,
              child: InkWell(
                  child: CircleAvatar(
                      minRadius: _circleSize,
                      maxRadius: _circleSize,
                      backgroundColor:_localHero.geschlecht == 'm' ?Colors.blueAccent:Colors.redAccent,
                      child: Center(child: new CircleAvatar(
                          minRadius: _circleSize * 0.95,
                          maxRadius: _circleSize * 0.95,
                          backgroundImage: new AssetImage(
                              _localHero.iBild!=-1?'images/user_images/hund_${_localHero.iBild}.jpg'
                                  :'images/user_images/fragezeichen.jpg')
                      )
                      )
                  )
              )
          ),
          new Container(
            padding: EdgeInsets.only(top:40.0),
              child: new Text(
                _localHero.name,
                style: new TextStyle(
                    fontSize: 28.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w300),
              )
          )
        ],
      )
    );
  }

  Widget _showBody(){
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showUser(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _showSecondaryButton(),
              _showErrorMessage(),
              _showTertiaryButton()
            ],
          ),
        ));
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'E-Mail',
            icon: new Icon(
              Icons.mail,
              color: hero.geschlecht == 'm' ? Colors.blueAccent[200] : Colors.redAccent[200],
            )),
        validator: (value) => value.isEmpty ? 'E-Mail Adresse darf nicht leer sein' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Passwort',
            icon: new Icon(
              Icons.lock,
              color: hero.geschlecht == 'm' ? Colors.blueAccent[200] : Colors.redAccent[200],
            )),
        validator: (value) => value.isEmpty ? 'Passwort darf nicht leer sein' : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  Widget _showSecondaryButton() {
    Text _buttonText = Text('');
    if(_formMode != FormMode.SIGNUP){
      _buttonText = new Text('Registrieren',
          style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300));}
    else{
      _buttonText = new Text('Anmelden',
          style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300));}
    return new FlatButton(
      child: _buttonText,
      onPressed:_formMode==FormMode.SIGNUP?_changeFormToLogin:_changeFormToSignUp
    );
  }

  Widget _showTertiaryButton() {
    double _iconSize = 40.0;
    IconData _buttonIcon;
    signedIn?_buttonIcon = Icons.delete:_buttonIcon = Icons.cached;
    return new IconButton(
        icon: Icon(_buttonIcon, size: _iconSize),
        onPressed:signedIn?_deleteUserData:_resetPassword
    );
  }

  Widget _showPrimaryButton() {
    Text _buttonText = Text('');
    if(signedIn){
      _changeFormToSignOut();
      _buttonText = new Text('Abmelden',
          style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300));
    }
    else {
      if (_formMode == FormMode.SIGNUP) {
        _buttonText = new Text('Neu registrieren',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300));
      }
      else {
        _buttonText = new Text('Anmelden',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300));
      }
    }
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            color: hero.geschlecht == 'm' ? Colors.blueAccent : Colors.redAccent,
            child: _buttonText,
            onPressed:_formMode==FormMode.SIGNOUT?_signOut:_validateAndSubmit
          ),
        ));
  }
}
