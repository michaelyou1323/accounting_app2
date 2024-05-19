import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyListViewScreen(),
    );
  }
}

class MyListViewScreen extends StatefulWidget {
  const MyListViewScreen({super.key});

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
        title: const Text('العملاد'),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void fetchDataFromFirebase() {

    final DatabaseReference ref = FirebaseDatabase.instance.ref().child("users/hmn nm/-Nhp3kwLBuSocwfURtfu");

    ref.onValue.listen((event) {
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

  const MyListItem({super.key, 
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
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _additionalInfoController,
            decoration: const InputDecoration(labelText: 'تفاصيل'),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Add your button logic here
                },
                child: const Text('له'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Add your button logic here
                },
                child: const Text('عليه'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

class AddItemForm extends StatefulWidget {
  final Function(MyListItem) onSubmit;

  const AddItemForm(this.onSubmit, {super.key});

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();

  final DatabaseReference _ref = FirebaseDatabase.instance.ref().child("users");

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إضافة عميل',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'الاسم'),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'المبلغ'),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _additionalInfoController,
            decoration: const InputDecoration(labelText: 'تفاصيل'),
          ),
          const SizedBox(height: 16.0),
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
            child: const Text('إضافة العميل'),
          ),
        ],
      ),
    );
  }
}
