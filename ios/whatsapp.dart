// import 'package:accounting_app2/user_details_screen.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: MyHomePage(),
//     );
//   }
// }
//
// class MyHomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('WhatsApp Chat & Calls'),
//       ),
//       body: HorizontalListView(),
//     );
//   }
// }
//
// class HorizontalListView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: List.generate(3, (index) {
//           return VerticalListView();
//         }),
//       ),
//     );
//   }
// }
//
// class VerticalListView extends StatelessWidget {
//   Future<Map<String, dynamic>> fetchUserData(String userId) async {
//     final ref = FirebaseDatabase.instance.ref();
//     final snapshot = await ref.child("users").child(widget.childName).child(userId).get();
//
//     try {
//       if (snapshot.exists) {
//         Map userData = snapshot.value as Map;
//
//         String name = userData['name'];
//         String description = userData['description'];
//         int number = userData['number'];
//         int quantity = userData['quantity'];
//         int price = userData['price'];
//         int totalPrice = userData['totalPrice'];
//         bool status = userData['status'];
//
//         return {
//           'name': name,
//           'description': description,
//           'number': number,
//           'quantity': quantity,
//           'price': price,
//           'totalPrice': totalPrice,
//           'status': status,
//         };
//       }
//     } catch (error) {
//       print("Error: $error");
//     }
//
//     return {
//       'name': 'N/A',
//       'description': 'N/A',
//       'number': 'N/A',
//       'quantity': 'N/A',
//       'price': 'N/A',
//       'totalPrice': 'N/A',
//       'status': 'N/A',
//     };
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Implement your content for each vertical item here, e.g., fetching data from Firebase.
//     return Container(
//       width: MediaQuery.of(context).size.width,
//       height: MediaQuery.of(context).size.height,
//       child: Column(
//         children: [
//           ListTile(
//             title: Text(
//               widget.childName,
//               style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             onTap: () {
//               setState(() {
//                 isExpanded = !isExpanded;
//               });
//             },
//           ),
//           if (isExpanded)
//             SizedBox(
//               height: 200, // Set the height to the desired value
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: childData.length,
//                 itemBuilder: (context, index) {
//                   return GestureDetector(
//                     onTap: () async {
//                       Map<String, dynamic> userData = await fetchUserData(childData[index]);
//
//                       String name = userData['name'];
//                       String description = userData['description'];
//                       int number = userData['number'];
//                       int quantity = userData['quantity'];
//                       int price = userData['price'];
//                       int totalPrice = userData['totalPrice'];
//                       bool status = userData['status'];
//
//                       Navigator.of(context).push(
//                         MaterialPageRoute(
//                           builder: (context) => UserDetailsScreen(
//                             name: name,
//                             description: description,
//                             number: number,
//                             quantity: quantity,
//                             price: price,
//                             totalPrice: totalPrice,
//                             status: status,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       width: 150, // Set the width to the desired value
//                       margin: EdgeInsets.all(8),
//                       color: Colors.blue,
//                       child: Center(
//                         child: Text(
//                           childData[index],
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
// class NestedListViewDemo extends StatefulWidget {
//   const NestedListViewDemo({Key? key}) : super(key: key);
//
//   @override
//   _NestedListViewDemoState createState() => _NestedListViewDemoState();
// }
//
// class _NestedListViewDemoState extends State<NestedListViewDemo> {
//   List<String> userNames = [];
//   DatabaseReference _usersRef = FirebaseDatabase.instance.reference().child("users");
//
//   @override
//   void initState() {
//     super.initState();
//
//     _usersRef.onChildAdded.listen((event) {
//       String? childName = event.snapshot.key;
//       if (childName != null) {
//         setState(() {
//           userNames.add(childName);
//         });
//       }
//     }, onError: (error) {
//       print("Error: $error");
//     });
//   }
//
//   void addUser() async {
//     DatabaseReference newUserRef = _usersRef.push();
//     newUserRef.set({
//       'name': 'New User',
//       'description': 'Description',
//       'number': 0,
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Nested ListView Demo'),
//       ),
//       body: ListView.builder(
//         itemCount: userNames.length,
//         itemBuilder: (context, index) {
//           return ExpandableListViewItem(
//             index: index,
//             childName: userNames[index],
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           showModalBottomSheet(
//             context: context,
//             builder: (BuildContext context) {
//               return AddItemForm((MyListItem newItem) {
//                 setState(() {});
//                 Navigator.pop(context);
//               });
//             },
//           );
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }
//
//
