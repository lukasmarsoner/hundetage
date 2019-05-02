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

  Future<String> getUid() async {
    FirebaseUser _user = await firebaseAuth.currentUser();
    if(_user == null){return null;}else{return _user.uid;}
  }

  Future<void> signOut() async {
    return firebaseAuth.signOut();
  }

  Future<FirebaseUser> getCurrentUser() async {
    return firebaseAuth.currentUser();
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
