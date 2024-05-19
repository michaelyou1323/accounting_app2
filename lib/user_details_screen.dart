// import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart'; // Import this package for FilteringTextInputFormatter
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'dart:ui' as ui;

import 'CalculatorWidget.dart';
import 'new.dart';

// import 'package:flutter/services.dart' show rootBundle;

// import 'lib/new.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UserDetailsScreen(
        name: ' ',
        description: ' ',
        number: 0,
        quantity: 0,
        price: 0,
        totalPrice: 0,
        status: false,
        userSignature: " ",
        index: 0,
        childData: ' ',
        currentPage: 0,
        datacollection: " ",
        dateAndTime: " ",
        imagePath: "   ",
        numberOfNodes: 0,
        userName: "",
        falseTotalPriceSum: 0,
        trueTotalPriceSum: 0,
        totalQuantitySum: 0,
        totalPriceSum: 0,
        userNames: const [],
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
  final int currentPage;
  final String datacollection;
  final String dateAndTime;
  final String imagePath;
  final int numberOfNodes;
  final String userName;
  final int trueTotalPriceSum;
  final int falseTotalPriceSum;
  final int totalPriceSum;
  final int totalQuantitySum;

  List<String> userNames;

  UserDetailsScreen(
      {super.key,
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
        required this.currentPage,
        required this.datacollection,
        required this.dateAndTime,
        required this.imagePath,
        required this.numberOfNodes,
        required this.userName,
        required this.trueTotalPriceSum,
        required this.falseTotalPriceSum,
        required this.totalQuantitySum,
        required this.totalPriceSum,
        required this.userNames,
        re});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool status = false;
  final TextEditingController _amountController = TextEditingController();
  List<String> filteredUserNames = [];
  final FocusNode _nameFocus = FocusNode();
  final TextEditingController _namegestController = TextEditingController();
  late TextEditingController _numberController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  bool isEditing = false; // Flag to indicate if editing mode is enabled

  bool isStatusAlih = false; // Track the "عليه" button status
  bool isStatusLah = false; // Track the "له" button status

  late DatabaseReference _ref;
  late pw.Font arabicFont;
  List<String> childData2 = [];
  List<String> reversedUserNames = [];
  int currentBalance = 0;
  int currentNumber = 0;
  int currentNumberForDeletedUser = 0;
  int newPrice = 0;
  int newNumber = 0;
  bool currentStatus = false;
  int valueOfAddedPrice = 0;
  bool currentStatusForDeletedUser = false;
  bool currentStatusForOne = false;
  int updatedNumber = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _numberController = TextEditingController(text: widget.number.toString());
    _descriptionController = TextEditingController(text: widget.description);
    _quantityController =
        TextEditingController(text: widget.quantity.toString());
    _priceController = TextEditingController(text: widget.price.toString());
    isStatusAlih = !widget.status;
    isStatusLah = widget.status;
    // Initialize _ref here based on the dataCollection received from the widget
    _ref = FirebaseDatabase.instance.ref().child(widget.datacollection);
    _namegestController.addListener(_onNameChanged);
    _nameFocus.addListener(_onFocusChanged);
  }

  Future<int> getNumberOfNodes() async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance
          .ref()
          .child(widget.datacollection)
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
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      return 0; // Return a default value in case of an error
    }
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

    final name = widget.name;

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
      widget.totalQuantitySum.toString(),
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

  void _toggleEditingMode() {
    // Toggle between view and edit mode
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveChanges() {
    // Save changes to Firebase and exit editing mode

    _updateUserDetailsInFirebase(); // Add this function to update Firebase
    _updateUserBalanceInFirebase();
    _toggleEditingMode();
  }

  void _exitEditingMode() {
    setState(() {
      isEditing = false;
      // Reset the text fields to their original values
      _nameController.text = widget.name;
      _numberController.text = widget.number.toString();
      _descriptionController.text = widget.description;
      _quantityController.text = widget.quantity.toString();
      _priceController.text = widget.price.toString();
      isStatusAlih = !widget.status;
      isStatusLah = widget.status;
    });
  }

  Future<void> fetchChildDataForDelete() async {
    try {
      late DatabaseReference childRef;
      childRef = FirebaseDatabase.instance
          .ref()
          .child(widget.datacollection)
          .child(widget.userName);
      final DatabaseEvent event = await childRef.once();
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
        childData2 = orderedChildData;

// print(orderedChildData);
// lastChild = orderedChildData.last;
        reversedUserNames = List.from(childData2.reversed);
        int indexOf = reversedUserNames.indexOf(widget.childData);

        String lastChild = reversedUserNames.last;
        reversedUserNames.indexOf(lastChild);
        if (kDebugMode) {
          print(reversedUserNames);
        }
        reversedUserNames.removeRange(indexOf, reversedUserNames.length);
        if (kDebugMode) {
          print(reversedUserNames);
        }
      });
    } catch (error) {
      if (kDebugMode) {
        print("Fetch Child Data Error in userData: $error");
      }
    }
    //_updateUserBalanceInFirebase();
  }

// UserDetailsScreen - Updated _deleteItem and _updateUserDetailsInFirebase methods
  Future<void> _deleteItem() async {
    // Show a confirmation dialog
    fetchChildDataForDelete();
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا العنصر؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't delete
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    // If the user confirms deletion
    if (shouldDelete == true) {
      // Get the reference based on the data collection

      final snapshot =
      await _ref.child(widget.userName).child(widget.childData).get();

      // try {
      if (snapshot.exists) {
        Map userData = snapshot.value as Map;
        {
          setState(() {
            currentNumberForDeletedUser = userData['price'];
            currentStatusForDeletedUser = userData['status'];
          });
        }
      }

      try {
        // Loop through each child in reversedUserNames list
        for (String childKey in reversedUserNames) {
          final snapshot =
          await _ref.child(widget.userName).child(childKey).get();
          // totalChange = 0;
          if (snapshot.exists) {
            // Map userData = snapshot.value as Map;
            // bool currentStatusForOne = userData['status'];
            setState(() {
              //   newNumber = currentBalance;
            });
          }
        }

        // Update balance for all users
        for (String childKey in reversedUserNames) {
          final snapshot =
          await _ref.child(widget.userName).child(childKey).get();
          if (snapshot.exists) {
            Map userData = snapshot.value as Map;
            int currentBalance = userData['number'];
            await _ref.child(widget.userName).child(childKey).update({
              if (currentStatusForDeletedUser == true)
                'number': currentBalance + currentNumberForDeletedUser,
              if (currentStatusForDeletedUser == false)
                'number': currentBalance - currentNumberForDeletedUser,
            });
          }
        }

        // Show a success message and navigate back
      } catch (error) {
        if (kDebugMode) {
          print("Error: $error");
        }
        // Handle error (e.g., show an error message)
      }

      if (widget.numberOfNodes == 1) {
        int indexOf = childData2.indexOf(widget.childData);
        childData2.remove(widget.childData);

        reversedUserNames = List.from(childData2.reversed);

        if (kDebugMode) {
          print(reversedUserNames);
        }
        reversedUserNames.removeRange(indexOf, reversedUserNames.length);
        if (kDebugMode) {
          print(reversedUserNames);
        }

        await _ref
            .child(widget.name)
            .child(widget.childData)
            .remove()
            .then((_) {
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NestedListViewDemo(
                userSignature: widget.userSignature,
              ),
            ),
          );
        }).catchError((error) {
          if (kDebugMode) {
            print("Error: $error");
          }
          // Handle error (e.g., show an error message)
        });
      } else {
        await _ref
            .child(widget.name)
            .child(widget.childData)
            .remove()
            .then((_) {
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NestedListViewDemo(
                userSignature: widget.userSignature,
              ),
            ),
          );
        }).catchError((error) {
          if (kDebugMode) {
            print("Error: $error");
          }
          // Handle error (e.g., show an error message)
        });
      }
    }
  }

  void updateStatus() {
    setState(() {
      status = isStatusLah;
    });
  }

  Future<void> fetchChildData() async {
    try {
      late DatabaseReference childRef;
      childRef = FirebaseDatabase.instance
          .ref()
          .child(widget.datacollection)
          .child(widget.userName);
      final DatabaseEvent event = await childRef.once();
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
        childData2 = orderedChildData;

// print(orderedChildData);
// lastChild = orderedChildData.last;
        reversedUserNames = List.from(childData2.reversed);
        int indexOf = reversedUserNames.indexOf(widget.childData);

        String lastChild = reversedUserNames.last;
        reversedUserNames.indexOf(lastChild);
        if (kDebugMode) {
          print(reversedUserNames);
        }
        reversedUserNames.removeRange(indexOf, reversedUserNames.length);
        if (kDebugMode) {
          print(reversedUserNames);
        }
      });
    } catch (error) {
      if (kDebugMode) {
        print("Fetch Child Data Error in userData: $error");
      }
    }
    //_updateUserBalanceInFirebase();
  }

  Future<void> _updateUserDetailsInFirebase() async {
    final snapshot =
    await _ref.child(widget.userName).child(widget.childData).get();

    // try {
    if (snapshot.exists) {
      Map userData = snapshot.value as Map;
      {
        setState(() {
          currentNumber = userData['price'];
          currentStatus = userData['status'];
          double newPriceDouble = double.parse(_priceController.text);
          newPrice = newPriceDouble.round();

          newNumber = newPrice - currentNumber;

          if (kDebugMode) {
            print("0000000 $newNumber");
          }
          if (kDebugMode) {
            print("print current status for user  : $currentStatus ");
          }
          if (currentStatus == true) {
            updatedNumber = int.parse(_numberController.text) - newNumber;
            if (kDebugMode) {
              print("$updatedNumber");
            }
            if (kDebugMode) {
              print(10 - -1);
            }
          } else if (currentStatus == false) {
            updatedNumber = int.parse(_numberController.text) + newNumber;
            if (kDebugMode) {
              print("$updatedNumber");
            }
          }
        });

        if (kDebugMode) {
          print("before  $updatedNumber");
        }

        setState(() {
          if (currentStatus == isStatusLah) {
            if (kDebugMode) {}
          } else {
            if (currentStatus == true) {
              // new balance = old balance + 2*price
              valueOfAddedPrice = newPrice * 2;
              if (kDebugMode) {
                print("edite is requaird for this case $valueOfAddedPrice ");
              }
            } else if (currentStatus == false) {
              // new balance = old balance - 2*price
              valueOfAddedPrice = (0 - 1) * newPrice * 2;
            }
            if (kDebugMode) {
              print(
                  "edite is requaird for this case  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
            }
          }

          updatedNumber = updatedNumber + valueOfAddedPrice;

          if (kDebugMode) {
            print("after  $updatedNumber");
          }
        });

        //
      }
    }

    if (kDebugMode) {
      print(
          "$currentNumber ------00000----000---0000--000---000----0000----00000---");
    }
    double newPriceDouble = double.parse(_priceController.text);
    newPrice = newPriceDouble.round();
    // Update the user details in Firebase
    await _ref.child(widget.userName).child(widget.childData).update({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'number': updatedNumber,
      'quantity': int.parse(_quantityController.text),
      'price': newPrice,
      'totalPrice': int.parse(_quantityController.text) * newPrice,
      "status": isStatusLah, // Update status based on the button states
    }).then((_) {
      // Show a success message and navigate back
      Fluttertoast.showToast(
        msg: "تم تحديث البيانات بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.of(context).pop();
    }).catchError((error) {
      if (kDebugMode) {
        print("Error: $error");
      }
      // Handle error (e.g., show an error message)
    });

    //_updateUserBalanceInFirebase();
  }

  Future<void> _updateUserBalanceInFirebase() async {
    int totalChange = 0; // Accumulate changes across all users

    try {
      // Loop through each child in reversedUserNames list
      for (String childKey in reversedUserNames) {
        final snapshot =
        await _ref.child(widget.userName).child(childKey).get();
        totalChange = 0;
        if (snapshot.exists) {
          Map userData = snapshot.value as Map;
          int currentBalance = userData['number'];
          bool currentStatusForOne = userData['status'];

          if (kDebugMode) {
            print("Current Balance for $childKey : $currentBalance");
            print("Current Status for $childKey : $currentStatusForOne");
            print("Current Balance for $childKey : $totalChange");
          }
        }
      }

      // Update balance for all users
      for (String childKey in reversedUserNames) {
        final snapshot =
        await _ref.child(widget.userName).child(childKey).get();
        if (snapshot.exists) {
          Map userData = snapshot.value as Map;
          int currentBalance = userData['number'];
          currentBalance = currentBalance + valueOfAddedPrice;
          await _ref.child(widget.userName).child(childKey).update({
            if (currentStatus == true) 'number': currentBalance - newNumber,
            if (currentStatus == false) 'number': currentBalance + newNumber,
          });
        }
      }

      // Show a success message and navigate back
    } catch (error) {
      if (kDebugMode) {
        print("Error: $error");
      }
      // Handle error (e.g., show an error message)
    }
  }

  void _showCalculatorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('الحاسبة'),
          content: CalculatorWidget(
            onResultChanged: (String result) {
              // Update the quantity controller directly
              // int resultOfCalculator = int.parse(result);
              _priceController.text = result;
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('الغاء'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss the keyboard when tapping outside the text fields or the bottom sheet
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.name),
          actions: [
            Visibility(
              visible: !isEditing,
              // Show the "Edit" button when not in edit mode
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  fetchChildData();
                  // _updateUserBalanceInFirebase();
                  _toggleEditingMode();
                  _updateUserBalanceInFirebase();
                },
              ),
            ),
            Visibility(
              visible: isEditing, // Show the "Save" button when in edit mode
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  _saveChanges();
                },
              ),
            ),
            Visibility(
              visible: isEditing, // Show the "Cancel" button when in edit mode
              child: IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  _exitEditingMode();
                },
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Directionality(
                textDirection: ui.TextDirection.rtl, // Right-to-Left direction
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(widget.dateAndTime,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                decoration:
                                const InputDecoration(labelText: 'الاسم'),
                                enabled: false, // Enable/disable editing
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextField(
                                controller: _numberController,
                                decoration:
                                const InputDecoration(labelText: 'الرصيد'),
                                enabled: false,
                                // Enable/disable editing
                                keyboardType: TextInputType.number,
                                // Set keyboard type to number
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  // Allow only digits
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                // Delete the item
                                _deleteItem();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                decoration:
                                const InputDecoration(labelText: 'السعر'),
                                enabled: isEditing,
                                // Enable/disable editing
                                keyboardType: TextInputType.number,
                                // Set keyboard type to number
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  // Allow only digits
                                ],
                              ),
                            ),
                            if (isEditing)
                              InkWell(
                                onTap: () {
                                  // Open the calculator when the calculator icon is clicked
                                  _showCalculatorDialog();
                                },
                                child: const Icon(
                                  Icons.calculate,
                                  size: 30.0,
                                  color: Colors.green,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text("  "),
                                  const Text("المجموع",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 17)),
                                  const SizedBox(height: 15),
                                  Text(
                                    widget.totalPrice.toString(),
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          controller: _descriptionController,
                          decoration:
                          const InputDecoration(labelText: 'تفاصيل'),
                          enabled: isEditing, // Enable/disable editing
                        ),
                        const SizedBox(height: 17),
// Add Image widget here to show the image from local storage

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              if (widget.imagePath.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.file(
                                      File(widget.imagePath),
                                      // height: 300, // Adjust the height of the image preview
                                      // width: 300, // Adjust the width of the image preview
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              } else {
                                // Handle the case where the image path is empty
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('لا توجد صورة'),
                                    content: const Text('هذه الصورة غير متاحة'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('تم'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: widget.imagePath.isNotEmpty
                                      ? Image.file(
                                    File(widget.imagePath),
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  )
                                      : const Icon(
                                    Icons.image,
                                    size: 150,
                                    color: Colors
                                        .grey, // Customize the color as needed
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 17),

                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isStatusLah)
                                Container(
                                    padding: const EdgeInsets.only(
                                        right: 12, left: 12, top: 5, bottom: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: const Text(
                                      'له',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    )),
                              if (!isStatusLah)
                                Container(
                                    padding: const EdgeInsets.only(
                                        right: 12, left: 12, top: 5, bottom: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: const Text(
                                      'عليه',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    )),
                            ]),

                        if (isEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: isStatusLah,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isStatusLah = newValue ?? false;
                                    updateStatus(); // Update status when checkbox changes
                                  });
                                },
                              ),
                              const Text(
                                'له',
                                style: TextStyle(fontSize: 15),
                              ),
                              const SizedBox(width: 20),
                              Checkbox(
                                value: !isStatusLah,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isStatusLah = !(newValue ?? true);
                                    updateStatus(); // Update status when checkbox changes
                                  });
                                },
                              ),
                              const Text(
                                'عليه',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        const SizedBox(height: 17),
                        Text(
                          widget.userSignature,
                          style:
                          const TextStyle(color: Colors.blue, fontSize: 18),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      loadArabicFontAndSharePDF(widget.datacollection);
                    },
                    child: const Text('مشاركة PDF'),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onNameChanged() {
    var enteredText = _namegestController.text.toLowerCase();
    setState(() {
      filteredUserNames = widget.userNames
          .where((userName) => userName.toLowerCase().contains(enteredText))
          .toList();
    });
  }

  void _onFocusChanged() {
    if (!_nameFocus.hasFocus) {
      setState(() {
        filteredUserNames.clear();
      });
    }
  }
}
