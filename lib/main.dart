import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/viewmodels/state/matching_state.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'views/screens/login_screen.dart';
import 'views/navigation_controller.dart';

// ViewModels
import 'viewmodels/state/chat_state.dart';
import 'viewmodels/state/bottle_note_state.dart';
import 'viewmodels/state/sharing_state.dart';
import 'viewmodels/state/create_post_state.dart';
import 'viewmodels/state/music_player_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatState()),
        ChangeNotifierProvider(create: (_) => MatchingState()),
        ChangeNotifierProvider(create: (_) => BottleNoteState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => SharingState()),
        ChangeNotifierProvider(create: (_) => CreatePostState()),
        ChangeNotifierProvider(create: (_) => MusicPlayerState()),
        // Add more providers as needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blind Mate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const NavigationController(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const NavigationController(); // ✅ You can wrap with more providers here if needed.
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
