import 'package:accounting_app2/new.dart';
import 'package:accounting_app2/try.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'Magdy.dart';
import 'firebase_options.dart';
import 'listView.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp(


        MaterialApp(
        home: NestedListViewDemo(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp(changeNotifierProvider, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: NestedListViewDemo(),
    );
  }
}

class MyInputScreen extends StatefulWidget {
  @override
  _MyInputScreenState createState() => _MyInputScreenState();
}

class _MyInputScreenState extends State<MyInputScreen> {
  final TextEditingController _dataController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _dataController,
              decoration: InputDecoration(labelText: 'Enter Data'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if( _dataController.text.isNotEmpty){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp2()),
                  );
                  FirebaseService().addData(_dataController.text, 1000, "ورقيات",10,10,100,true);
                }
                else{
                  Fluttertoast.showToast(
                      msg: "Please enter a valid value",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0
                  );
                }


              },
              child: Text('Store Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseService {
final DatabaseReference ref = FirebaseDatabase.instance.ref().child("users");

FirebaseService() {
  // Initialize Firebase in the constructor
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> addData(String name, int number, String description ,int quantity,int price ,int totalPrice,bool status) async {
  await ref.child(name).push().set({
    'name': name,
    'number': number,
    'description': description,
    'quantity': quantity,
    'price': price,
    'totalPrice': totalPrice,
    'status': status,


  });
}
}

