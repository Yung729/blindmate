import '../../services/matching_service.dart';
import '../../models/dataModels/user_model.dart';
import '../state/matching_state.dart';

class MatchingDataBinding {
  final MatchingService _matchingService = MatchingService();
  final MatchingState matchingState;

  MatchingDataBinding({required this.matchingState});

  Future<void> initialize(String userId) async {
    // Set up listener for matches
    _matchingService.listenForMatch(userId, (chatRoomId) {
      matchingState.setChatRoomId(chatRoomId);
      matchingState.updateStatus('in_chat');
      matchingState.setSearching(false);
    });
  }

  Future<void> startMatching(UserModel user) async {
    // Update state to indicate searching
    matchingState.clear();
    matchingState.setSearching(true);
    matchingState.updateStatus('waiting');
    
    // Call service to start matching - this will properly trigger all debug logs
    String? chatRoomId = await _matchingService.startMatching(user);
    
    // If no match was found through direct matching (unlikely but possible)
    if (chatRoomId == null) {
      // We're still in waiting state, the listener will catch any match
    }
  }

  Future<void> cancelMatching(String userId) async {
    await _matchingService.updateUserStatus(userId, 'available');
    matchingState.setSearching(false);
    matchingState.updateStatus('available');
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _matchingService.updateUserStatus(userId, status);
    matchingState.updateStatus(status);
  }
}