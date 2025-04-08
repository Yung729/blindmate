import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
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
      body: Stack(
        children: [
          // Set the sea background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/sea_background.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Center the content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.recycling,
                  size: 100,
                  color: Colors.black,
                ),
                const SizedBox(height: 20),
                Consumer<HomeState>(
                  builder: (context, homeState, child) {
                    return homeState.currentUser != null
                        ? Text(
                            "Welcome, ${homeState.currentUser!.name}!",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          )
                        : const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startRandomMatching,
                  child: const Text("Random Matching"),
                ),
              ],
            ),
          ),
          // Add the Lottie animation for the bottle button at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bottle message!"),
                    ),
                  );
                },
                child: Lottie.asset(
                  'assets/bottle.json',
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
