import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyListViewScreen(),
    );
  }
}

class MyListViewScreen extends StatefulWidget {
  @override
  _MyListViewScreenState createState() => _MyListViewScreenState();
}

class _MyListViewScreenState extends State<MyListViewScreen> {
  List<MyListItem> items = [];
  late DatabaseReference _ref;

  @override
  void initState() {
    super.initState();
    _ref = FirebaseDatabase.instance.ref().child("users");
    fetchDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('العملاد'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return items[index];
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return AddItemForm((MyListItem newItem) {
                setState(() {
                  // items.add(newItem);
                });
                Navigator.pop(context);
              });
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void fetchDataFromFirebase() {

    final DatabaseReference _ref = FirebaseDatabase.instance.ref().child("users/hmn nm/-Nhp3kwLBuSocwfURtfu");

    _ref.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final Map<String, dynamic>? data = snapshot.value as Map<String, dynamic>?;
        if (data != null) {
          String name = data['name'];
          String description = data['discription']; // Make sure to use the correct field name
          String number = data['number'];

          // Now, you can use these values as needed
          print("Name: $name, Description: $description, Number: $number");
        }
      } else {
        print("Data not found.");
      }
    }, onError: (error) {
      print("Error: $error");
    });

    // _ref.onChildAdded.listen((event) {
    //   final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
    //   if (data != null) {
    //     setState(() {
    //       items.add(MyListItem(
    //         firstName: data['name'] ?? '',
    //         lastName: data['number'] ?? '',
    //         additionalInfo: data['description'] ?? '',
    //        // key: event.snapshot.key.toString(),
    //         onDelete: () {
    //           _deleteItem(data['name'], event.snapshot.key.toString());
    //         },
    //       ));
    //     });
    //   }
    // });
  }

  void _deleteItem(String firstName, String key) {
    _ref.child(firstName).child(key).remove().then((_) {
      setState(() {
        items.removeWhere((item) =>
        item.firstName == firstName && item.key == key,
        );
      });
    }).catchError((error) {
      // Handle any errors here
    });
  }
}

class MyListItem extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String additionalInfo;
 // final String key;
  final Function onDelete;

  MyListItem({
    required this.firstName,
    required this.lastName,
    required this.additionalInfo,
   // required this.key,
    required this.onDelete,
  });

  @override
  _MyListItemState createState() => _MyListItemState();
}

class _MyListItemState extends State<MyListItem> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _additionalInfoController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _additionalInfoController = TextEditingController(text: widget.additionalInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'الاسم'),
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'المبلغ'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  widget.onDelete();
                },
              ),
            ],
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _additionalInfoController,
            decoration: InputDecoration(labelText: 'تفاصيل'),
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Add your button logic here
                },
                child: Text('له'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Add your button logic here
                },
                child: Text('عليه'),
              ),
            ],
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

class AddItemForm extends StatefulWidget {
  final Function(MyListItem) onSubmit;

  AddItemForm(this.onSubmit);

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _additionalInfoController = TextEditingController();

  final DatabaseReference _ref = FirebaseDatabase.instance.ref().child("users");

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
            controller: _firstNameController,
            decoration: InputDecoration(labelText: 'الاسم'),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: 'المبلغ'),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _additionalInfoController,
            decoration: InputDecoration(labelText: 'تفاصيل'),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              String firstName = _firstNameController.text;
              _ref.child(firstName).push().set({
                'name': _firstNameController.text,
                'number': _lastNameController.text,
                'description': _additionalInfoController.text,
              });
              Navigator.pop(context);
            },
            child: Text('إضافة العميل'),
          ),
        ],
      ),
    );
  }
}
