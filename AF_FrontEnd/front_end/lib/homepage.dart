import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:front_end/markets_screen.dart';


class AscentHomepage extends StatefulWidget{
  @override
  State<AscentHomepage> createState() => _AscentHomepageUIState();
}

class _AscentHomepageUIState extends State<AscentHomepage>{

  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[


    SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),

                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('My Activity And Alerts',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    ),

                    Text('You have 2 new updates on funded projects',
                    style: TextStyle(fontSize: 14),
                    ),

                    Text('Your project Ecofarm has reached 75% funding',
                    style: TextStyle(fontSize: 14),
                    ),

                    Text('*1 Message from Project X.',
                    style: TextStyle(fontSize: 14),
                    ),

                    SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text('Tap for full details',
                      style: TextStyle(fontSize: 12,
                      color: Colors.blueAccent,
                      fontStyle: FontStyle.italic
                      ),
                      ),
                    ),


                  ],
                ),
                
              ),
              
            Builder(
              builder: (context){

                final screenHeight = MediaQuery.of(context).size.height;
                final desiredHeight = screenHeight * 0.45;

                return SizedBox(
                  height: desiredHeight,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ]
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Column(children: [Icon(Icons.lightbulb_outline, size: 30,color: Colors.amber,), Text('Tech')],),
                        Column(children: [Icon(Icons.palette_outlined, size: 30,color: Colors.blue,), Text('Arts')],),
                        Column(children: [Icon(Icons.groups_outlined, size: 30,color: Colors.blueGrey,), Text('Social')],),
                        Column(children: [Icon(Icons.money_outlined, size: 30,color: Colors.green,), Text('Finance')],),

                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Text(
                      'Discover 150+ projects!',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Browse All Categories ->',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontStyle: FontStyle.italic,

                        ),
                      ),
                    )
                  ],
                ),
              ),
                );
              }
            ),
            


              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),

                    ),
                  ],

                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Market Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),

                    SizedBox(
                      height: 8,
                    ),

                    Text(
                      'XYZ Token: \$0.05 (+2.1%)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'View Detailed Analytics ->',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purpleAccent,
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ),

                  ],
                ),
              )
            ],
            
          ),
        ),

    
 
    MarketsScreen(),

    
    Center(child: Text('Teams Content'), 

    ),

    Center(child: Text('Wallet Content'), 
    ),
  ];

  void _onItemtapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
  
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        leading:  Image.asset('assets/icon/ascent_icon.png', height: 50,),
        backgroundColor: Colors.white ,

      



        actions: <Widget>[
          IconButton(onPressed: (){}, icon: Icon(Icons.search)),
          IconButton(onPressed: (){}, icon: Icon(Icons.person,))
        ],

        

      

        
        ), 


        body: _widgetOptions.elementAt(_selectedIndex),

        bottomNavigationBar: BottomNavigationBar(
          items: const<BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.black,),
          label: 'Home',
        
          ),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up_sharp, color: Colors.black,),
          label: 'Markets',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group, color: Colors.black,),
          label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet, color: Colors.black,),
          label: 'Wallet'),
          


        ],
        currentIndex: _selectedIndex,
        onTap: _onItemtapped,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        type: BottomNavigationBarType.fixed,
        ),

          
  

      
    );
  }

}