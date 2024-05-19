import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'CalculatorWidget.dart';

class AddItemForm extends StatefulWidget {
  final List<String> userNames;
  final String userSignature;
  final List<String> dataCollections;
  final int currentPage;
  final int userOrAll;
  final String userName;

  // final Function onSheetClosed; // Add this line
  final VoidCallback onSheetClosed;
  final String lastChild;

  const AddItemForm({
    super.key,
    required this.userSignature,
    required this.dataCollections,
    required this.currentPage,
    required this.userNames,
    required this.userOrAll,
    required this.userName,
    required this.onSheetClosed,
    required this.lastChild, // Add this line
  });

  @override
  _AddItemFormState createState() =>
      _AddItemFormState(dataCollections, userSignature, currentPage);
}

class _AddItemFormState extends State<AddItemForm> {
  DatabaseReference? _ref;
  final List<String> dataCollections;
  final String userSignature;
  final int currentPage;
  bool warningText = false;

  bool isFor =
  false; // Assuming "له" corresponds to "For" and "عليه" corresponds to "Against"
  _AddItemFormState(this.dataCollections, this.userSignature, this.currentPage);

  final TextEditingController _nameController = TextEditingController();

  // final TextEditingController _calculatorResultController = TextEditingController();
  List<String> filteredUserNames = [];
  final FocusNode _nameFocus = FocusNode();

  // final TextEditingController _numberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // final TextEditingController _quantityController = TextEditingController();
  bool status = false;
  int balance = 0;
  String? imagePath;
  int timeForNow = DateTime.now().millisecondsSinceEpoch;

  List<String> childData = [];
  List<String> reversedUserNames = [];

  String lastChild1 = " ";

  @override
  void initState() {
    super.initState();
    _ref = FirebaseDatabase.instance
        .ref()
        .child(widget.dataCollections[currentPage]);

    _nameController.addListener(_onNameChanged);
    _nameFocus.addListener(_onFocusChanged);
    // print(widget.dataCollections);
    // print(widget.lastChild);
    // fetchChildData();
  }

  @override
  void dispose() {
    // _calculatorResultController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      final picker = ImagePicker();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('اختيار صورة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the dialog
                    final pickedFile =
                    await picker.pickImage(source: ImageSource.camera);
                    _handleImageSelection(pickedFile);
                  },
                  child: const Text('التقاط صورة من الكاميرا'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the dialog
                    final pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                    _handleImageSelection(pickedFile);
                  },
                  child: const Text('اختيار صورة من المعرض'),
                ),
              ],
            ),
          );
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    }
  }

  void _handleImageSelection(XFile? pickedFile) {
    setState(() {
      if (pickedFile != null) {
        imagePath = pickedFile.path;
        Fluttertoast.showToast(
          msg: "Image selected: ${pickedFile.path}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        imagePath = "";
      }
    });
  }

  void _onNameChanged() {
    if (widget.userOrAll == 1) {
      final enteredText = _nameController.text.toLowerCase();
      setState(() {
        filteredUserNames = widget.userNames
            .where((userName) => userName.toLowerCase().contains(enteredText))
            .toList();
      });
    } else {
      // _nameController = widget.userName
    }
  }

  void _onFocusChanged() {
    if (!_nameFocus.hasFocus) {
      setState(() {
        filteredUserNames.clear();
      });
    }
  }

  void updateStatus() {
    setState(() {
      status = isFor;
    });
  }

  Widget _displaySelectedImage() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.center,
        child: Image.file(
          File(imagePath!), // Assuming imagePath contains the file path
          height: 150,
          width: 150,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(); // Return an empty container if no image is selected
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

  Future<void> fetchChildData() async {
    try {
      // String user = widget.userName;
      // print("$user youssernameyoussernameyoussernameyoussernameyoussernameyoussernameyoussernameyoussername");
      final ref = FirebaseDatabase.instance
          .ref()
          .child(widget.dataCollections[currentPage])
          .child(_nameController.text);
      // final snapshot = await ref

      final DatabaseEvent event = await ref.once();

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
        childData = orderedChildData;

        reversedUserNames = List.from(childData.reversed);

        if (reversedUserNames.isNotEmpty) {
          lastChild1 = reversedUserNames.first;

          //   print("$reversedUserNames 999987899999999999");
          // print(lastChild1);
        } else {
          // Handle the case when reversedUserNames is empty
          // For example, you can assign a default value to lastChild1
          lastChild1 = "null";
          if (kDebugMode) {
            print("reversedUserNames is empty");
          }
        }
      });
    } catch (error) {
      if (kDebugMode) {
        print("Fetch Child Data Error in userData: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ref == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Text(
              'إضافة عميل',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          if (widget.userOrAll == 0)
            Text(widget.userName),

          if (widget.userOrAll == 1)
            Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Check for forbidden characters
                      if (value.contains(RegExp(r'[\/#.$\[\]]'))) {
                        setState(() {
                          warningText = true;
                        });
                      } else {
                        setState(() {
                          warningText = false;
                        });
                        _nameController.text = value;
                      }
                    },
                  ),
                  if (warningText)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'يرجى عدم استخدام الرموز /# . \ [ \ ] \$ ',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          if (filteredUserNames.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: filteredUserNames.length,
                itemBuilder: (context, index) {
                  final userName = filteredUserNames[index];
                  return ListTile(
                    title: Text(userName),
                    onTap: () {
                      setState(() {
                        if (widget.userOrAll == 1) {
                          _nameController.text = userName;
                        } else {
                          _nameController.text = widget.userName;
                        }

                        filteredUserNames.clear();
                        _nameFocus.unfocus(); // Hide keyboard
                      });
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 8.0),
          // Directionality(
          //   textDirection: ui.TextDirection.ltr,
          //   child: buildNumericTextField("المبلغ", _numberController),
          // ),
          // const SizedBox(height: 8.0),
          Directionality(
            textDirection: ui.TextDirection.rtl,
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'تفاصيل',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Directionality(
            textDirection: ui.TextDirection.rtl,
            child: buildNumericTextField("سعر", _priceController),
          ),
          const SizedBox(height: 8.0),

          // Directionality(
          //   textDirection:  ui.TextDirection.ltr,
          //   child: buildNumericTextField("الكمية", _quantityController),
          // ),

          const SizedBox(height: 8.0),
          Row(
            children: [
              InkWell(
                onTap: _captureImage,
                child: const Icon(
                  Icons.camera_alt,
                  size: 30.0,
                  color: Colors.blue,
                ),
              ),
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
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: isFor,
                onChanged: (bool? newValue) {
                  setState(() {
                    isFor = newValue ?? false;
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
                value: !isFor,
                onChanged: (bool? newValue) {
                  setState(() {
                    isFor = !(newValue ?? true);
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

          _displaySelectedImage(),

          ElevatedButton(
            onPressed: () async {
              if(!warningText){
                functionForButton();
              }

            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
            ),
            child: const Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Text('إضافة العميل',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNumericTextField(
      String labelText, TextEditingController controller) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: labelText,
          alignLabelWithHint: true,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
            Fluttertoast.showToast(
              msg: "من فضلك ادخل رقم صحيح",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            controller.clear();
          }
        },
      ),
    );
  }

  bool validateFields() {
    if (widget.userOrAll == 1) {
      if (
      // _quantityController.text.isEmpty ||
      _nameController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "من فضلك ادخل كل القيم بشكل صحيح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      }
    } else {
      if (
      // _quantityController.text.isEmpty ||
      // _nameController.text.isEmpty ||
      _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "من فضلك ادخل كل القيم بشكل صحيح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      }
    }
    return true;
  }

  Future functionForButton() async {
    //  print("$lastChild1 before");
    await fetchChildData(); // Wait for fetchChildData to complete
    //  print("$lastChild1 after");
    if (validateFields()) {
      // int totalPrice = 1 * int.parse(_priceController.text);
      double totalDouble = 1 * double.parse(_priceController.text);
      int totalPrice = totalDouble.round(); // Convert the result to an integer

      setState(() {
        fetchChildData();
      });
      if (widget.userOrAll == 1) {
        Future<Map<String, int>> fetchUserData() async {
          //  print("$lastChild1 last one");
          final ref = FirebaseDatabase.instance.ref();
          final snapshot = await ref
              .child(widget.dataCollections[currentPage])
              .child(_nameController.text)
              .child(lastChild1)
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
            'number': 0,
          };
        }

        Map<String, dynamic> userData = await fetchUserData();

        int number = 0; // Default value in case parsing fails
        if (userData['number'] != null) {
          // Check if userData['number'] is a String
          if (userData['number'] is String) {
            // Try parsing the String to an int
            try {
              number = int.parse(userData['number']);
            } catch (e) {
              Fluttertoast.showToast(
                msg: "  $e حدث خطا برجاء مراجعة البيانات : ",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0,
              );

              if (kDebugMode) {
                print( "  $e حدث خطا برجاء مراجعة البيانات : ");
              }
            }
          } else if (userData['number'] is int) {
            // If it's already an int, assign it directly
            number = userData['number'];
          } else {
            Fluttertoast.showToast(
              msg: "حدث خطا برجاء مراجعة البيانات",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: "حدث خطا برجاء مراجعة البيانات",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }

        if (status == true) {
          setState(() {
            balance = number - totalPrice;
          });
        } else if (status == false) {
          balance = number + totalPrice;
        } else {
          Fluttertoast.showToast(
            msg: "حدث خطا برجاء مراجعة البيانات",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
        // print("$number your number is here ");
        // print("$totalPrice your price is here ");
        // print("$balance your balancce is here ");

        //    print(_nameController.text + "1111111111111");
        DateTime now = DateTime.now();

        String formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(now);

        imagePath ??= "";
        String name = _nameController.text;
        // Use imagePath in the push function
        _ref?.child(name).child("$timeForNow").set({
          'name': _nameController.text,
          'number': balance,
          'description': _descriptionController.text,
          'quantity': 1,
          'price': double.parse(_priceController.text),
          'totalPrice': totalPrice,
          'status': status,
          'userSignature': widget.userSignature,
          'dateAndTime': formattedDate,
          'imagePath': imagePath, // Use imagePath here
          // Add the date and time
        });
      } else {
        Future<Map<String, int>> fetchUserData() async {
          final ref = FirebaseDatabase.instance.ref();
          final snapshot = await ref
              .child(widget.dataCollections[currentPage])
              .child(widget.userName)
              .child(widget.lastChild)
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
            'number': 0,
          };
        }

        Map<String, int> userData = await fetchUserData();
        int? number = 0; // Default value in case parsing fails
        if (userData['number'] != null) {
          // Check if userData['number'] is a String
          if (userData['number'] is String) {
            // Try parsing the String to an int
            try {
              number = userData['number'];
            } catch (e) {
              // Handle the case where parsing fails
              // print('Error parsing userData['number']: $e');
              // You can assign a default value or handle the error as needed
            }
          } else if (userData['number'] is int) {
            // If it's already an int, assign it directly
            number = userData['number'];
          } else {
            // Handle unexpected type if needed
            // print('Unexpected type for userData['number']: ${userData['number'].runtimeType}');
            // You can assign a default value or handle the unexpected type as needed
          }
        }

        if (status == true) {
          setState(() {
            balance = (number! - totalPrice);
          });
        } else {
          balance = (number! + totalPrice);
        }

        _nameController.text = widget.userName;
        //   print(_nameController.text + "00000000");
        DateTime now = DateTime.now();
        String formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(now);

        imagePath ??= "";

        //   String dateWithoutSymbols = formattedDate.replaceAll(RegExp(r'[^\w\s]'), ' ');
        // Use imagePath in the push function
        _ref?.child(_nameController.text).child("$timeForNow").set({
          'name': _nameController.text,
          'number': balance,
          'description': _descriptionController.text,
          'quantity': 1,
          'price': double.parse(_priceController.text),

          'totalPrice': totalPrice,
          'status': status,
          'userSignature': widget.userSignature,
          'dateAndTime': formattedDate,
          'imagePath': imagePath, // Use imagePath here
          // Add the date and time
        });
      }
      //
      //
      // print(name + "000000099999990090");

      // Get the current date and time

      Fluttertoast.showToast(
        msg: "تمت إضافة العميل بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      setState(() {
        Navigator.pop(context, true);
        widget.onSheetClosed();
      });

      // Call the callback when the sheet is closed
      //  widget.onSheetClosed();
    }
  }
}
