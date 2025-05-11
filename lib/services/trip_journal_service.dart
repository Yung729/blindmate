import 'package:cloud_firestore/cloud_firestore.dart';

class UserTripJournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user's trip journal posts
  Future<List<Map<String, dynamic>>> fetchUserTripJournals(
    String userId,
  ) async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('shared_content')
              .where('userId', isEqualTo: userId)
              .where('postType', isEqualTo: 'tripJournal')
              .get();

      // First, process all posts and ensure each trip journal has a tripId
      final List<Map<String, dynamic>> processedPosts = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Parse the post timestamp
            DateTime? postTimestamp;
            if (data['timestamp'] != null) {
              if (data['timestamp'] is Timestamp) {
                postTimestamp = (data['timestamp'] as Timestamp).toDate();
              } else if (data['timestamp'] is String) {
                try {
                  postTimestamp = DateTime.parse(data['timestamp'] as String);
                } catch (_) {
                  // If parsing fails, use current time as fallback
                  postTimestamp = DateTime.now();
                }
              }
            } else {
              // If timestamp is missing, use current time as fallback
              postTimestamp = DateTime.now();
            }
            
            return {
              ...data,
              'id': doc.id,
              'timestamp': postTimestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'tripJournals':
                  (data['tripJournals'] as List?)?.map<Map<String, dynamic>>((
                    journal,
                  ) {
                    final journalMap = Map<String, dynamic>.from(
                      journal as Map,
                    );
                    
                    // Ensure each journal has a tripId
                    if (!journalMap.containsKey('tripId')) {
                      journalMap['tripId'] = '${doc.id}_${journalMap.hashCode}';
                    }
                    
                    return {
                      ...journalMap,
                      'postTimestamp': postTimestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
                      'date': () {
                        final rawDate = journalMap['date'];
                        if (rawDate is Timestamp) return rawDate.toDate();
                        if (rawDate is DateTime) return rawDate;
                        if (rawDate is String) {
                          try {
                            return DateTime.parse(rawDate);
                          } catch (_) {
                            return null;
                          }
                        }
                        return null;
                      }(),
                    };
                  }).toList() ??
                  <Map<String, dynamic>>[],
            };
          })
          .where(
            (post) =>
                post['tripJournals'].isNotEmpty &&
                post['visibility'] != 'deleted',
          )
          .toList();

      // Track which tripIds have been seen and in which post
      final Map<String, String> tripIdToPostId = {};
      
      // Final list of posts with deduplicated trip journals
      final List<Map<String, dynamic>> finalPosts = [];
      
      // Process each post to handle cross-post duplicates
      for (final post in processedPosts) {
        final String postId = post['id'];
        final List<Map<String, dynamic>> uniqueJournalsForPost = [];
        
        // Check each trip journal in this post
        for (final journal in post['tripJournals'] as List<Map<String, dynamic>>) {
          final String tripId = journal['tripId'] as String;
          
          // If this tripId has been seen in another post, skip it
          if (tripIdToPostId.containsKey(tripId) && tripIdToPostId[tripId] != postId) {
            print('Skipping duplicate tripId $tripId found in post $postId (already in ${tripIdToPostId[tripId]})');
            continue;
          }
          
          // Otherwise, mark this tripId as belonging to this post
          tripIdToPostId[tripId] = postId;
          uniqueJournalsForPost.add(journal);
        }
        
        // Only add the post if it still has trip journals after deduplication
        if (uniqueJournalsForPost.isNotEmpty) {
          finalPosts.add({
            ...post,
            'tripJournals': uniqueJournalsForPost,
          });
        }
      }
      
      return finalPosts;
    } catch (e) {
      print('Error fetching user trip journals: $e');
      return [];
    }
  }

  // Format trip journals for display
  List<Map<String, dynamic>> formatTripJournals(
    List<Map<String, dynamic>> journals,
  ) {
    return journals.map((journal) {
      return {
        'tripId': journal['tripId'] ?? '',
        'location': journal['location'] ?? '',
        'description': journal['description'] ?? '',
        'date': journal['date'] as DateTime,
        'postTimestamp': journal['postTimestamp'] ?? DateTime.now().toIso8601String(),
        'activities': List<String>.from(journal['activities'] ?? []),
      };
    }).toList();
  }
}