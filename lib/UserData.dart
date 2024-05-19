// import 'dart:async';

//
// import 'package:accounting_app2/user_details_screen.dart';

import 'package:accounting_app2/user_details_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';

import 'dart:ui' as ui;

// import 'package:flutter/cupertino.dart';

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'AddItemForm.dart';

class UserData extends StatefulWidget {
  final String userName;
  final String userSignature;
  final String dataCollection;
  final int currentPage;
  final List<String> dataCollections;
  int trueTotalPriceSum;
  int falseTotalPriceSum;
  int userPrices;
  int quantities;
  List<String> userNames;
  final void Function(int, int) onTotalPriceSumsUpdated;
  final Function totalPriceSum;
  ValueNotifier<int> balanceForUser;

  UserData({
    super.key,
    required this.userName,
    required this.userSignature,
    required this.dataCollection,
    required this.currentPage,
    required this.trueTotalPriceSum,
    required this.falseTotalPriceSum,
    required this.onTotalPriceSumsUpdated,
    required this.userPrices,
    required this.quantities,
    required this.userNames,
    required this.dataCollections,
    required this.totalPriceSum,
    required this.balanceForUser,
  });

  @override
  _UserData createState() => _UserData();
}

class _UserData extends State<UserData> {
  late DatabaseReference _childRef;
  late DatabaseReference numberOfUsers;
  bool _showTextField = false;
  List<String> searchNodes = [];
  List<String> childNodes =
  []; // List to store child nodes for each reference name
  List<String> childData = [];
  List<String> reversedUserNames = [];

  // List<String> reversedUserNames1 = [];
  bool isExpanded = false;

//  List<String> childData2 = [];
  int currentNumberForDeletedUser = 0;
  bool currentStatusForDeletedUser = false;
  String lastChild = " ";

  // late DatabaseReference _ref;

  int lastUserBalance = 0;

  @override
  void initState() {
    super.initState();

    _childRef = FirebaseDatabase.instance
        .ref()
        .child(widget.dataCollection)
        .child(widget.userName);

    numberOfUsers = FirebaseDatabase.instance
        .ref()
        .child(widget.dataCollection)
        .child(widget.userName);

    // Attach Firebase listeners
    setState(() {
      _attachFirebaseListeners();
    });

    // Fetch user data to update total sums
    // Moved here to ensure it's called after Firebase setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserDataForSums();
    });
  }

  Future<int> getNumberOfNodes() async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance
          .ref()
          .child(widget.dataCollection)
          .child(widget.userName);

      // Use await and then to handle the once() method's result
      DataSnapshot dataSnapshot = await reference.once().then((event) {
        return event.snapshot;
      });

      if (dataSnapshot.value != null &&
          dataSnapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic>? values =
        dataSnapshot.value as Map<dynamic, dynamic>;
        return values.length;
      } else {
        return 0;
      }
    } catch (e) {
      // print('Error fetching data: $e');
      return 0; // Return a default value in case of an error
    }
  }

  // Setter methods for trueTotalPriceSum and falseTotalPriceSum
  void setTrueTotalPriceSum(int value) {
    if (mounted) {
      setState(() {
        widget.trueTotalPriceSum = value;
      });
    }
  }

  void setFalseTotalPriceSum(int value) {
    if (mounted) {
      setState(() {
        widget.falseTotalPriceSum = value;
      });
    }
  }

  // Attach Firebase listeners
  void _attachFirebaseListeners() {
    _childRef.onChildAdded.listen((event) {
      if (mounted) {
        String? childName = event.snapshot.key;
        if (childName != null) {
          if (!reversedUserNames.contains(childName)) {
            setState(() {
              // getLastUserBalance();
              reversedUserNames
                  .add(childName); // Update childData on child addition
            });
          }
        }
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("data Error: $error");
      }
    });

    _childRef.onChildChanged.listen((event) {
      if (mounted) {
        String? changedChildName = event.snapshot.key;
        if (changedChildName != null &&
            reversedUserNames.contains(changedChildName)) {
          setState(() {
            // Handle changes in child data by refetching
            // childData.clear();
            fetchChildData(); // Re-fetch child data
            // getLastUserBalance();
          });
        }
      }
    }, onError: (error) {
      // print("Child Error: $error");
    });

    _childRef.onChildRemoved.listen((event) {
      String? removedChildName = event.snapshot.key;
      if (removedChildName != null) {
        if (mounted) {
          setState(() {
            // Remove the corresponding child from the local state
            reversedUserNames.remove(removedChildName);
            // getLastUserBalance();
          });
        }
        // Optionally, fetch updated data here to ensure synchronization
        // fetchChildData();
      }
    }, onError: (error) {
      //  print("Child Removal Error: $error");
    });
  }

  Future<void> fetchChildData() async {
    try {
      final DatabaseEvent event = await _childRef.once();
      final DataSnapshot snapshot = event.snapshot;

      List<String> orderedChildData = [];

      if (snapshot.value != null && snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          // Extract keys from the map and add them to orderedChildData
          orderedChildData.addAll(data.keys.cast<String>());

          // Sort keys based on milliseconds
          orderedChildData.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        }
      }

      setState(() {
        // Update childData with the ordered list of keys

        childData = orderedChildData;

        // print(orderedChildData);

        // lastChild = orderedChildData.last;
        reversedUserNames = List.from(childData.reversed);

        lastChild = reversedUserNames.first;
        // print(reversedUserNames);
        getLastUserBalance();
      });
    } catch (error) {
      // print("Fetch Child Data Error in userData: $error");
    }
  }

  Future<void> fetchUserDataForSums() async {
    int trueTotalPriceSum = 0;
    int falseTotalPriceSum = 0;

    // Fetch child data and calculate sums
    await fetchChildData();

    for (String childId in reversedUserNames) {
      Map<String, dynamic> userData = await fetchUserData(
        childId,
        widget.userName,
        widget.dataCollection,
      );

      int totalPrice = userData['totalPrice'] ?? 0;
      bool status = userData['status'] ?? false;

      if (status) {
        trueTotalPriceSum += totalPrice;
      } else {
        falseTotalPriceSum += totalPrice;
      }
    }

    // Update the user's total sums using the setter methods
    setTrueTotalPriceSum(trueTotalPriceSum);
    setFalseTotalPriceSum(falseTotalPriceSum);

    // Update state after calculations
    if (mounted) {
      setState(() {
        widget.trueTotalPriceSum = trueTotalPriceSum;
        widget.falseTotalPriceSum = falseTotalPriceSum;
      });
    }
  }

  // Function to fetch user data from Firebase
  Future<Map<String, dynamic>> fetchUserData(
      String userId, String userName, String dataCollection) async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref
        .child(widget.dataCollection)
        .child(userName)
        .child(userId)
        .get();

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
          'userSignature': userData["userSignature"],
          'dateAndTime': userData['dateAndTime'],
          'imagePath': userData['imagePath'],
        };
      }
    } catch (error) {
      // print("Error: $error");
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
      'dateAndTime': 'N/A',
      'imagePath': 'N/A',
    };
  }

  Future<void> loadArabicFontAndSharePDF(datacollection) async {
    final fontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final arabicFont = pw.Font.ttf(fontData);
    // Call the function to create the PDF after loading the font
    _shareUserDataInPDF(arabicFont, datacollection);
  }

// Update the _shareUserDataInPDF method to create a table with dynamic row count
  Future<void> _shareUserDataInPDF(pw.Font arabicFont, datacollection) async {
    int numberOfNodes = await getNumberOfNodes(); // Await the Future<int>
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: arabicFont,
        bold: arabicFont,
        italic: arabicFont,
        boldItalic: arabicFont,
      ),
    );

    final name = widget.userName;

    List<List<String>> tableData = [];

    // Add empty rows based on numberOfNodes
    for (int i = 0; i < numberOfNodes; i++) {
      tableData.add(['', '', '', '']);
    }
    String totalType = "";
    int total = 0;
    if (widget.trueTotalPriceSum > widget.falseTotalPriceSum) {
      total = widget.trueTotalPriceSum - widget.falseTotalPriceSum;
      totalType = "إجمالي العمليات (له)";
    } else if (widget.trueTotalPriceSum < widget.falseTotalPriceSum) {
      total = widget.trueTotalPriceSum - widget.falseTotalPriceSum;
      totalType = "إجمالي العمليات (عليه)";
    } else {
      totalType = "إجمالي العمليات";
      total = 0;
    }

    // headers: [  'له', 'عليه',"كمية","سعر", 'التفاصيل', 'التاريخ'],
    tableData.add([
      "........",
      "........",
      '........',
      "........",
      " ........",
      "........"
    ]);
    tableData.add([
      widget.trueTotalPriceSum.toString(),
      widget.falseTotalPriceSum.toString(),
      widget.quantities.toString(),
      widget.userPrices.toString(),
      " ـــــــ",
      "ـــــــ"
    ]);
    tableData.add([
      "ـــــــ",
      "ـــــــ",
      'ـــــــ',
      'ـــــــ',
      total.toString(),
      totalType
    ]);

    // Firebase Database reference
// Fetching data from Firebase and populating the empty rows
    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child(datacollection)
        .child(widget.userName);

    DatabaseEvent event = await reference.once();
    DataSnapshot dataSnapshot = event.snapshot;
    if (dataSnapshot.value != null) {
      Map<dynamic, dynamic>? values =
      dataSnapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        int rowCounter = 0;
        values.forEach((key, value) {
          if (rowCounter < numberOfNodes) {
            if (value["status"] == true) {
              tableData[rowCounter] = [
                value['totalPrice'].toString(),
                // Leave the last two columns empty as neede
                '0',
                value['quantity'].toString(),
                value['price'].toString(),
                value['description'].toString(),
                value['dateAndTime'].toString(),
              ];
              rowCounter++;
            } else {
              tableData[rowCounter] = [
                '0', // Leave the last two columns empty as neede
                value['totalPrice'].toString(),
                value['quantity'].toString(),
                value['price'].toString(),
                value['description'].toString(),
                value['dateAndTime'].toString(),
              ];
              rowCounter++;
            }
          }
        });
      }
    }

    pw.Widget buildTable(List<List<String>> data) {
      return pw.Table.fromTextArray(
        headers: ['له', 'عليه', "كمية", "سعر", 'التفاصيل', 'التاريخ'],
        data: data.map((row) {
          return row.map((cell) {
            return cell; // Adjust this part based on your cell data
          }).toList();
        }).toList(),
        cellAlignment: pw.Alignment.center,
        cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        border: pw.TableBorder.all(color: PdfColors.black),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.0),
          1: const pw.FlexColumnWidth(1.0),
          2: const pw.FlexColumnWidth(1.0),
          3: const pw.FlexColumnWidth(1.0),
        },
        cellHeight: 20,
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
        },
        rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      );
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(now);

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(' كشف حساب : $name',
                      textDirection: pw.TextDirection.rtl,
                      style: const pw.TextStyle(fontSize: 24)),
                  pw.SizedBox(height: 10),
                  pw.Text(formattedDate,
                      textDirection: pw.TextDirection.rtl,
                      style: const pw.TextStyle(
                          fontSize: 15, color: PdfColors.blue)),
                  pw.SizedBox(height: 10),
                  // Add space between the date and table
                  buildTable(tableData),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final Directory tempDir = await getTemporaryDirectory();
    final String pdfPath = '${tempDir.path}/$name.pdf';
    final File file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());
    Share.shareFiles([pdfPath], text: '$name PDF');
  }

  void search(String query) async {
    // If the search query is empty, reset the list to its original state
    if (query.isEmpty) {
      setState(() {
        reversedUserNames = childData.reversed.toList();
      });
      return;
    }

    List<String> searchResults = [];

    // Filter reversedUserNames list based on the query
    for (String childId in childData) {
      Map<String, dynamic> userData =
      await fetchUserData(childId, widget.userName, widget.dataCollection);
      String description = userData['description'].toLowerCase();
      if (description.contains(query.toLowerCase())) {
        searchResults.add(childId);
      }
    }

    setState(() {
      reversedUserNames = searchResults;
    });
  }

  Future<Map<String, dynamic>> fetchLastUserData() async {
    // lastChild = reversedUserNames.first;

    //  print("$lastChild1 last one");
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref
        .child(widget.dataCollections[widget.currentPage])
        .child(widget.userName)
        .child(lastChild)
        .get();

    try {
      if (snapshot.exists) {
        Map userData = snapshot.value as Map;
        return {
          'number': userData['number'],
        };
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error: $error");
      }
    }

    return {
      'number': 'N/A',
    };
  }

  Future<void> getLastUserBalance() async {
    // If the search query is empty, reset the list to its original state
    Map<String, dynamic> userData = await fetchLastUserData();
    //lastUserBalance =  * -1;
    print(
        "User Data: $userData   vvvvvvvvvvvvvvvvvvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv"); // Check the entire userData map
    print(
        "Number: ${userData['number']}   vvvvvvvvvvvvvvvvvvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv vvvvvvvv"); // Check the specific value you're trying to parse
    //  var number = int.parse(userData["number"].trim());
    lastUserBalance = userData["number"] * -1;
    print(
        "$lastUserBalance   _______   ++++++++   ++++++++   ++++++++   ++++++++   ++++++++   ++++++++   ++++++++   ++++++++");
  }

  @override
  void dispose() {
    _childRef.onChildAdded.drain(); // Cancel the listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // getLastUserBalance();
    return Scaffold(
      appBar: AppBar(
        actionsIconTheme: const IconThemeData(color: Colors.black),
        title: _showTextField
            ? Directionality(
            textDirection: ui.TextDirection.rtl, // Right-to-Left direction
            child: TextField(
              autofocus: true,
              // Set autofocus to true
              decoration: const InputDecoration(
                hintText: 'بحثـــ....',
                hintStyle: TextStyle(color: Colors.black),
              ),
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                search(value);
              },
              onSubmitted: (value) {
                // search(value);
                //  setState(() {
                //    _showTextField = !_showTextField;
                //   childNodes = searchNodes;
                //  });
                //
                //  print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
              },
            ))
            : GestureDetector(
          onTap: () {
            //  setState(() {
            // //   _showTextField = true;
            //  });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey,
              ),
            ),
            child: Center(
              child: Text(
                widget.userName,
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          // ),
        ),

        //

        actions: [
          ValueListenableBuilder<int>(
            valueListenable: widget.balanceForUser,
            builder: (BuildContext context, int value, child) {
              print(widget.balanceForUser.value);
              return lastUserBalance == widget.balanceForUser.value
                  ? IconButton(
                icon: const Icon(
                  Icons.check_circle,
                ),
                color: Colors.green,
                onPressed: () {},
              )
                  : const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator());
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_sharp),
            color: Colors.black,
            onPressed: () {
              setState(() {
                _showTextField =
                !_showTextField; // Toggle the text field visibility
              });
            },
          ),
        ],
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            widget.totalPriceSum();
            return;
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                ),
                const Expanded(
                  child: SizedBox(
                    width: 80,
                    child: Text(
                      "الرصيد",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 28.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      "التفاصيل",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      "المبلغ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      "التاريخ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 13,
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reversedUserNames.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 5,
                      color: Colors.white,
                      child: ListTile(
                        title: Align(
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: fetchUserData(reversedUserNames[index],
                                widget.userName, widget.dataCollection),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              if (snapshot.data != null) {
                                String totalPrice =
                                snapshot.data!['totalPrice'].toString();
                                String balance =
                                snapshot.data!['number'].toString();
                                String description =
                                snapshot.data!['description'];
                                String dateAndTime =
                                snapshot.data!['dateAndTime'];
                                bool status = snapshot.data!['status'] ==
                                    true; // Convert String to bool

                                return Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width: 80,
                                        child: Text(
                                          balance,
                                          style: TextStyle(
                                              color: Colors.indigo[900],
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    if (status == false)
                                      Container(
                                        width: 28.0,
                                        height: 28.0,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 28.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                    if (status == true)
                                      Container(
                                        width: 28.0,
                                        height: 28.0,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons
                                                .keyboard_double_arrow_up_rounded,
                                            size: 28.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        width: 80,
                                        child: Text(
                                          description,
                                          style: TextStyle(
                                              color: Colors.indigo[900],
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        width: 80,
                                        child: Text(
                                          totalPrice,
                                          style: TextStyle(
                                              color: Colors.indigo[900],
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),
                                    // Expanded(
                                    //   child:
                                    Expanded(
                                      child: SizedBox(
                                        width: 80,
                                        child: Text(
                                          dateAndTime,
                                          style: TextStyle(
                                              color: Colors.indigo[900],
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                    // ),
                                    // Repeat the same for other Text widgets
                                  ],
                                );
                              } else {
                                return const Text(
                                    'No data available'); // Placeholder for no data state
                              }
                            },
                          ),
                        ),
                        onTap: () async {
                          Map<String, dynamic> userData = await fetchUserData(
                              reversedUserNames[index],
                              widget.userName,
                              widget.dataCollection);
                          String name = userData['name'];
                          String description = userData['description'];
                          int number = userData['number'];
                          int quantity = userData['quantity'];
                          int price = userData['price'];
                          int totalPrice = userData['totalPrice'];
                          bool status = userData['status'];
                          String userSignature = userData["userSignature"];
                          String dateAndTime = userData["dateAndTime"];
                          String imagePath = userData['imagePath'];

                          int numberOfNodes =
                          await getNumberOfNodes(); // Await the Future<int>
                          // if (numberOfNodes == 1) {
                          //   setState(() {
                          //
                          //   });
                          // }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserDetailsScreen(
                                userNames: widget.userNames,
                                name: name,
                                description: description,
                                number: number,
                                quantity: quantity,
                                price: price,
                                totalPrice: totalPrice,
                                status: status,
                                userSignature: userSignature,
                                index: index,
                                childData: reversedUserNames[index],
                                currentPage: widget.currentPage,
                                datacollection: widget.dataCollection,
                                dateAndTime: dateAndTime,
                                imagePath: imagePath,
                                numberOfNodes: numberOfNodes,
                                userName: widget.userName,
                                trueTotalPriceSum: widget.trueTotalPriceSum,
                                falseTotalPriceSum: widget.falseTotalPriceSum,
                                totalQuantitySum: widget.quantities,
                                totalPriceSum: widget.userPrices,
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {},
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          backgroundColor: Colors.indigo[500],
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return FractionallySizedBox(
                  heightFactor: 0.9,
                  child: AddItemForm(
                    userSignature: widget.userSignature,
                    dataCollections: widget.dataCollections,
                    currentPage: widget.currentPage,
                    userNames: widget.userNames,
                    userOrAll: 0,
                    userName: widget.userName,
                    onSheetClosed: () {
                      _attachFirebaseListeners();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        fetchUserDataForSums();
                      });
                    },
                    lastChild: lastChild,
                  ),
                );
              },
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class RoundedDownArrowIcon extends StatelessWidget {
  const RoundedDownArrowIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        // Adjust the radius as needed
        color: Colors.red, // Set the background color as needed
      ),
      padding: const EdgeInsets.all(4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        // Should match the container's radius
        child: const Icon(
          Icons.keyboard_arrow_down,
          size: 40.0, // Adjust the size as needed
          color: Colors.white, // Set the icon color as needed
        ),
      ),
    );
  }
}
