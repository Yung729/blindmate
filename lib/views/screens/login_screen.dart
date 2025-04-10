import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/auth_state.dart';
import '../../viewmodels/eventHandlers/auth_event_handler.dart';
import '../../viewmodels/dataBinding/auth_data_binding.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AuthEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    final authState = Provider.of<AuthState>(context, listen: false);
    final authService = AuthService();
    final authBinding = AuthDataBinding(authService);
    _eventHandler = AuthEventHandler(authState, authBinding);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Welcome Back",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Consumer<AuthState>(
          builder: (context, authState, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword 
                            ? Icons.visibility 
                            : Icons.visibility_off),
                          onPressed: () => setState(() => 
                            _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 50,
                      child: authState.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _eventHandler.onLoginPressed(
                              context,
                              _emailController.text,
                              _passwordController.text,
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Login"),
                          ),
                    ),
                    if (authState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
