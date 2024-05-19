
import 'dart:async';

// import 'package:accounting_app2/user_details_screen.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';




import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'UserData.dart';




class ExpandableListViewItem extends StatefulWidget {
  final String userName;
  final String userSignature;
  final String dataCollection;
  final int currentPage;
  int trueTotalPriceSum; // Remove 'final' keyword
  int falseTotalPriceSum; // Remove 'final' keyword
  int userPrices;
  int quantities;
  List<String> userNames;
  final void Function(int, int) onTotalPriceSumsUpdated;
  final List<String> dataCollections;
  final Function totalPriceSum; // Add this line
  ExpandableListViewItem({
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

  });

  @override
  _ExpandableListViewItemState createState() => _ExpandableListViewItemState();
}


class _ExpandableListViewItemState extends State<ExpandableListViewItem> {
  late DatabaseReference _childRef;
  late DatabaseReference numberOfUsers;

  List<String> childData = [];

  bool isExpanded = false;
  List<String> reversedUserNames = [];
  ValueNotifier<int> balanceForUser = ValueNotifier<int>(0);
  @override
  void initState() {
    super.initState();
    _childRef = FirebaseDatabase.instance.ref()
        .child(widget.dataCollection)
        .child(widget.userName);

    numberOfUsers = FirebaseDatabase.instance.ref()
        .child(widget.dataCollection)
        .child(widget.userName);

    // Attach Firebase listeners
    _attachFirebaseListeners();

    // Fetch user data to update total sums
    // Moved here to ensure it's called after Firebase setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserDataForSums();
    });
  }



  Future<int> getNumberOfNodes() async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref()
          .child(widget.dataCollection)
          .child(widget.userName);

      // Use await and then to handle the once() method's result
      DataSnapshot dataSnapshot = await reference.once().then((event) {
        return event.snapshot;
      });

      if (dataSnapshot.value != null && dataSnapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>;
        return values.length;
      } else {
        return 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      return 0; // Return a default value in case of an error
    }
  }

  // Setter methods for trueTotalPriceSum and falseTotalPriceSum
  void setTrueTotalPriceSum(int value) {
    if(mounted){
      setState(() {
        widget.trueTotalPriceSum = value;

      });
    }

  }

  void setFalseTotalPriceSum(int value) {
    if(mounted) {
      setState(() {

        widget.falseTotalPriceSum = value;
      });
    }
  }




  // Attach Firebase listeners
  void _attachFirebaseListeners() {
    if (!mounted) return;
    setState(() {
      childData.clear(); // Update childData on child addition
    });

    _childRef.onChildAdded.listen((event) {
      if (mounted) {
        String? childName = event.snapshot.key;
        if (childName != null) {
          setState(() {
            childData.add(childName); // Update childData on child addition
          });
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
        if (changedChildName != null && childData.contains(changedChildName)) {
          setState(() {
            // Handle changes in child data by refetching
            // childData.clear();
          });
          // fetchChildData(); // Re-fetch child data]
          fetchUserDataForSums();
        }
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("Child Error: $error");
      }
    });

    _childRef.onChildRemoved.listen((event) {
      String? removedChildName = event.snapshot.key;
      if (removedChildName != null) {
        if (mounted) {
          setState(() {
            // Remove the corresponding child from the local state
            childData.remove(removedChildName);
          });
          fetchUserDataForSums();
        }
        // Optionally, fetch updated data here to ensure synchronization
        // fetchChildData();
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("Child Removal Error: $error");
      }
    });
  }




  Future<void> fetchUserDataForSums() async {
    int trueTotalPriceSum = 0;
    int falseTotalPriceSum = 0;

    // Fetch child data and calculate sums
    await fetchChildData();

    List<String> childDataCopy = List.from(childData); // Create a copy of childData

    for (String childId in childDataCopy) {
      Map<String, dynamic> userData = await fetchUserData(
        childId,
        widget.userName,
        widget.dataCollection,
      );

      int totalPrice = 0;
      if (userData['totalPrice'] != null) {
        if (userData['totalPrice'] is int) {
          totalPrice = userData['totalPrice'];
        } else if (userData['totalPrice'] is String) {
          try {
            totalPrice = int.parse(userData['totalPrice']);
          } catch (e) {
            // Handle the case where the string cannot be parsed to an integer
            if (kDebugMode) {
              print('Error parsing totalPrice: $e');
            }
          }
        }
      }

      bool status = false;
      if (userData['status'] != null) {
        if (userData['status'] is bool) {
          status = userData['status'];
        } else if (userData['status'] is String) {
          // Convert string to boolean if it's 'true' or 'false'
          if (userData['status'] == 'true') {
            status = true;
          } else if (userData['status'] == 'false') {
            status = false;
          } else {
            // Handle the case where the string is not 'true' or 'false'
            if (kDebugMode) {
              print('Invalid status string: ${userData['status']}');
            }
          }
        }
      }


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


  Future<void> fetchChildData() async {
    try {
      final DatabaseEvent event = await _childRef.once();
      final DataSnapshot snapshot = event.snapshot;

      final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        if (mounted) {
          setState(() {
            childData = data.keys.cast<String>().toList();
          });
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("Fetch Child Data Error in ExpandableListViewItem: $error");
      }
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
      if (kDebugMode) {
        print("Error: $error");
      }
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
      'dateAndTime':'N/A',
      'imagePath':'N/A',
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
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(now);
    int numberOfNodes = await getNumberOfNodes(); // Await the Future<int>
    const int itemsPerPage = 20; // Define the number of items per page
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
      tableData.add(['', '', '', '', '']);
    }
    // Add empty rows based on numberOfNodes

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

    // headers: [ 'له', 'عليه',"كمية","سعر", 'التفاصيل', 'التاريخ'],
    tableData.add([
      "........",
      "........",
      "........",
      '........',
      "........",
      " ........",
      "........"
    ]);
    tableData.add([
      'ـــــــ',
      widget.trueTotalPriceSum.toString(),
      widget.falseTotalPriceSum.toString(),
      widget.quantities.toString(),
      widget.totalPriceSum.toString(),
      " ـــــــ",
      "ـــــــ"
    ]);
    tableData.add([
      "ـــــــ",
      "ـــــــ",
      "ـــــــ",
      'ـــــــ',
      'ـــــــ',
      total.toString(),
      totalType
    ]);

    // Firebase Database reference
    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child(datacollection)
        .child(widget.userName);
    // Modify the query to sort the data in descending order
    Query query =
    reference.orderByChild("timestamp").limitToLast(numberOfNodes);

    DatabaseEvent event = await query.once(); // Wait for the query result
    DataSnapshot dataSnapshot = event.snapshot;
    if (dataSnapshot.value != null) {
      Map<dynamic, dynamic>? values =
      dataSnapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        List<String> orderedKeys = values.keys.cast<String>().toList();

        // Sort keys based on milliseconds
        orderedKeys.sort((a, b) {
          try {
            return int.parse(a).compareTo(int.parse(b));
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing keys: $a, $b");
              print(e);
            }

            return 0; // Return 0 to handle the error gracefully, or choose appropriate fallback behavior
          }
        });

        // Reverse the order of keys
        orderedKeys = orderedKeys.reversed.toList();

        // Now, populate the tableData with reversed data
        int rowCounter = 0;
        for (var key in orderedKeys) {
          var value = values[key];
          if (rowCounter < numberOfNodes) {
            if (value["status"] == true) {
              tableData[rowCounter] = [
                value['number'].toString(),
                value['totalPrice'].toString(),
                '0',
                value['quantity'].toString(),
                value['price'].toString(),
                value['description'].toString(),
                value['dateAndTime'].toString(),
              ];
              rowCounter++;
            } else {
              tableData[rowCounter] = [
                value['number'].toString(),
                '0',
                value['totalPrice'].toString(),
                value['quantity'].toString(),
                value['price'].toString(),
                value['description'].toString(),
                value['dateAndTime'].toString(),
              ];
              rowCounter++;
            }
          }
        }

        // Split tableData into multiple pages if necessary
        List<List<List<String>>> pagesData = [];
        for (int i = 0; i < tableData.length; i += itemsPerPage) {
          final endIndex = i + itemsPerPage;
          pagesData.add(tableData.sublist(
              i, endIndex > tableData.length ? tableData.length : endIndex));
        }

        // Generate PDF pages for each set of table data
        // Generate PDF pages for each set of table data
        for (int i = 0; i < pagesData.length; i++) {

          pdf.addPage(
            pw.MultiPage(
              build: (pw.Context context) {
                final List<pw.Widget> content = [
                  pw.Center(
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.rtl,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (i == 0) // Display the title only on the first page
                            pw.Column(
                                children: [
                                  pw.Text(
                                    ' كشف حساب : $name',
                                    textDirection: pw.TextDirection.rtl,
                                    style: const pw.TextStyle(fontSize: 24),
                                  ),
                                  pw.Text(
                                    formattedDate,
                                    textDirection: pw.TextDirection.rtl,
                                    style: const pw.TextStyle(
                                      fontSize: 15,
                                      color: PdfColors.blue,
                                    ),
                                  ),
                                ]
                            ),

                          // Add space between the date and table
                          buildTable(pagesData[i]),
                        ],
                      ),
                    ),
                  ),
                ];


                return content;
              },
            ),
          );
        }

      }
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String pdfPath = '${tempDir.path}/$name.pdf';
    final File file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());
    Share.shareFiles([pdfPath], text: '$name PDF');
  }

  pw.Widget buildTable(List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: ['الرصيد', 'له', 'عليه', "كمية", "سعر", 'التفاصيل', 'التاريخ'],
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

  @override
  void dispose() {
    _childRef.onChildAdded.drain(); // Cancel the listener
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    // String userName = "";
    // int underscoreIndex = widget.userName.indexOf('_');
    // if (underscoreIndex != -1 && underscoreIndex <  widget.userName.length - 1) {
    //   userName =  widget.userName.substring(underscoreIndex + 1);
    //   print(userName); // This will print the substring that starts after the underscore
    // } else {
    //   print("No underscore found or no characters after the underscore.");
    // }

    balanceForUser.value = widget.trueTotalPriceSum - widget.falseTotalPriceSum ;
    int  balanceForUserValue  = balanceForUser.value;
    return
      ValueListenableBuilder<int>(
        valueListenable: balanceForUser,
        builder: (BuildContext context, int value, child) {
          return

            InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserData(
                        userName: widget.userName,
                        userSignature: widget.userSignature,
                        dataCollection: widget.dataCollection,
                        currentPage: widget.currentPage,
                        trueTotalPriceSum: widget.trueTotalPriceSum,
                        falseTotalPriceSum: widget.falseTotalPriceSum,
                        balanceForUser: balanceForUser,
                        onTotalPriceSumsUpdated: (trueTotal, falseTotal) {
                          // Handle updates if needed
                        },
                        userPrices: widget.userPrices,
                        quantities: widget.quantities,
                        userNames: widget.userNames,
                        dataCollections: widget.dataCollections, totalPriceSum:  () {
                        // This callback will be executed after the BottomSheet is closed
                        // setState(() {
                        // Update childNodes here
                        fetchUserDataForSums();
                        _attachFirebaseListeners();
                        widget.totalPriceSum();

                        //  print("done ----------------------------- - - - - - - - -- - - -  --  --  -    -  -- 2");
                        // Future.delayed(Duration(milliseconds:300), () {
                        //   fetchChildNodes(dataCollections[currentPage]);
                        // });

                        //  });
                      },
                      ),
                    ),
                  ).then((value) {
                    // Check if the value is true, then recall the function
                    if (value == true) {
                      // fetchUserDataForSums();
                      // _attachFirebaseListeners();
                      // widget.totalPriceSum();
                      setState(() {
                        //  print("done ----------------------------- - - - - - - - -- - - -  --  --  -    -  -- 222222222");
                        widget.totalPriceSum();

                      });


                    }
                  });
                },
                onLongPress: () {
                  loadArabicFontAndSharePDF(widget.dataCollection);
                },
                child:
                ListTile(
                  title:
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (balanceForUser.value > 0 )


                        Container(decoration: BoxDecoration( border: Border.all(color: Colors.black45 ),
                          borderRadius: BorderRadius.circular(8.0),), child:SizedBox(
                          width: 90,
                          child: Column(
                            children: [
                              const Text(
                                'له',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '$balanceForUserValue',
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),

                      if (balanceForUser.value < 0)
                        Container(decoration: BoxDecoration( border: Border.all(color: Colors.indigo),
                          borderRadius: BorderRadius.circular(8.0),), child:  SizedBox(
                          width: 90,
                          child: Column(
                            children: [
                              const Text(
                                'عليه',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '$balanceForUserValue',
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                      if(balanceForUser.value == 0 )
                        Container(decoration: BoxDecoration( border: Border.all(color: Colors.indigo),
                          borderRadius: BorderRadius.circular(8.0),), child:   SizedBox(
                          width: 90,
                          child: Column(
                            children: [
                              // const Text(
                              //   '',
                              //   style: TextStyle(
                              //     fontSize: 16.0,
                              //     fontWeight: FontWeight.bold,
                              //     color: Colors.blue,
                              //   ),
                              // ),
                              Text(
                                '$balanceForUserValue',
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        )),
                      //  SizedBox(width: 5,),









                      //  SizedBox(width: 5,),
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                              color:
                              Color(0xFF494EBA),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ), )

            );

        },
      );
  }




}