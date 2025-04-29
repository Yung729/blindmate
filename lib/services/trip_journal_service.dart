import 'package:cloud_firestore/cloud_firestore.dart';

class UserTripJournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user's trip journal posts

  Future<List<Map<String, dynamic>>> fetchUserTripJournals(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('shared_content')
          .where('userId', isEqualTo: userId)
          .where('postType', isEqualTo: 'tripJournal')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'tripJournals': (data['tripJournals'] as List?)?.map((journal) {
            return {
              ...journal,
              'date': (journal['date'] as Timestamp).toDate(),
            };
          }).toList() ?? [],
        };
      }).where((post) => post['tripJournals'].isNotEmpty).toList();
    } catch (e) {
      print('Error fetching user trip journals: $e');
      return [];
    }
  }

  // Format trip journals for display
  List<Map<String, dynamic>> formatTripJournals(List<Map<String, dynamic>> journals) {
    return journals.map((journal) {
      return {
        'location': journal['location'] ?? '',
        'description': journal['description'] ?? '',
        'date': journal['date'] as DateTime,
        'activities': List<String>.from(journal['activities'] ?? []),
      };
    }).toList();
  }
}