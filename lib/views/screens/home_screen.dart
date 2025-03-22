import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/home_state.dart';
import '../../viewmodels/dataBinding/home_data_binding.dart';
import '../../viewmodels/eventHandlers/home_event_handler.dart';
import 'matching_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeEventHandler _homeEventHandler;

  @override
  void initState() {
    super.initState();
    final homeState = context.read<HomeState>();
    final dataBinding = HomeDataBinding();
    _homeEventHandler = HomeEventHandler(homeState: homeState, dataBinding: dataBinding);
    _homeEventHandler.loadUserData();
  }

  // 🔹 Show Pop-up with Matching Options
  void _showMatchingOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Matching Type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startRandomMatching();
              },
              child: const Text("Random Matching"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Bottle Matching"),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Start Random Matching
  void _startRandomMatching() {
    final currentUser = context.read<HomeState>().currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchingScreen(user: currentUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<HomeState>(
          builder: (context, homeState, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (homeState.currentUser != null)
                  Text(
                    "Welcome, ${homeState.currentUser!.name}!",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showMatchingOptions,
                  child: const Text("Start Matching"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
