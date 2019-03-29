import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:hundetage/firebase_utilities.dart';
import 'package:hundetage/main.dart';
import 'utilities.dart';
import 'package:hundetage/main_screen.dart';
import 'package:image_test_utils/image_test_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Firebase unit tests', () {
    //Mock class-instances needed in all tests involving classes initialized from Firebase
    final Firestore mockFirestore = MockFirestore();
    final CollectionReference mockCollectionReference = MockCollectionReference();
    final DocumentSnapshot mockDocumentSnapshotA = MockDocumentSnapshot();
    final DocumentSnapshot mockDocumentSnapshotB = MockDocumentSnapshot();
    final DocumentReference mockDocumentReferenceA = MockDocumentReference();
    final DocumentReference mockDocumentReferenceB = MockDocumentReference();
    final QuerySnapshot mockQuerySnapshot = MockQuerySnapshot();

    test('Test GeneralData Class', () async{
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

      //Mock the collection
      when(mockFirestore.collection('general_data')).thenReturn(mockCollectionReference);
      //Mock both documents
      when(mockCollectionReference.document('gendering')).thenReturn(mockDocumentReferenceA);
      when(mockDocumentReferenceA.get()).thenAnswer((_) async => mockDocumentSnapshotA);
      when(mockDocumentSnapshotA.data).thenReturn(_genderingMockData);
      when(mockCollectionReference.document('erlebnisse')).thenReturn(mockDocumentReferenceB);
      when(mockDocumentReferenceB.get()).thenAnswer((_) async => mockDocumentSnapshotB);
      when(mockDocumentSnapshotB.data).thenReturn(_erlebnisseMockData);
      //Initialize the class
      GeneralData _generalData = await loadGeneralData(mockFirestore);
      
      //See if initialization worked correctly
      expect(_generalData.gendering, genderingTestData);
      expect(_generalData.erlebnisse, erlebnisseTestData);
    });

    testWidgets('Test Adventure Selection', (WidgetTester _tester) async {
      provideMockedNetworkImages(() async {
        Map<String, dynamic> _adventure1 = {
          'name': 'Reja', 'version': 0.6, 'image': 'https...'};

        //Mock the collection
        when(mockFirestore.collection('abenteuer')).thenReturn(
            mockCollectionReference);
        //Mock the stream
        when(mockCollectionReference.snapshots())
            .thenAnswer((_) => Stream.fromIterable([mockQuerySnapshot]));
        when(mockQuerySnapshot.documents).thenReturn([mockDocumentSnapshotA]);
        when(mockDocumentSnapshotA.data).thenReturn(_adventure1);

        AbenteuerAuswahl _widget = AbenteuerAuswahl(firestore: mockFirestore);
        await _tester.pumpWidget(StaticTestWidget(returnWidget: _widget));
        await _tester.pumpAndSettle();

        //Check if one grid-tile was added
        var _findTile = find.byType(GridTile);
        expect(_findTile, findsOneWidget);
        final _image = find.byType(Image);
        expect(_image, findsOneWidget);
      });
    });
  });
}

//Stuff needed for mocking Firestore calls
class MockDocumentReference extends Mock implements DocumentReference {}
class MockFirestore extends Mock implements Firestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}