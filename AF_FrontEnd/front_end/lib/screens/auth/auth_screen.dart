import 'package:flutter/material.dart';
import 'package:front_end/screens/auth/login_screen.dart';
import 'package:front_end/screens/auth/signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLoginPage = true;

  void _toggleView() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showLoginPage ? 'Login' : 'SignUp'),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Visibility(
            visible: _showLoginPage,
            maintainState: true,
            child: LoginScreen(
              onToggleView: _toggleView,
            ),
          ),
          Visibility(
            visible: !_showLoginPage,
            maintainState: true,
            child: SignupScreen(
              onToggleView: _toggleView,
            ),
          )
        ],
      ),
    );
  }
}
