import '../../services/matching_service.dart';
import '../state/matching_state.dart';
import '../../models/dataModels/user_model.dart';

class MatchingEventHandler {
  final MatchingState matchingState;
  final MatchingService _matchingService = MatchingService();

  MatchingEventHandler({required this.matchingState});

  Future<void> updateUserStatus(String userId, String status) async {
    await _matchingService.updateUserStatus(userId, status);
    matchingState.updateStatus(status); // No need for Future.microtask
  }

  Future<void> startMatching(UserModel user) async {
     matchingState.clear();
     matchingState.updateStatus('waiting');
    String? chatRoomId = await _matchingService.startMatching(user);
    if (chatRoomId != null) {
       matchingState.setChatRoomId(chatRoomId);
    }
  }

  void listenForMatch(String userId) {
    _matchingService.listenForMatch(userId, (chatRoomId) {
       matchingState.setChatRoomId(chatRoomId);
    });
  }
}
