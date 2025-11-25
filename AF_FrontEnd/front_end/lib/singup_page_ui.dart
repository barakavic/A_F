import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class SignupPageUI  extends StatefulWidget{
  final VoidCallback onToggleView;
  
  const SignupPageUI({super.key, required this.onToggleView});
  @override
  State<SignupPageUI> createState() => _SignupPageUIState();




 }

 class _SignupPageUIState extends State<SignupPageUI>{
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  
  @override
  void dispose(){
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(children: <Widget>[
  /*      const Icon(
          Icons.person_add,
          size: 120,
          color: Colors.teal
          
        ),

        const SizedBox(height: 20.0),

        Text('MarksMan',
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold
        ),
        ),
*/

        Image.asset('assets/icon/ascent_icon.png',
            height: 100),

        const SizedBox(height: 30.0),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter Your Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),

        SizedBox(
          height: 10.0,
        ),

        

        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Username',
            prefixIcon: Icon(Icons.person)

          ),

        ),
        const SizedBox(height: 10.0),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility
          ),
          onPressed: (){
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          ),

          labelText: 'Password',
          hintText: 'Create a password'
          ),
          
        ),
        const SizedBox(height: 10.0),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(onPressed: (){
              setState(() {
                _obscurePassword = !_obscurePassword;
                
              });
            }, icon: Icon(
              _obscurePassword? Icons.visibility_off : Icons.visibility
            ))

          ),
        ),



        const SizedBox(height: 10.0),

        SizedBox(
          width: double.infinity,
        
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
          textStyle: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          onPressed: (){
          

          print('SignUp Button tapped');
          print('Email: ${_emailController.text}');

        }, 
        child: const Text('Sign Up')
        ),
        ),


        const SizedBox(height: 10.0),
        TextButton(
        onPressed: widget.onToggleView, 
        child: const Text(
          'Already have an account? Login',
          style: TextStyle(color: Colors.orangeAccent),
          
        ))
        

      ],),

    ),);
  }



 }