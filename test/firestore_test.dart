import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hundetage/firebase_utilities.dart';
import 'package:hundetage/main.dart';
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

    test('Test GeneralData Class', () async{
    //Data used for testing - we will return this in our mocked request to Firebase
      Map<String,Map<String,String>> _genderingTestData = {
        'eineine':{'m': 'ein', 'w': 'eine'},
        'HeldHeldin':{'m': 'Held', 'w': 'Heldin'},
        'ersie':{'m': 'er', 'w': 'sie'}};
      Map<String,Map<String,String>> _erlebnisseTestData = {
        'besteFreunde':{'text': 'Some test Text', 'image': 'https://firebasestorage.googleapis.com/...'},
        'alteFrau':{'text': 'Some other test Text', 'image': 'https://firebasestorage.googleapis.com/...'}};

      //Mock the collection
      when(mockFirestore.collection('general_data')).thenReturn(mockCollectionReference);
      //Mock both documents
      when(mockCollectionReference.document('gendering')).thenReturn(mockDocumentReferenceA);
      when(mockDocumentReferenceA.get()).thenAnswer((_) async => mockDocumentSnapshotA);
      when(mockDocumentSnapshotA.data).thenReturn(_genderingTestData);
      when(mockCollectionReference.document('erlebnisse')).thenReturn(mockDocumentReferenceB);
      when(mockDocumentReferenceB.get()).thenAnswer((_) async => mockDocumentSnapshotB);
      when(mockDocumentSnapshotB.data).thenReturn(_erlebnisseTestData);
      //Initialize the class
      GeneralData _generalData = await loadGeneraldata(mockFirestore);
      
      //See if initialization worked correctly
      expect(_generalData.gendering, _genderingTestData);
      expect(_generalData.erlebnisse, _erlebnisseTestData);
    });
  });
}

//Stuff needed for mocking Firestore calls
class MockDocumentReference extends Mock implements DocumentReference {}
class MockFirestore extends Mock implements Firestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}