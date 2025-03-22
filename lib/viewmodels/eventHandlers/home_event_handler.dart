import '../state/home_state.dart';
import '../dataBinding/home_data_binding.dart';

class HomeEventHandler {
  final HomeState homeState;
  final HomeDataBinding dataBinding;

  HomeEventHandler({required this.homeState, required this.dataBinding});

  Future<void> loadUserData() async {
    final user = await dataBinding.fetchUserData();
    homeState.setCurrentUser(user);
  }
}