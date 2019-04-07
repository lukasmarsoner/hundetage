import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class Authenticator {
  final FirebaseAuth firebaseAuth;

  Authenticator({this.firebaseAuth});

  Future<String> signIn(String email, String password) async {
    FirebaseUser _user = await firebaseAuth.signInWithEmailAndPassword(
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
    firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<String> signUp(String email, String password) async {
    FirebaseUser _user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return _user.uid;
  }

  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser _user = await firebaseAuth.currentUser();
    return _user;
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
    return firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    FirebaseUser _user = await firebaseAuth.currentUser();
    _user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser _user = await firebaseAuth.currentUser();
    return _user.isEmailVerified;
  }

}
