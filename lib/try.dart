import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp2());
}

class MyApp2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController _pageController = PageController(initialPage: 0, viewportFraction: 1.0);
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nested ListView Demo'),
      ),
      body: HorizontalListView(pageController: _pageController),
    );
  }
}

class HorizontalListView extends StatefulWidget {
  final PageController pageController;

  HorizontalListView({required this.pageController});

  @override
  _HorizontalListViewState createState() => _HorizontalListViewState(pageController: pageController, childName: '');
}

class _HorizontalListViewState extends State<HorizontalListView> {
  final PageController pageController;
  final String childName;

  _HorizontalListViewState({required this.pageController, required this.childName});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      itemCount: 10, // Number of pages (items)
      itemBuilder: (BuildContext context, int index) {
        return FutureBuilder<List<String>>(
          future: fetchUserNames(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final userNames = snapshot.data!;
              final childName = userNames[index];
              return VerticalListView(childName: childName);
            } else {
              return Center(child: Text('No data available.'));
            }
          },
        );
      },
    );
  }

  Future<List<String>> fetchUserNames() async {
    DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child("users");

    final snapshot = await _usersRef.get();
    final userNamesMap = snapshot.value;
    if (userNamesMap is Map) {
      return userNamesMap.keys.cast<String>().toList();
    }
    return [];
  }
}

class VerticalListView extends StatefulWidget {
  final String childName;

  VerticalListView({required this.childName});

  @override
  _VerticalListViewState createState() => _VerticalListViewState(childName: childName);
}

class _VerticalListViewState extends State<VerticalListView> {
  late DatabaseReference _childRef;

  var childName;

 _VerticalListViewState({required this.childName});



  @override
  void initState() {
    super.initState();
    _childRef = FirebaseDatabase.instance.ref().child("users").child(widget.childName);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20, // Number of vertical items
      itemBuilder: (BuildContext context, int subIndex) {
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchUserData(subIndex.toString()), // Pass the subIndex as the user ID
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(title: Text('Loading...'));
            } else if (snapshot.hasError) {
              return ListTile(title: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final userData = snapshot.data!;
              return ListTile(
                title: Text('Name: ${userData['name']}'),
                subtitle: Text('Description: ${userData['description']}'),
              );
            } else {
              return ListTile(title: Text('No data available.'));
            }
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> fetchUserData(String userId) async {

    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child("users").child(widget.childName).child(userId).get();

    try {
      if (snapshot.exists) {
        Map userData = snapshot.value as Map ;
        // final Map<String, dynamic>? data2 = snapshot as Map<String, dynamic>?;

        String name = userData['name'];
        String description = userData['description'];
        int number = userData['number'];
        int quantity = userData['quantity'];
        int price = userData['price'];
        int totalPrice = userData['totalPrice'];
        bool status = userData['status'];

        print(snapshot.value );

        return {
          'name': name,
          'description': description,
          'number': number,
          'quantity': quantity,
          'price': price,
          'totalPrice': totalPrice,
          'status': status,

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

    };
  }
}
