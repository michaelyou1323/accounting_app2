import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import 'AddItemForm.dart';
import 'VerticalListViewItem.dart';
import 'package:permission_handler/permission_handler.dart';

import 'changePassword.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const KeyboardVisibilityProvider(
      child: MaterialApp(
        home: NestedListViewDemo(userSignature: ""),
      ),
    ),
  );

}

class NestedListViewDemo extends StatefulWidget {
  final String userSignature;

  const NestedListViewDemo({super.key, required this.userSignature});

  @override
  _NestedListViewDemoState createState() => _NestedListViewDemoState();



}

class _NestedListViewDemoState extends State<NestedListViewDemo> {
  bool _showTextField = false;

  bool _showAdditionalActions = false;
  late SharedPreferences _prefs;
  var  currentPage2 ;
  final PageController _pageController = PageController();
  var currentPage = 0;
  List<String> pageTitles = ["FirstPage"]; // Titles for the pages
  List<String> childNodes = []; // List to store child nodes for each reference name
  List<String> searchNodes = []; // List to store child nodes for each reference name
  List<String> dataCollectionNodes = ["FirstPage"];
  List<String> dataCollections = ["FirstPage"];
  bool isLoading = true; // Add loading state
  List<String> filteredNodes = [];
  List<Node> nodes = [];
  bool permissionGranted = false;
  bool _wasAppClosed = false;
  bool warningText = false;
  String newReferenceName = '';
  // static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  // FlutterLocalNotificationsPlugin();
  // SharedPreferences? prefs ;
  // Update initState method to set currentPage based on pageTitles length


  @override
  void initState() {

    _requestPermission();


    super.initState();

    _initSharedPreferences();
    _checkAppStatus();
    // Load page titles when the widget is initialized
    _loadPageTitles();
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page?.round() ?? 0;
      });
    });

    fetchData();

    _getStoragePermission();

  }


  void search(String query) {
    // Filter childNodes list based on the query
    List<String> searchResults = searchNodes
        .where((node) => node.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {

      childNodes = searchResults;
      if (kDebugMode) {
        print("Search results: $searchResults");
      }
    });


  }

  Future<void> _requestPermission() async {
    if (await Permission.scheduleExactAlarm.request().isGranted
    //  &&  await Permission.storage.request().isGranted
    ) {
      // Permission is granted, you can now schedule exact alarms
      if (kDebugMode) {
        print('SCHEDULE_EXACT_ALARM permission is granted.');
      }
    } else {
      // Permission is not granted, handle accordingly
      if (kDebugMode) {
        print('SCHEDULE_EXACT_ALARM permission is not granted.');
      }
    }
  }




  Future<void> _checkAppStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool wasClosed = prefs.getBool('was_closed') ?? false;
    setState(() {
      _wasAppClosed = wasClosed;
    });
    if (_wasAppClosed) {
      // Reset app state here
    }
    prefs.setBool('was_closed', false); // Reset the flag
  }

  Future<void> done() async {
    if (kDebugMode) {
    }
  }

  void don() {
    // Handle alarm trigger logic here

    if (kDebugMode) {
    }
  }

// Modify the fetchData method to handle currentPage bounds
  Future<void> fetchData() async {
    try {
      setState(() {
        dataCollections.clear();
        pageTitles.clear();
        nodes.clear();
        isLoading = true;
      });

      await fetchCollectionNodes();

      if (dataCollections.isNotEmpty) {
        // Ensure currentPage is within bounds after fetching data
        currentPage = currentPage.clamp(0, dataCollections.length - 1);
        await fetchChildNodes(dataCollections[currentPage]);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error loading data: $error");
      }
      setState(() {
        isLoading = false;
      });
    }
  }



  int totalPriceSum = 0;
  String errorMessage = '';
  List<Map<dynamic, dynamic>> dataList = [];




  Future<void> fetchChildNodes(String referenceName) async {

    Future.delayed(const Duration(milliseconds:0), () {


      Completer<void> completer = Completer<void>();

      final usersRef = FirebaseDatabase.instance.ref().child(referenceName);

      // Clear the local list before adding new data
      setState(() {
        childNodes.clear();
      });

      // Listener for adding a child
      usersRef.onChildAdded.listen((event) {
        String? childName = event.snapshot.key;
        if (childName != null) {
          if (!childNodes.contains(childName)) {
            // Add the new user to the list
            childNodes.add(childName);
          }
        }
      }, onError: (error) {
        if (kDebugMode) {
          print("Users Error (onChildAdded): $error");
        }
        completer.completeError(error); // Complete with error
      }, onDone: () {
        // Reverse the order of childNodes after all children are added
        setState(() {

        });
        completer.complete(); // Complete without error
      });

      // Listener for changing a child
      usersRef.onChildChanged.listen(
            (event) {
          String? childName = event.snapshot.key;
          if(childName != null){
          }
          setState(() {

          });
        },
        onError: (error) {
          if (kDebugMode) {
            print("Users Error (onChildChanged): $error");
          }
        },
      );

      // Listener for removing a child
      usersRef.onChildRemoved.listen(
            (event) {
          String? childName = event.snapshot.key;
          if (childName != null) {
            if(mounted) {
              setState(() {
                childNodes.remove(
                    childName); // Remove the deleted child from the local list
              });
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("Users Error (onChildRemoved): $error");
          }
          completer.completeError(error); // Complete with error
        },
      );

      setState(() {

        searchNodes = childNodes;
      });

      return completer.future; // Return the Future
    });


  }





  Future<void> fetchCollectionNodes() async {

    setState(() {

      dataCollections.clear();
      pageTitles.clear();
      nodes.clear();
    });

    DatabaseReference? ref;
    ref = FirebaseDatabase.instance.ref().child("dataCollections");

    // Fetch data once from the database
    DatabaseEvent event = await ref.once();

    // Print the raw snapshot value
    if (kDebugMode) {
      print("Raw Snapshot Value: ${event.snapshot.value}");
    }

    // Check if the snapshot value is not null
    if (event.snapshot.value != null) {
      // Check the type of snapshot value
      if (event.snapshot.value is Map<dynamic, dynamic>) {
        // Case: snapshot value is a Map
        Map<dynamic, dynamic> dataCollectionsMap = event.snapshot.value as Map<dynamic, dynamic>;

        //   print("$dataCollectionsMap ---------------");

        // Iterate through the map entries and add each element to the dataCollections and pageTitles
        dataCollectionsMap.forEach((key, value) {
          if (value != null && value is Map<dynamic, dynamic> && value['value'] != null) {
            setState(() {
              dataCollections.add(value['value'].toString());
              pageTitles.add(value['value'].toString());

              // Store the node locally
              nodes.add(Node(key.toString(), value['value'].toString()));
            });
          }
        });
      } else if (event.snapshot.value is List<dynamic>) {
        // Case: snapshot value is a List
        List<dynamic> dataCollectionsList = event.snapshot.value as List<dynamic>;

        //  print("$dataCollectionsList ---------------");

        // Iterate through the list and add each element to the dataCollections and pageTitles
        for (var item in dataCollectionsList) {
          if (item != null && item is Map<dynamic, dynamic> && item['value'] != null) {
            setState(() {
              dataCollections.add(item['value'].toString());
              pageTitles.add(item['value'].toString());

              // Store the node locally
              nodes.add(Node(item['key'].toString(), item['value'].toString()));
            });
          }
        }
      } else {
        // Handle other cases if needed
        if (kDebugMode) {
          print("Unsupported data type: ${event.snapshot.value.runtimeType}");
        }
      }

      // Now you have the nodes stored locally with their key and value
      //  print("Nodes stored locally: $nodes");
    }

    // Print the retrieved data
    //  print("Data retrieved from dataCollections: $dataCollections -----");
    //  print("Data retrieved from pages: $pageTitles -----");
  }









  void addNewPageWithTitleAndReference(String title, String referenceName) {
    setState(() {
      // Add the new title and reference to the pageTitles and referenceNames lists
      /// pageTitles.add(title);
      // dataCollections.add(referenceName);
    });
  }



  Future<void> _showAddPageDialog(BuildContext context) async {
    String newReferenceName = '';
    bool warningText = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إضافة حقل بيانات جديد'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'أدخل اسم الحقل',
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
                        newReferenceName = value;
                      }
                    },
                  ),
                  if (warningText)
                    const Text(
                      'يرجى عدم استخدام الرموز /# . \ [ \ ] \$ ',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {

                    if (newReferenceName.isNotEmpty && warningText == false) {
                      DatabaseReference? ref;
                      ref = FirebaseDatabase.instance.ref().child("dataCollections");

                      // Fetch data once from the database
                      DatabaseEvent event = await ref.once();

                      // Get the current number of elements in the collection
                      int numberOfElements = 1;

                      if (event.snapshot.value != null) {
                        if (event.snapshot.value is List) {
                          // Handle the case where the value is a list
                          numberOfElements = (event.snapshot.value as List).length;
                        }
                      }

                      // Increment the number of elements
                      //numberOfElements++;
                      //    print(numberOfElements);
                      // Set the new element with the incremented key
                      ref.child("$numberOfElements").set({"value": newReferenceName});
                      setState(() {
                        //  currentPage = dataCollections.length ;
                        fetchData();
                        currentPage = 0;
                      });
                      Navigator.of(context).pop();
                    } else {
                      Fluttertoast.showToast(msg: 'برجاء اضافة اسم الحقل بشكل صحيحس');
                    }

                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }





  Future<void> deleteRecordByValue() async {
    final ref = FirebaseDatabase.instance.ref();
    DatabaseReference dataCollectionsRef = ref.child("dataCollections");

    final DatabaseEvent event = await dataCollectionsRef.once();
    final DataSnapshot snapshot = event.snapshot;

    if (kDebugMode) {
      print('Snapshot value: ${snapshot.value}');
    }

    if (snapshot.value != null && snapshot.value is List) {

      // Find the node associated with the specified value
      Node? nodeToDelete;
      for (Node node in nodes) {
        if (node.value == dataCollections[currentPage]) {
          nodeToDelete = node;
          break;
        }
      }

      if (nodeToDelete != null) {
        // Delete the record using the found key
        await dataCollectionsRef.child(nodeToDelete.key).remove();

        if (currentPage >= 0 && currentPage < pageTitles.length) {
          setState(() {
            fetchData();
          });

          // print(nodeToDelete);
          if (kDebugMode) {
            print('Record with value ${dataCollections[currentPage]} deleted successfully.');
          }

          // Update local lists after deletion
          setState(() {
            pageTitles.removeAt(currentPage);
            dataCollections.removeAt(currentPage);
            nodes.remove(nodeToDelete);
          });
        } else {
          if (kDebugMode) {
            print('Invalid currentPage: $currentPage');
          }
        }
      } else {
        if (kDebugMode) {
          print('Record with value ${dataCollections[currentPage]} not found.');
        }
      }
    } else {
      if (kDebugMode) {
        print('DataCollections is empty or null.');
      }
    }
  }




  Future<void> requestPermission() async {
    final PermissionStatus status = await Permission.storage.request();
    if (status != PermissionStatus.granted) {

    }
  }


  Future _getStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      setState(() {
        permissionGranted = true;
      });
    }
  }


  Future<void> _backupData() async {
    if (kDebugMode) {
      print("Backup data function called at ${DateTime.now()}");
    }


    try {
      // Fetch data from Firebase Realtime Database
      DatabaseEvent event =
      await FirebaseDatabase.instance.ref().once();
      DataSnapshot snapshot = event.snapshot;

      // Convert fetched data to JSON
      String jsonData = json.encode(snapshot.value);

      // Get the directory path for storing persistent app data
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      // Define the file path within the app's documents directory
      String filePath = '$appDocPath/backup.json';

      // Write JSON data to file
      File file = File(filePath);
      file.writeAsStringSync(jsonData);

      // Store the file path in preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('backupFilePath', filePath);

      // Display a dialog with the file name and path




      Fluttertoast.showToast(
        msg: 'تم عمل النسخة الاحتياطية',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );



    } catch (error) {
      if (kDebugMode) {
        print('خطأ في النسخ: $error');
      }
      Fluttertoast.showToast(
        msg: 'حدث خطأ',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    // }
    if (kDebugMode) {
      print("Backup data function completed at ${DateTime.now()}");
    }
    //});
  }

  Future<void> _uploadBackupData(BuildContext context) async {
    BuildContext dialogContext = context;
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          backgroundColor: Colors.white,
          elevation: 4.0,
          title: const Text(
            "رفع نسخة إحتياطية",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "هل أنت متأكد أنك تريد استبدال بياناتك بأخر نسخة احتياطية ؟",
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.red),
              ),
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.green),
              ),
              child: const Text("نعم"),
            ),
          ],
        );

      },
    )?? false; // Add a default value of false if confirmed is null

    if (confirmed) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? backupFilePath = prefs.getString('backupFilePath');

        // Check if a backup file path is available
        if (backupFilePath != null && backupFilePath.isNotEmpty) {
          String jsonData = await File(backupFilePath).readAsString();
          Map<String, dynamic> data = json.decode(jsonData);

          // Upload data to Firebase
          await FirebaseDatabase.instance.ref().set(data);
          Fluttertoast.showToast(
            msg: 'لا يوجد نسخة لرفعها',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          // Show success dialogue

          showDialog(
            context: dialogContext,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("تم تحديث البيانات بنجاح"),
                content: const Text("برجاء غلق التطبيق واعادة فتحه"),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        // Restart the app
                        // RestartApp.restartApp(context);
                        Phoenix.rebirth(context);
                      },
                      child: const Text("تم", style: TextStyle(color: Colors.green),)
                  ),
                ],
              );
            },
          )

              .then((value) =>  Phoenix.rebirth(context));
        } else {
          Fluttertoast.showToast(
            msg: 'لا يوجد نسخة لرفعها',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } catch (error) {
        if (kDebugMode) {
          print('Error uploading backup data: $error');
        }
        Fluttertoast.showToast(
          msg: 'حدث خطأ.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }


  void reloadCurrentPageData() {
    if (dataCollections.isNotEmpty && currentPage >= 0 && currentPage < dataCollections.length) {
      fetchChildNodes(dataCollections[currentPage]);
    }
  }

  // void _filterNodes(String query) {
  //   setState(() {
  //     filteredNodes = childNodes
  //         .where((node) => node.toLowerCase().contains(query.toLowerCase()))
  //         .toList();
  //   });
  // }




  Future<void> _loadPageTitles() async {
    SharedPreferences prefs =
    await SharedPreferences.getInstance();
    setState(() {
      pageTitles = prefs.getStringList('pageTitles') ?? [];
    });
  }




  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPage2 = _prefs.getInt('currentPage') ?? 0; // Get last opened page
    });
    //  _pageController = PageController(initialPage: currentPage); // Initialize PageController

    // Delay the call to animateToPage

    await Future.delayed(const Duration(milliseconds: 2000), () {
      _pageController.animateToPage(
        currentPage2,
        duration: const Duration(milliseconds: 1300), // Adjust the duration as needed
        curve: Curves.easeInOut, // Adjust the curve as needed

      );
      currentPage = currentPage2;
    });


  }

  Future<void> _saveCurrentPage(int page) async {
    currentPage = page;
    await _prefs.setInt('currentPage', currentPage);
    // print("saved page is  $page -------------========== -------------========== -------------========== -------------========== -------------========== -------------========== -------------==========");
  }



  List<VerticalListViewItem> pages = [];

  @override
  void dispose() {
    final fetchChildNodesRef = FirebaseDatabase.instance.ref().child(dataCollections[currentPage]);

    fetchChildNodesRef.onChildAdded.drain();
    fetchChildNodesRef.onChildChanged.drain();
    fetchChildNodesRef.onChildRemoved.drain();

    super.dispose();
  }






  @override
  Widget build(BuildContext context) {
    //   _NestedListViewDemoState.scheduleNotification(context);
    // childNodes.reversed;
    return WillPopScope(
        onWillPop: () async {
          // _lastPage();

          _backupData();

          Future.delayed(const Duration(milliseconds: 200), () {

            SystemNavigator.pop();
          });

          return true;
        },
        child: Scaffold(
          appBar:AppBar(
            automaticallyImplyLeading: false,
            title: _showTextField
                ?
            Directionality(
                textDirection: ui.TextDirection.rtl, // Right-to-Left direction
                child:
                TextField(
                  autofocus: true, // Set autofocus to true
                  decoration: const InputDecoration(
                    hintText: 'بحثـــ....',
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) {
                    search(value);
                  },
                  onSubmitted: (value) {

                  },
                ) )
                : GestureDetector(
              onTap: () {

              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
                child:
                Center(
                  child:  Text(
                    pageTitles.isNotEmpty ? pageTitles[currentPage] : 'No',
                    style: const TextStyle(color: Colors.black, fontSize: 25),
                  ),
                ),
              ),
              // ),
            ),
            actions: <Widget>[

              _showTextField
                  ?
              IconButton(
                icon:
                const Icon(Icons.close),

                onPressed: () {
                  setState(() {
                    _showTextField = !_showTextField;
                    childNodes = searchNodes;
                  });
                },
              )
                  :

              IconButton(
                icon: const Icon(Icons.search_sharp),
                onPressed: () {
                  setState(() {
                    _showTextField = !_showTextField; // Toggle the text field visibility

                    // if ( _showTextField == true){
                    //   fetchChildNodes(dataCollections[currentPage]);
                    // }

                  });
                },
              ),




              IconButton(
                icon: _showAdditionalActions
                    ? const Icon(Icons.close)
                    : const Icon(Icons.menu_open,size: 32,color: Colors.green,),
                onPressed: () {
                  setState(() {

                    _showAdditionalActions = !_showAdditionalActions;
                  });
                },
              ),




              AnimatedCrossFade(
                firstChild:  const SizedBox(),
                secondChild:
                Row(
                  children: [

                    IconButton(
                      icon: const Icon(Icons.vpn_key_outlined),
                      color: Colors.red,
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cloud_download),
                      color: Colors.green,
                      onPressed: () {
                        _backupData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.backup_sharp),
                      color: Colors.orange,
                      onPressed: () {
                        _uploadBackupData(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        _showAddPageDialog(context);
                      },
                    ),


                  ],
                ),
                crossFadeState: _showAdditionalActions
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              :
          GestureDetector(
            onTap: () {
              if (_showTextField == true){
                setState(() {
                  _showTextField = !_showTextField;
                  childNodes = searchNodes;
                });
              }

            },
            child:

            PageView.builder(
              controller: _pageController,
              itemCount: pageTitles.length,
              itemBuilder: (context, index) {

                if (index < dataCollections.length) {
                  final page = VerticalListViewItem(
                    key: UniqueKey(),
                    userNames: childNodes,
                    userSignature: widget.userSignature,
                    dataCollection: dataCollections[index],
                    currentPage: index,
                    dataCollections: dataCollections, // Use index instead of currentPage

                  );

                  pages.add(page);

                  return page;
                } else {
                  return Center(
                    child: Text('Data not available for index $index'),
                  );
                }
              },
              // Modify the onPageChanged callback to handle currentPage bounds

              onPageChanged: (int page) async {
                await _saveCurrentPage(page); // Save current page
                setState(() {
                  currentPage = page.clamp(0, pageTitles.length - 1);
                });
                if (dataCollections.isNotEmpty) {
                  childNodes.clear();
                  fetchChildNodes(dataCollections[currentPage]);
                }
              },
            ),),
          floatingActionButton: Container(

            margin: const EdgeInsets.only(bottom: 65),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                backgroundColor: Colors.grey[50],
                onPressed: () {
                  if (dataCollections.isEmpty) {
                    // Show a temporary dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('اضف حقل اولا'),
                          content: Text('اضف حقل قبل بدء المعاملات'),
                        );
                      },
                    );
                    // Close the dialog after 2 seconds
                    // Future.delayed(Duration(milliseconds: 500), () {
                    // Navigator.of(context).pop();

                    Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => NestedListViewDemo(userSignature: widget.userSignature,

                            )));
                    // });
                  } else {
                    // Show the bottom sheet to add an item
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return FractionallySizedBox(
                          heightFactor: 0.9,
                          child: AddItemForm(
                            userSignature: widget.userSignature,
                            dataCollections: dataCollections,
                            currentPage: currentPage,
                            userNames: childNodes,
                            userOrAll: 1,
                            userName: ' ',
                            onSheetClosed: () {
                              setState(() {
                                childNodes.clear();
                                reloadCurrentPageData();
                              });
                            },
                            lastChild: ' ',
                          ),
                        );
                      },
                    ).then((_) {
                      setState(() {
                        // fetchChildNodes(dataCollections[currentPage]);
                        // Update state if necessary after the bottom sheet is closed
                      });
                    });
                  }
                },
                child:  Icon(Icons.add, color: Colors.indigo[500],size: 32,),
              ),
            ),
          ),
        )

    );
  }




}




class Node {
  String key;
  String value;

  Node(this.key, this.value);
}



