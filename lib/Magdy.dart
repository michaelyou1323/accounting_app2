import 'package:accounting_app2/user_details_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'Magdy.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      home: NestedListViewDemo(),
    ),
  );
}


class NestedListViewDemo extends StatefulWidget {
  @override
  _NestedListViewDemoState createState() => _NestedListViewDemoState();
}

class _NestedListViewDemoState extends State<NestedListViewDemo> {
  List<String> userNames = [];
  DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child("users");

  @override
  void initState() {
    super.initState();

    // Listen for new child additions
    _usersRef.onChildAdded.listen((event) {
      String? childName = event.snapshot.key;
      if (childName != null) {
        setState(() {
          userNames.add(childName);
        });
      }
    }, onError: (error) {
      print("Error: $error");
    });

    // Listen for changes in existing children
    _usersRef.onChildChanged.listen((event) {
      String? childName = event.snapshot.key;
      if (childName != null) {
        setState(() {
          // Update your user data here
        });
      }
    }, onError: (error) {
      print("Error: $error");
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nested ListView Demo'),
      ),
      body: PageView.builder(
        itemCount: 2,
        itemBuilder: (context, index) {
          return VerticalListViewItem(userNames: userNames);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return AddItemForm();
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class VerticalListViewItem extends StatelessWidget {
  final List<String> userNames;

  VerticalListViewItem({required this.userNames});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: userNames.length,
      itemBuilder: (context, index) {
        String userName = userNames[index];
        return ExpandableListViewItem(userName: userName);
      },
    );
  }
}

class ExpandableListViewItem extends StatefulWidget {
  final String userName;

  ExpandableListViewItem({required this.userName});

  @override
  _ExpandableListViewItemState createState() => _ExpandableListViewItemState();
}

class _ExpandableListViewItemState extends State<ExpandableListViewItem> {
  late DatabaseReference _childRef;
  List<String> childData = [];
  bool isExpanded = false;

  final String userSignature = "" ;

  @override
  void initState() {
    super.initState();
    _childRef = FirebaseDatabase.instance.reference().child("users").child(widget.userName);

    _childRef.onChildAdded.listen((event) {
      String? childNodeName = event.snapshot.key;
      if (childNodeName != null) {
        setState(() {
          childData.add(childNodeName);
        });
      }
    }, onError: (error) {
      print("Error: $error");
    });
  }

  Future<Map<String, dynamic>> fetchUserData(String userId, String userName) async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child("users").child(userName).child(userId).get();

    try {
      if (snapshot.exists) {
        Map userData = snapshot.value as Map;
        return {
          'name': userData['name'],
          'description': userData['description'],
          'number': userData['number'],
          'quantity': userData['quantity'],
          'price': userData['price'],
          'totalPrice': userData['totalPrice'],
          'status': userData['status'],
          'userSignature': userData["userSignature"] ,
        };
      }
    } catch (error) {
      print("Error: $error");
    }

    return {
      'name': 'N/A',
      'description': 'N/A',
      'number': 'N/A',
      'quantity': 'N/A',
      'price': 'N/A',
      'totalPrice': 'N/A',
      'status': 'N/A',
      'userSignature': 'N/A',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            widget.userName,
            style: TextStyle(color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
        ),
        if (isExpanded)
          ListView.builder(
            shrinkWrap: true,
            itemCount: childData.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  "     " + widget.userName + (index + 1).toString(),
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                onTap: () async {
                  Map<String, dynamic> userData = await fetchUserData(childData[index], widget.userName);
                  String name = userData['name'];
                  String description = userData['description'];
                  int number = userData['number'];
                  int quantity = userData['quantity'];
                  int price = userData['price'];
                  int totalPrice = userData['totalPrice'];
                  bool status = userData['status'];



                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserDetailsScreen(
                        name: name,
                        description: description,
                        number: number,
                        quantity: quantity,
                        price: price,
                        totalPrice: totalPrice,
                        status: status,
                        userSignature: userSignature,
                        index: index ,
                        childData: childData[index],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class AddItemForm extends StatefulWidget {
  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _numberController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _quntityController = TextEditingController();
  final String userSignature = "يوسف عدلي" ;
  bool status = false  ;


  DatabaseReference _ref = FirebaseDatabase.instance.ref().child("users");

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إضافة عميل',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'الاسم'),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _numberController,
            decoration: InputDecoration(labelText: 'المبلغ'),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'تفاصيل'),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(labelText: 'سعر القطعة'),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _quntityController,
            decoration: InputDecoration(labelText: 'الكمية'),
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    status = false;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(status == false ? Colors.grey : Colors.lightBlueAccent),
                ),
                child: Text('          عليه           '),
              ),
              SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    status = true;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(status == true ? Colors.grey : Colors.lightBlueAccent),
                ),
                child: Text('            له             '),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty ||
                  _numberController.text.isEmpty ||
                  _descriptionController.text.isEmpty ||
                  _priceController.text.isEmpty ||
                  _quntityController.text.isEmpty) {
                Fluttertoast.showToast(
                  msg: "Please enter a value in all fields",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              } else {
                int totalPrice = int.parse(_quntityController.text) * int.parse(_priceController.text);
                String name = _nameController.text;
                _ref.child(name).push().set({
                  'name': _nameController.text,
                  'number': int.parse(_numberController.text),
                  'description': _descriptionController.text,
                  'quantity': int.parse(_quntityController.text),
                  'price': int.parse(_priceController.text),
                  'totalPrice': totalPrice,
                  'status': status,
                  'userSignature': userSignature ,
                });
                Navigator.pop(context);
              }
            },
            child: Text('إضافة العميل'),
          ),

        ],
      ),
    );
  }
}

