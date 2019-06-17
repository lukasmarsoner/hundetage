import 'package:flutter/material.dart';
import 'package:hundetage/main.dart';
import 'package:hundetage/menuBottomSheet.dart';
import 'package:hundetage/utilities/styles.dart';
import 'package:hundetage/screens/mainScreen.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginSignUpPage extends StatefulWidget{
  final DataHandler dataHandler;

  LoginSignUpPage({@required this.dataHandler});

  @override
  LoginSignUpPageState createState() => new LoginSignUpPageState(
      dataHandler: dataHandler);
}

enum FormMode { LOGIN, SIGNUP, SIGNOUT }

class LoginSignUpPageState extends State<LoginSignUpPage> {
  bool _isIos, _isLoading;
  DataHandler dataHandler;
  String _email, _password, _errorMessage;
  FormMode _formMode = FormMode.LOGIN;

  double get getWidth => MediaQuery.of(context).size.width;
  double get getHeight => MediaQuery.of(context).size.height;

  LoginSignUpPageState({@required this.dataHandler});

  final _formKey = new GlobalKey<FormState>();

  //Update user page and hand change to hero to main function
  void updateData({DataHandler newData}){
    setState(() {
      dataHandler.updateData = newData;
    });
  }

  // Check if form is valid before perform login or sign-up
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _loadAndUpdateData() async{
    Held _newHero = await dataHandler.hero.load(signedIn: true);
    if(_newHero==null){_newHero=dataHandler.hero;}
    setState((){
      //If we are currently logged-in we should log-out the user and set the hero
      //to it's initial values
      //If not - we get the data from the load-function
      //If we don't have anything we use default values
      //All this happens in the load function of the Held-class
      _newHero.signedIn = true;
      dataHandler.updateHero = _newHero;
    });
    _changeFormToSignOut();
  }


  //Sign user out
  _signOut() {
    setState(() {
      dataHandler.authenticator.signOut();
      dataHandler.hero.signedIn = false;
      updateData(newData: dataHandler);
      _changeFormToLogin();
    });
  }

  @override
  void initState() {
    // Initial form is login form if user is not already logged-in
    _formMode = dataHandler.hero.signedIn?FormMode.SIGNOUT:FormMode.LOGIN;
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
    updateData(newData: dataHandler);
  }

  Future<void> _deleteUserData() async{
    FirebaseUser user = await dataHandler.authenticator.getCurrentUser();
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    try {
      //Deleting requires the user to have logged-in only recently
      //We catch the error here and log the user out, should he/she not
      //have signed-in recently. If the user is not - we sign him/her out
      deleteFirestoreUserData(firestore: dataHandler.firestore, user: user);
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
      dataHandler.authenticator.sendPasswordReset(_email);
    }
  }

  void _createUserdataInFirebase(String uid){
    updateCreateFirestoreUserData(firestore: dataHandler.firestore,
        uid: uid, hero: dataHandler.hero);
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
          uid = await dataHandler.authenticator.signIn(_email, _password);
        }
        else {
          uid = await dataHandler.authenticator.signUp(_email, _password);
          dataHandler.authenticator.sendEmailVerification();
          _createUserdataInFirebase(uid);
          _showVerifyEmailSentDialog();
        }
        if (uid.length > 0 && uid != null && _formMode == FormMode.LOGIN) {
          dataHandler.hero.signedIn = true;
          _loadAndUpdateData();
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

    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        resizeToAvoidBottomPadding: false,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: new Text("Bitte bestätige deinen Account"),
          content: new Text("Eine Bestätigungsmail wurde verschickt"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Schließen"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MainPage(dataHandler: dataHandler))
                );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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

  Widget _showBody(){
    return new Container(
        child: new Form(
            key: _formKey,
            child: _showInputLoginMessage()
        ));
  }

  //Showes either login fields or a message that the user is already logged-in
  Widget _showInputLoginMessage(){
    if(dataHandler.hero.signedIn){
      return Stack(children: <Widget>[
        Background(getWidth: getWidth, getHeight: getHeight),
        ListView(
            children: <Widget>[
              ProfileRow(dataHandler: dataHandler, login: true),
              _showLogedInMessage(),
              _showPrimaryButton(),
              _showErrorMessage(),
              _showResetDeleteButton()
            ]
        ),
        MenuBottomSheet(getHeight: getHeight, dataHandler: dataHandler,
            getWidth: getWidth, icon: 'assets/images/user_settings.png',
            homeButtonFunction: () => Navigator.pop(context))
      ]);
    }
    else{
      return Stack(children: <Widget>[
        Background(getWidth: getWidth, getHeight: getHeight),
        ListView(
            children: <Widget>[
              ProfileRow(dataHandler: dataHandler, login: true),
              _showEmailInput(),
              _showPasswordInput(),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _showPrimaryButton(),
                    SizedBox(width: 40),
                    _showSecondaryButton()]),
              _showErrorMessage(),
              SizedBox(height: 40),
              _showResetDeleteButton()
            ]
        ),
        MenuBottomSheet(getHeight: getHeight, dataHandler: dataHandler,
            getWidth: getWidth, icon: 'assets/images/user_settings.png',
            homeButtonFunction: () => Navigator.pop(context))
      ]);
    }
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: subTitleBlackStyle,
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget _showEmailInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(45, 45, 45, 0),
      child: new TextFormField(
        style: subTitleStyle,
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'E-Mail',
            icon: new Icon(
              Icons.mail,
              color: Colors.black,
            )),
        validator: (value) => value.isEmpty ? 'E-Mail Adresse darf nicht leer sein' : null,
        onSaved: (value) => _email = value,
      )
    );
  }

  Widget _showPasswordInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(45, 15, 45, 0),
      child: new TextFormField(
        //focusNode: _focusNode,
        style: subTitleStyle,
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Passwort',
            icon: new Icon(
              Icons.lock,
              color: Colors.black,
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
            Image.asset('assets/images/cloud.png', height: 55.0, width: 55.0),
            Container(
                padding: EdgeInsets.all(10.0),
                child: Text('Du bist jetzt eingelogged',
                    style: new TextStyle(fontSize: 20.0, fontWeight: FontWeight.w300)))
          ]
        )
    );
  }

  Widget _showSecondaryButton() {
    Image _buttonImage;
    if(dataHandler.hero.signedIn){
      _buttonImage = Image.asset('assets/images/cloud_logout_${dataHandler.hero.geschlecht}.png');
    }
    else {
      _buttonImage = Image.asset('assets/images/register_user_${dataHandler.hero.geschlecht}.png');
    }
    return new Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: SizedBox(
          height: 75.0,
          child: new GestureDetector(
              child: _buttonImage,
              onTap: _formMode==FormMode.SIGNOUT?_signOut:_validateAndSubmit
          ),
        ));
  }

  Widget _showPrimaryButton() {
    Image _buttonImage;
    _buttonImage = Image.asset('assets/images/cloud_login.png');
    return new Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: SizedBox(
          height: 70.0,
          child: new GestureDetector(
              child: _buttonImage,
              onTap: _formMode==FormMode.SIGNUP?_changeFormToLogin:_changeFormToSignUp
          ),
        )
    );
  }

  Widget _showResetDeleteButton() {
    Image _buttonImage;
    dataHandler.hero.signedIn
    //TODO: Add correct image
        ?_buttonImage = Image.asset('assets/images/cloud_logout_${dataHandler.hero.geschlecht}.png')
        :_buttonImage = Image.asset('assets/images/cloud_reset_${dataHandler.hero.geschlecht}.png');
    return SizedBox(
        height: 75.0,
        child: new GestureDetector(
            child: _buttonImage,
            onTap:dataHandler.hero.signedIn?_showDeleteUserDialog:_showResetMailDialog
        )
    );
  }
}