import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:front_end/AuthScreen.dart';
import 'package:front_end/homepage.dart';
class LoginOptionsPage extends StatelessWidget{
  const LoginOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          const SizedBox(
            height: 350.0,
          ),

          Image.asset(
            'assets/icon/ascent_icon.png',
            height: 100,
          ),

          const SizedBox(
            height: 40,
          ),

          ElevatedButton.icon(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AuthScreen()),
            );
            
          }, 
          label: Text("Continue with Email"),
          icon: Icon(Icons.email,),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
          ),

          
          ),

          SizedBox(height: 16),

          ElevatedButton.icon(onPressed: (){},
           
          label: Text("Continue With Google"),
        

            icon: Image.asset('assets/icon/google_icon.png', width: 24, height: 24),         
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              
              side: const BorderSide(color: Colors.grey)
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          ElevatedButton.icon(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=> AscentHomepage(),));

          },
           
          label: const Text("Continue with SSO"),
          icon: Icon(Icons.key),
          style: ElevatedButton.styleFrom(
            
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          ),

          const SizedBox(height: 20),

          Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton(onPressed: (){},
               child: Text('Privacy Policy',
               style: TextStyle(color: Colors.blueGrey),)),

               TextButton(onPressed: (){}, 
               child: Text('Terms and Conditions',
               style: TextStyle(color: Colors.blueGrey),
               
               ))
            ],

            
          )


          


        ],
        
        
        
        
      ),
      

      
      ),

      
    )
    );
  }
  
}