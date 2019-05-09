import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/utilities/firebase.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';
import 'package:hundetage/erlebnisse.dart';
import 'package:hundetage/main_screen.dart';
import 'package:image_test_utils/image_test_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hundetage/utilities/authentication.dart';
import 'package:hundetage/adventures.dart';
import 'package:hundetage/login.dart';
import 'dart:io';
import 'package:hundetage/utilities/json.dart';
import 'package:flutter/services.dart';


//Stuff needed for mocking Firestore calls
class MockDocumentReference extends Mock implements DocumentReference {}
class MockFirestore extends Mock implements Firestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockAuthenticator extends Mock implements FirebaseAuth {}
class MockFireUser extends Mock implements FirebaseUser {}

void main() {
  group('Tests involving Firebase', () {
    //Mocks calls to the application directory
    setUpAll(() async {
      // Create a temporary directory to work with
      final directory = await Directory.systemTemp.createTemp();

      // Mock out the MethodChannel for the path_provider plugin
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        // If you're getting the apps documents directory, return the path to the
        // temp directory on the test environment instead.
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return directory.path;
        }
        return null;
      });
    });

    //Mock class-instances needed in all tests involving classes initialized from Firebase
    final Firestore mockFirestore = MockFirestore();
    final MockFireUser mockFireUser = MockFireUser();
    final MockAuthenticator mockFireAuth = MockAuthenticator();
    final Authenticator _testAuth = new Authenticator(firebaseAuth: mockFireAuth);

    final CollectionReference mockCollectionReference = MockCollectionReference();

    final DocumentSnapshot mockDocumentSnapshotGendering = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotErlebnisse = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotVersions = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotUser = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotAbenteuer = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotAbenteuerMetadata = MockDocumentSnapshot();

    final DocumentReference mockDocumentReferenceGendering = MockDocumentReference();
    final DocumentReference mockDocumentReferenceErlebnisse = MockDocumentReference();
    final DocumentReference mockDocumentReferenceVersions = MockDocumentReference();
    final DocumentReference mockDocumentReferenceUser = MockDocumentReference();
    final DocumentReference mockDocumentReferenceAbenteuer = MockDocumentReference();
    final QuerySnapshot mockQuerySnapshot = MockQuerySnapshot();

    //Mock the collection
    when(mockFirestore.collection('general_data')).thenReturn(mockCollectionReference);
    //Mock both documents
    when(mockCollectionReference.document('gendering')).thenReturn(mockDocumentReferenceGendering);
    when(mockDocumentReferenceGendering.get()).thenAnswer((_) async => mockDocumentSnapshotGendering);
    when(mockDocumentSnapshotGendering.data).thenReturn(genderingMockData);

    when(mockCollectionReference.document('erlebnisse')).thenReturn(mockDocumentReferenceErlebnisse);
    when(mockDocumentReferenceErlebnisse.get()).thenAnswer((_) async => mockDocumentSnapshotErlebnisse);
    when(mockDocumentSnapshotErlebnisse.data).thenReturn(erlebnisseMockData);

    when(mockCollectionReference.document('firebase_versions')).thenReturn(mockDocumentReferenceVersions);
    when(mockDocumentReferenceVersions.get()).thenAnswer((_) async => mockDocumentSnapshotVersions);
    when(mockDocumentSnapshotVersions.data).thenReturn(versionData);

    when(mockFirestore.collection('user_data')).thenReturn(mockCollectionReference);
    when(mockCollectionReference.document('hQtzTZdHkQde3dUxyZQ3EkzxYYn1')).thenReturn(mockDocumentReferenceUser);
    when(mockDocumentReferenceUser.get()).thenAnswer((_) async => mockDocumentSnapshotUser);
    when(mockDocumentSnapshotUser.data).thenReturn(testHeld.values);

    when(mockFirestore.collection('abenteuer')).thenReturn(mockCollectionReference);
    when(mockFirestore.collection('abenteuer_metadata')).thenReturn(mockCollectionReference);
    when(mockCollectionReference.snapshots()).thenAnswer((_) => Stream.fromIterable([mockQuerySnapshot]));
    when(mockQuerySnapshot.documents).thenReturn([mockDocumentSnapshotAbenteuerMetadata]);
    when(mockCollectionReference.document('Raja')).thenReturn(mockDocumentReferenceAbenteuer);
    when(mockDocumentReferenceAbenteuer.get()).thenAnswer((_) async => mockDocumentSnapshotAbenteuer);
    when(mockDocumentSnapshotAbenteuer.data).thenReturn(adventure);
    when(mockDocumentSnapshotAbenteuerMetadata.data).thenReturn(adventureMetadata);

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

    testWidgets('Test Erlebnisse Screen', (WidgetTester _tester) async {
      provideMockedNetworkImages(() async {
        Widget _widget = StaticTestWidget(returnWidget: Erlebnisse(generalData: generalData,
        hero: testHeld, substitution: substitutions,));
        await _tester.pumpWidget(_widget);

        //See if everything looks right
        expect(find.text('Erlebnisse'), findsOneWidget);
        expect(find.byType(CircleAvatar), findsNWidgets(2));
        expect(find.byType(ClipPath), findsOneWidget);
        expect(find.byType(GridTile), findsOneWidget);

        //Test the pop-up
        final _button = find.byType(MaterialButton);
        expect(_button, findsOneWidget);
        await _tester.tap(_button);
        await _tester.pumpAndSettle();
        //See if pop-up is there
        expect(find.byType(SimpleDialog), findsOneWidget);

        //See if the pop-up looks right
        String _checkText = testHeld.geschlecht=='w'
            ?'Sie ist eine wahre Heldin.'
            :'Er ist ein wahrer Held.';
        expect(find.text(_checkText), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));
      });
    });

    testWidgets('Test Adventure Selection', (WidgetTester _tester) async {
      provideMockedNetworkImages(() async {

        AbenteuerAuswahl _widget = AbenteuerAuswahl(firestore: mockFirestore, imageHeight: 200.0,
        updateHero: (_) => null, substitution: substitutions, hero: testHeld, generalData: generalData,);
        await _tester.pumpWidget(StaticTestWidget(returnWidget: _widget));
        await _tester.pumpAndSettle();

        //Check if one grid-tile was added
        var _findTile = find.byType(GridTile);
        expect(_findTile, findsOneWidget);
        final _image = find.byType(Image);
        expect(_image, findsOneWidget);
        final _button = find.byType(MaterialButton);
        expect(_button, findsOneWidget);
        //Just test tapping the button here - we need an integration test
        //to actually test going to the next screen
        await _tester.tap(_button);
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

    //TODO: mock http-request
    //testWidgets('Test splash screen', (WidgetTester _tester) async {
    //  SplashScreen _widget = new SplashScreen();
    //  await _tester.pumpWidget(_widget);
    //  final _findImage = find.byType(Image);
    //  expect(_findImage, findsOneWidget);
    //  await _tester.pump();
    //  final _findText = find.byKey(Key('loadingText'));
    //  expect(_findText, findsOneWidget);
    //  expect(find.byType(CircularProgressIndicator), findsOneWidget);
    //  });

    test('Load User from Firebase', () async{
      //Make sure we don't just get the same values we put in
      Held _tmpHeld = Held.initial();

      _tmpHeld = await _tmpHeld.load(signedIn: true, firestore: mockFirestore, authenticator: _testAuth);
      expect(_tmpHeld.values, testHeld.values);
    });

    testWidgets('Test login screen', (WidgetTester _tester) async {
        StaticTestWidget _widget = StaticTestWidget(returnWidget: LoginSignUpPage(
            authenticator: _testAuth, hero: testHeld,
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

    testWidgets('Test loading page', (WidgetTester _tester) async {
      StaticTestWidget _widget = StaticTestWidget(returnWidget: StoryLoadingScreen(updateHero: (_) => null,
          hero: testHeld, firestore: mockFirestore, generalData: generalData,
          geschichte: testGeschichte, substitution: substitutions));

      await _tester.pumpWidget(_widget);
      expect(find.byKey(Key('loadingText')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      });

    test('Test loading story data', () async{
      Geschichte _geschichte = new Geschichte.fromMap(adventureMetadata);
      _geschichte = await loadGeschichte(firestore: mockFirestore, geschichte: _geschichte);

      List<String> _keys = _geschichte.screens[0].keys.toList();

      //Check if all data was returned correctly and the story is initialized as it should
      for(int i=0;i<_keys.length;i++){
        expect(_geschichte.screens[0][_keys[i]], adventure['0'][_keys[i]]);
        expect(_geschichte.screens[1][_keys[i]], adventure['1'][_keys[i]]);
      }
    });

    testWidgets('Test adventure screen', (WidgetTester _tester) async {
      Geschichte _geschichte = new Geschichte.fromMap(adventureMetadata);
      _geschichte = await loadGeschichte(firestore: mockFirestore, geschichte: _geschichte);
      GeschichteMainScreen _widget = GeschichteMainScreen(updateHero: (_) => null,
          hero: testHeld, geschichte: _geschichte, substitution: substitutions,
      generalData: generalData,);

      await _tester.pumpWidget(MaterialApp(home: _widget));
      await _tester.pumpAndSettle();
      expect(find.byType(CircleAvatar), findsNWidgets(2));
    });

    test('Test text substitution', () async {
      String _textOut = substitutions.applyAllSubstitutions('#ErSie ist #eineine #wahrerwahre #HeldHeldin.');
      String _checkText = testHeld.geschlecht=='w'
          ?'Sie ist eine wahre Heldin.'
          :'Er ist ein wahrer Held.';
      expect(_textOut, _checkText);
    });

    testWidgets('Test Text', (WidgetTester _tester) async {
      Geschichte _geschichte = new Geschichte.fromMap(adventureMetadata);
      _geschichte = await loadGeschichte(firestore: mockFirestore, geschichte: _geschichte);
      StaticTestWidget _widget =  StaticTestWidget(returnWidget: StoryText(hero: testHeld, imageHeight: 100.0,
          geschichte: _geschichte, substitution: substitutions, updateHeroStory: ({Held newHero}) => null,
      generalData: generalData));

      String _checkText = testHeld.geschlecht=='w'
          ?'Sie ist eine wahre Heldin.'
          :'Er ist ein wahrer Held.';
      await _tester.pumpWidget(_widget);
      await _tester.pumpAndSettle();

      //See if the text widget is there at all
      expect(find.byType(Text), findsNWidgets(3));
          //See if the text widgets are correct
      expect(find.text(_checkText),findsOneWidget);
      final _forwardButton = find.text('test0');
      expect(_forwardButton,findsOneWidget);
      expect(find.text('test1'),findsOneWidget);

      //Go to next page
      await _tester.tap(_forwardButton);
      await _tester.pumpAndSettle();

      //Check text widgets on newly-loaded page
      expect(find.byType(Text), findsNWidgets(2));
      expect(find.text(_checkText),findsOneWidget);
      final _backButton = find.text('new page');
      expect(find.text('new page'),findsOneWidget);

      //Go back to first page
      await _tester.tap(_backButton);
      await _tester.pumpAndSettle();

      //See if pop-up is there
      expect(find.byType(SimpleDialog), findsOneWidget);

      //Check text widgets on first page after it was loaded again
      //There is one more text now because of the pop-up that is still open
      //Don't really need to test closing it here as it is flutter standart
      //so this should be fine...
      expect(find.byType(Text), findsNWidgets(4));
      //See if the text widgets are correct
      expect(find.text(_checkText),findsNWidgets(2));
      expect(_forwardButton,findsOneWidget);
      expect(find.text('test1'),findsOneWidget);

    });

    test('Test loading version data', () async{
      VersionController _versionController = await loadVersionInformation(firestore: mockFirestore);

      //Check if all data was returned correctly
      expect(_versionController.gendering,versionTestData['gendering']);
      expect(_versionController.erlebnisse,versionTestData['erlebnisse']);
      //Check story-versions
      Map<String,double> _storyVersions = _versionController.stories;
      List<String> _keys = _storyVersions.keys.toList();
      for(int i=0;i<_keys.length;i++){
        expect(_storyVersions[_keys[i]],versionTestData[_keys[i]]);
      }
    });

    test('Test offline general data loading', () async {{
      //TODO: Add test for no-data warning - needs to be widget test
      DataLoader _dataLoader = new DataLoader(firestore: mockFirestore,
      authenticator: _testAuth, fakeOnlineMode: false);

      //We add the local data and try to load it
      writeLocalUserData(testHeld);
      writeLocalGeneralData(generalData);
      await _dataLoader.loadData();

      expect(_dataLoader.substitution, isNotNull);
      expect(_dataLoader.generalData.values['erlebnisse'], erlebnisseTestData);
      expect(_dataLoader.generalData.values['gendering'], genderingTestData);
    }
    });

    test('Test online general data loading', () async {{
      DataLoader _dataLoader = new DataLoader(firestore: mockFirestore,
          authenticator: _testAuth, testVersionController:versionController, fakeOnlineMode: true);

      //Test loading with no local data present
      //First we delete all local data
      await deleteLocalVersionData();
      await deleteLocalGeneralData();

      await _dataLoader.loadData();
      expect(_dataLoader.substitution, isNotNull);
      expect(_dataLoader.generalData.values['erlebnisse'], erlebnisseTestData);
      expect(_dataLoader.generalData.values['gendering'], genderingTestData);

      //We add the local data and try to load it
      writeLocalUserData(testHeld);
      writeLocalGeneralData(generalData);
      //Update the local versions and see if they are updated
      VersionController versionControllerLower = VersionController.fromMap(versionDataLower);
      writeLocalVersionData(versionControllerLower);

      await _dataLoader.loadData();
      expect(_dataLoader.substitution, isNotNull);
      expect(_dataLoader.generalData.values['erlebnisse'], erlebnisseTestData);
      expect(_dataLoader.generalData.values['gendering'], genderingTestData);
      expect(_dataLoader.versionController.values, versionController.values);
    }
    });
    //Group ends here
  });
}