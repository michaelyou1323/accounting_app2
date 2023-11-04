import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UserDetailsScreen(
        name: '',
        description: '',
        number: 0,
        quantity: 0,
        price: 0,
        totalPrice: 0,
        status: false,
        userSignature: "",
        index: 0,
        childData: '',
      ),
    );
  }
}

class UserDetailsScreen extends StatefulWidget {
  final String name;
  final String description;
  final int number;
  final int quantity;
  final int price;
  final int totalPrice;
  final bool status;
  final String userSignature;
  final int index;
  final String childData;


  UserDetailsScreen({
    required this.name,
    required this.description,
    required this.number,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.status,
    required this.userSignature,
    required this.index,
    required this.childData,
  });

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  final DatabaseReference _ref = FirebaseDatabase.instance.reference().child("users");

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _numberController = TextEditingController(text: widget.number.toString());
    _descriptionController = TextEditingController(text: widget.description);
    _quantityController = TextEditingController(text: widget.quantity.toString());
    _priceController = TextEditingController(text: widget.price.toString());
  }

  Future<void> _deleteItem() async {
    // Show a confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف هذا العنصر؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't delete
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: Text('حذف'),
            ),
          ],
        );
      },
    );

    // If the user confirms deletion
    if (shouldDelete == true) {
      // Remove data from Firebase
      _ref.child(widget.name).child(widget.childData).remove().then((_) {
        // Show a toast message
        Fluttertoast.showToast(
          msg: "تم حذف العنصر بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // Navigate back to the previous screen
        Navigator.of(context).pop();
      }).catchError((error) {
        print("Error: $error");
        // Handle error (e.g., show an error message)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('العملاد'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(16.0),
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'الاسم'),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          controller: _numberController,
                          decoration: InputDecoration(labelText: 'المبلغ'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          // Delete the item
                          _deleteItem();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          decoration: InputDecoration(labelText: 'الكمية'),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: 'السعر'),
                        ),
                      ),
                      Expanded(
                        child: Text("Total"),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'تفاصيل'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              widget.status == false ? Colors.grey : Colors.lightBlueAccent),
                        ),
                        child: Text('          عليه           '),
                      ),
                      SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              widget.status == true ? Colors.grey : Colors.lightBlueAccent),
                        ),
                        child: Text('            له             '),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
