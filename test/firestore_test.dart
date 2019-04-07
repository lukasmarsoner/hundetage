import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';
import 'package:hundetage/main_screen.dart';
import 'package:image_test_utils/image_test_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'package:hundetage/login.dart';

void main() {
  group('Firebase unit tests', () {
    //Mock class-instances needed in all tests involving classes initialized from Firebase
    final Firestore mockFirestore = MockFirestore();
    final MockFireUser mockFireUser = MockFireUser();
    final MockAuthenticator mockFireAuth = MockAuthenticator();

    final CollectionReference mockCollectionReference = MockCollectionReference();

    final DocumentSnapshot mockDocumentSnapshotGendering = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotErlebnisse = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotUser = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotAbenteuer = MockDocumentSnapshot();

    final DocumentReference mockDocumentReferenceGendering = MockDocumentReference();
    final DocumentReference mockDocumentReferenceErlebnisse = MockDocumentReference();
    final DocumentReference mockDocumentReferenceUser = MockDocumentReference();
    final QuerySnapshot mockQuerySnapshot = MockQuerySnapshot();

    //Data used for testing - we will return this in our mocked request to Firebase
    //The data returnd from firebase is Map<dynamic,dynamic>, so the versions handed
    //to the mock firebase should be of that same type. As tests seem to fail that
    //way, we use the next-best thing
    Map<String,dynamic> _genderingMockData = {'ErSie':{'m':'Er','w':'Sie'},
      'eineine':{'m':'ein','w':'eine'},
      'HeldHeldin':{'m':'Held','w':'Heldin'},
      'wahrerwahre':{'m':'wahrer','w':'wahre'}};
    Map<String,dynamic> _erlebnisseMockData = {
      'besteFreunde':{'text': 'Some test Text', 'image': 'https://example.com/image.png'},
      'alteFrau':{'text': 'Some other test Text', 'image': 'https://example.com/image.png'}};
    Map<String, dynamic> _adventure1 = {
      'name': 'Reja', 'version': 0.6, 'image': 'https...'};

    //Mock the collection
    when(mockFirestore.collection('general_data')).thenReturn(mockCollectionReference);
    //Mock both documents
    when(mockCollectionReference.document('gendering')).thenReturn(mockDocumentReferenceGendering);
    when(mockDocumentReferenceGendering.get()).thenAnswer((_) async => mockDocumentSnapshotGendering);
    when(mockDocumentSnapshotGendering.data).thenReturn(_genderingMockData);

    when(mockCollectionReference.document('erlebnisse')).thenReturn(mockDocumentReferenceErlebnisse);
    when(mockDocumentReferenceErlebnisse.get()).thenAnswer((_) async => mockDocumentSnapshotErlebnisse);
    when(mockDocumentSnapshotErlebnisse.data).thenReturn(_erlebnisseMockData);

    when(mockFirestore.collection('user_data')).thenReturn(mockCollectionReference);
    when(mockCollectionReference.document('hQtzTZdHkQde3dUxyZQ3EkzxYYn1')).thenReturn(mockDocumentReferenceUser);
    when(mockDocumentReferenceUser.get()).thenAnswer((_) async => mockDocumentSnapshotUser);
    when(mockDocumentSnapshotUser.data).thenReturn(testHeld.values);

    when(mockFirestore.collection('abenteuer')).thenReturn(mockCollectionReference);
    when(mockCollectionReference.snapshots()).thenAnswer((_) => Stream.fromIterable([mockQuerySnapshot]));
    when(mockQuerySnapshot.documents).thenReturn([mockDocumentSnapshotAbenteuer]);
    when(mockDocumentSnapshotAbenteuer.data).thenReturn(_adventure1);

    when(mockFireUser.uid).thenReturn('hQtzTZdHkQde3dUxyZQ3EkzxYYn1');
    when(mockFireUser.isEmailVerified).thenReturn(true);
    when(mockFireUser.displayName).thenReturn('Mara');
    
    when(mockFireAuth.sendPasswordResetEmail(email: 'test@test.de')).thenReturn(null);
    when(mockFireAuth.createUserWithEmailAndPassword(email: 'test@test.de', password: 'test'))
        .thenAnswer((_) async => mockFireUser);
    when(mockFireAuth.signInWithEmailAndPassword(email: 'test@test.de', password: 'test'))
        .thenAnswer((_) async => mockFireUser);
    when(mockFireAuth.currentUser())
        .thenAnswer((_) async => mockFireUser);
    when(mockFireAuth.signOut()).thenReturn(null);

    test('Test GeneralData Class', () async{
      //Initialize the class
      GeneralData _generalData = await loadGeneralData(mockFirestore);
      
      //See if initialization worked correctly
      expect(_generalData.gendering, genderingTestData);
      expect(_generalData.erlebnisse, erlebnisseTestData);
    });

    testWidgets('Test Adventure Selection', (WidgetTester _tester) async {
      provideMockedNetworkImages(() async {

        AbenteuerAuswahl _widget = AbenteuerAuswahl(firestore: mockFirestore, imageHeight: 200.0);
        await _tester.pumpWidget(StaticTestWidget(returnWidget: _widget));
        await _tester.pumpAndSettle();

        //Check if one grid-tile was added
        var _findTile = find.byType(GridTile);
        expect(_findTile, findsOneWidget);
        final _image = find.byType(Image);
        expect(_image, findsOneWidget);
      });
    });

    testWidgets('Test main-screen', (WidgetTester _tester) async {
      await _tester.pumpWidget(
          StaticTestWidget(returnWidget: ProfileRow(hero: testHeld, imageHeight: 200.0))
      );

      //See if the main screen looks as it should
      final _findUsername = find.text(testHeld.name);
      final String _beruf = testHeld.berufe[testHeld.iBild][testHeld.geschlecht];
      final _findJob = find.text(_beruf);
      final _userImage = find.byType(CircleAvatar);

      expect(_userImage, findsNWidgets(2));
      expect(_findUsername, findsOneWidget);
      expect(_findJob, findsOneWidget);
    });

    // Test menu
    testWidgets('Test menu', (WidgetTester _tester) async {
      AnimatedButton _widget = AnimatedButton(hero: testHeld,updateHero: ()=>null,
          substitution: substitutions, generalData: generalData, firestore: mockFirestore,
          authenticator: authenticator);
      await _tester.pumpWidget(
          StaticTestWidget(returnWidget: _widget)
      );

      //See if icon is there
      var _findMenuIcon = find.byIcon(Icons.settings);
      expect(_findMenuIcon, findsOneWidget);

      //Click on menu
      var _findButton = find.byType(FloatingActionButton);
      expect(_findButton, findsOneWidget);
      await _tester.tap(find.byType(FloatingActionButton));
      //Wait for animation to terminate
      await _tester.pumpAndSettle();
      //Check if Icon has changed
      var _findChangedMenuIcon = find.byIcon(Icons.supervisor_account);
      expect(_findChangedMenuIcon, findsOneWidget);
      //Check if menu items are now there
      _findMenuIcon = find.byIcon(Icons.cloud_queue);
      expect(_findMenuIcon, findsOneWidget);
      _findMenuIcon = find.byIcon(Icons.account_circle);
      expect(_findMenuIcon, findsOneWidget);
      _findMenuIcon = find.byIcon(Icons.add_a_photo);
      expect(_findMenuIcon, findsOneWidget);

      //Click menu again and check it has been closed
      //Click on menu
      _findButton = find.byType(FloatingActionButton);
      expect(_findButton, findsOneWidget);
      await _tester.tap(find.byType(FloatingActionButton));
      //Wait for animation to terminate
      await _tester.pumpAndSettle();
      //Check if Icon has changed
      _findChangedMenuIcon = find.byIcon(Icons.settings);
      expect(_findChangedMenuIcon, findsOneWidget);
      //Check if menu items are now there
      _findMenuIcon = find.byIcon(Icons.cloud_queue);
      expect(_findMenuIcon, findsNothing);
      _findMenuIcon = find.byIcon(Icons.account_circle);
      expect(_findMenuIcon, findsNothing);
      _findMenuIcon = find.byIcon(Icons.add_a_photo);
      expect(_findMenuIcon, findsNothing);
    });

    testWidgets('Test License', (WidgetTester _tester) async {
      MainPage _widget = MainPage(hero: testHeld,heroCallback: ()=>null,
          substitution: substitutions,
          generalData: generalData, firestore: mockFirestore, authenticator: authenticator);
      await _tester.pumpWidget(
          StaticTestWidget(returnWidget: _widget));

      //Click on license button
      var _findButton = find.byType(IconButton);
      expect(_findButton, findsOneWidget);
      await _tester.tap(find.byType(IconButton));
      //Wait for animation to terminate
      await _tester.pumpAndSettle();
      //Check Title is there
      var _findTitleText = find.text('Licenses');
      expect(_findTitleText, findsOneWidget);
      //Check App Title is maintained
      var _findAppText = find.text('Hundetage');
      expect(_findAppText, findsOneWidget);
    });

    testWidgets('Test login screen', (WidgetTester _tester) async {
      SplashScreen _widget = new SplashScreen();
      await _tester.pumpWidget(_widget);
      final _findImage = find.byType(Image);
      expect(_findImage, findsOneWidget);
      await _tester.pump();
      final _findText = find.byKey(Key('loadingText'));
      expect(_findText, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('Load User from Firebase', () async{
      //Initialize the class
      Authenticator _testAuth = new Authenticator(firebaseAuth: mockFireAuth);

      //Make sure we don't just get the same values we put in
      Held _tmpHeld = Held.initial();
      _tmpHeld = await _tmpHeld.load(signedIn: true, firestore: mockFirestore, authenticator: _testAuth);
      expect(_tmpHeld.values, testHeld.values);
    });

    testWidgets('Test login screen', (WidgetTester _tester) async {
        Authenticator _testAuth = new Authenticator(firebaseAuth: mockFireAuth);
        StaticTestWidget _widget = StaticTestWidget(returnWidget: LoginSignUpPage(
            authenticator: _testAuth, hero: testHeld,//, screenHeight: 800.0, screenWidth: 80.0,
            updateHero: ({Held newHero}) => null, firestore: mockFirestore));

        await _tester.pumpWidget(_widget);

        //As always: see if things look like they should
        final _findImage = find.byType(CircleAvatar);
        expect(_findImage, findsNWidgets(2));
        final _findUsername = find.byKey(Key('username'));
        expect(_findUsername, findsOneWidget);
        final _findEmail = find.byKey(Key('email'));
        expect(_findEmail, findsOneWidget);
        final _findPassword = find.byKey(Key('password'));
        expect(_findPassword, findsOneWidget);
        final _findPrimButton = find.byKey(Key('primaryButton'));
        expect(_findPrimButton, findsOneWidget);
        final _findSecondButton = find.byKey(Key('secondaryButton'));
        expect(_findSecondButton, findsOneWidget);
        final _findResDeleteButton = find.byKey(Key('resetDelete'));
        expect(_findResDeleteButton, findsOneWidget);

        await _tester.enterText(_findEmail, 'test@test.de');
        await _tester.enterText(_findPassword, 'test');
        await _tester.tap(_findPrimButton);

        await _tester.pumpAndSettle();
        //See if the username was loaded corrects
        expect(find.text('Mara'),findsOneWidget);
        expect(_findPrimButton,findsOneWidget);
        await _tester.tap(_findPrimButton);

        await _tester.tap(_findResDeleteButton);
        await _tester.pumpAndSettle();
        await _tester.tap(find.byKey(Key('zurück')));
        await _tester.pumpAndSettle();
        await _tester.tap(_findResDeleteButton);
        await _tester.pumpAndSettle();
        await _tester.tap(find.byKey(Key('zurücksetzen')));
        await _tester.pumpAndSettle();
        final _findWarningMail = find.text('E-Mail Adresse darf nicht leer sein');
        final _findWarningPassword = find.text('Passwort darf nicht leer sein');
        expect(_findWarningMail,findsOneWidget);
        expect(_findWarningPassword,findsOneWidget);

    });
    //Group ends here
  });
}

//Stuff needed for mocking Firestore calls
class MockDocumentReference extends Mock implements DocumentReference {}
class MockFirestore extends Mock implements Firestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockAuthenticator extends Mock implements FirebaseAuth {}
class MockFireUser extends Mock implements FirebaseUser {}