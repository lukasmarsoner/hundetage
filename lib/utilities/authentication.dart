import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password);

  Future<FirebaseUser> getCurrentUser();

  Future<String> getUsername();

  Future<bool> deleteUser();

  Future<void> sendEmailVerification();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<bool> isEmailVerified();
}

class Authenticator implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String> signIn(String email, String password) async {
    FirebaseUser _user = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    //Make sure people have verified their accounts
    bool _verified = await isEmailVerified();
    if(_verified){
      return _user.uid;
    }
    else{
      return null;
    }
  }

  Future<void> sendPasswordReset(String email) async{
    _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<String> signUp(String email, String password) async {
    FirebaseUser _user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return _user.uid;
  }

  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser _user = await _firebaseAuth.currentUser();
    return _user;
  }

  Future<String> getUsername() async {
    FirebaseUser _user = await getCurrentUser();
    if(_user == null){return null;}else{return _user.displayName;}
  }

  Future<String> getUid() async {
    FirebaseUser _user = await getCurrentUser();
    if(_user == null){return null;}else{return _user.uid;}
  }

  //Deleting requires the user to have logged-in only recenty
  //We catch the error here and log the user out, should he/she not
  //have signed-in recently. If the user is not - we sign him/her out
  Future<bool> deleteUser() async {
    FirebaseUser _user = await getCurrentUser();
    _user.delete().then((error){return true;}).catchError(signOut);
    return false;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    FirebaseUser _user = await _firebaseAuth.currentUser();
    _user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser _user = await _firebaseAuth.currentUser();
    return _user.isEmailVerified;
  }

}
