import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget{
  final VoidCallback onToggleView;
  const LoginPage({super.key, required this.onToggleView});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

bool _hidePassword = true;
final bool _isLoading = false;

static const String emailPattern = 
  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+$";

final RegExp emailRegex = RegExp(emailPattern);

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility(){
    setState(() {
      _hidePassword = !_hidePassword;
    });
  }

  String? _validateEmail(String? value){
    if (value == null || value.isEmpty){
      return 'Please enter Your Email';
    }

    if(!emailRegex.hasMatch(value)){
      return 'Please Enter Valid Email Address';

    }
    return null;

  }

  String? _validatePassword(String? value){
    if (value == null || value.isEmpty ){
      return 'Please Enter Your Pssword';
    }
    if (value.length < 6){
      return 'Password Must Be At Least 6 Characters Long';

    }
    return null;
  }

  
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }





}