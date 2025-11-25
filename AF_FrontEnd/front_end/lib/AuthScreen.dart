import 'package:flutter/material.dart';
import 'package:front_end/login_page_ui.dart';
import 'package:front_end/singup_page_ui.dart';
class AuthScreen extends StatefulWidget {
const AuthScreen({super.key});

@override
State<AuthScreen> createState() => _AuthScreenState();

}

class _AuthScreenState extends State<AuthScreen>{
  bool _showLoginPage = true;

  void _toggleView(){
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
          child: LoginPageUI(
            onToggleView: _toggleView,
          ),
          ),

          Visibility(
            visible: !_showLoginPage,
            maintainState: true,
            child: SignupPageUI(
              onToggleView: _toggleView,
            ),
          )
        ],
      ),
    );
  }


}