import 'package:flutter/material.dart';
import '../pages/home_screen.dart';
import '../pages/login_screen.dart';
import '../pages/sharing_screen.dart';

class NavigationController {
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/home': (context) => const HomeScreen(),
  };

  static void navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  static void replaceWith(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }
}
