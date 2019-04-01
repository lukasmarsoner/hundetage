import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password);

  Future<FirebaseUser> getCurrentUser();

  Future<String> getUsername();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();
}

class Authenticator implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String> signIn(String email, String password) async {
    FirebaseUser _user = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return _user.uid;
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

  void deleteUser() async {
    FirebaseUser _user = await _firebaseAuth.currentUser();
    _user.delete();
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
