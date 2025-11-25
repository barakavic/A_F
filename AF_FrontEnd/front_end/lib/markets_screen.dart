import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:front_end/homepage.dart';

class MarketsScreen extends StatefulWidget{
  @override

  State <MarketsScreen> createState() => _MarketsScreenUI();
}

class _MarketsScreenUI extends State<MarketsScreen>{

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.00),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Ventures....',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,

                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
                onChanged: (value){
                  
                },


              )),

              const SizedBox(
                width: 10,

              ),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12.0),

                ),

                child: IconButton(onPressed: (){
                  showModalBottomSheet(context: context, 
                  builder: (BuildContext context){
                    return Container(
                      height: 200,
                      child: Center(
                        child: Text('Filtering Options Go Here!'),
                      ),
                    );
                  });
                }, icon: Icon(Icons.filter_list),
                tooltip: 'Filter',
                
                ),
                
              ),
            ],
          )
          
        ],

      ),

    );
    
  }
  
}