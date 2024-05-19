import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ExpandableListViewItem.dart';

class VerticalListViewItem extends StatefulWidget {
  final List<String> userNames;
  final String userSignature;
  final String dataCollection;
  final int currentPage;
  final List<String> dataCollections;

  const VerticalListViewItem({
    super.key,
    required this.userNames,
    required this.userSignature,
    required this.dataCollection,
    required this.currentPage,
    required this.dataCollections,
  });

  @override
  _VerticalListViewItemState createState() => _VerticalListViewItemState();
}

class _VerticalListViewItemState extends State<VerticalListViewItem> {
  late DatabaseReference _databaseReference;
  Map<String, int> userTrueTotalPriceSums = {};
  Map<String, int> userFalseTotalPriceSums = {};
  Map<String, int> userQuantities = {};
  Map<String, int> userPrices = {};
  int totalTrue = 0;
  int totalFalse = 0;
  late int localTotalTrue;
  late int localTotalFalse;
  bool allDataFetched = true;
  bool showCard = false;
  Set<String> processedUsers = {};

  List<String> reversedUserNames = [];

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref();
    localTotalTrue = 0;
    localTotalFalse = 0;
    fetchDataWithDelay();
  }

  Future<void> fetchDataWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await fetchDataForAllUsers();
    calculateLocalTotalSums();
  }

  Future<void> fetchDataForAllUsers() async {
    List<String> userNamesCopy =
    List.from(widget.userNames); // Create a copy of the list

    for (var userName in userNamesCopy) {
      await fetchData(userName);
    }

    if (mounted) {
      setState(() {
        showCard = true;
      });
    }
  }

  Future<void> fetchData(String userName) async {
    try {
      await _databaseReference
          .child(widget.dataCollection)
          .child(userName)
          .onValue
          .first
          .then((event) async {
        if (!mounted) return;
        DataSnapshot dataSnapshot = event.snapshot;
        Map<dynamic, dynamic>? values =
        dataSnapshot.value as Map<dynamic, dynamic>?;

        if (values != null && values.isNotEmpty) {
          updateSums(userName, values);

          int totalQuantitySum = getTotalQuantitySumForUser(userName, values);
          int totalPriceSum = getTotalPriceSumForUser(userName, values);

          if (mounted) {
            setState(() {
              userQuantities[userName] = totalQuantitySum;
              userPrices[userName] = totalPriceSum;
            });
          }
        }

        calculateTotalSums();
        updateLocalTotalSums();
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching data for $userName: $error');
      }
    }

    reversedUserNames = List.from(widget.userNames.reversed);
  }

  int getTotalQuantitySumForUser(
      String userName, Map<dynamic, dynamic> values) {
    int totalQuantitySum = 0;

    values.forEach((key, value) {
      int quantity = value['quantity'] ?? 0;
      totalQuantitySum += quantity;
    });

    return totalQuantitySum;
  }

  int getTotalPriceSumForUser(String userName, Map<dynamic, dynamic> values) {
    int totalPriceSum = 0;

    values.forEach((key, value) {
      int totalPrice = value['price'] ?? 0;
      totalPriceSum += totalPrice;
    });

    return totalPriceSum;
  }

  int getTotalFalseTotalPriceSumAcrossUsers() {
    return userFalseTotalPriceSums.values.reduce((a, b) => a + b);
  }

  int getTotalTrueTotalPriceSumAcrossUsers() {
    return userTrueTotalPriceSums.values.reduce((a, b) => a + b);
  }

  void calculateTotalSums() {
    if (mounted) {
      setState(() {
        totalTrue = getTotalTrueTotalPriceSumAcrossUsers();
        totalFalse = getTotalFalseTotalPriceSumAcrossUsers();
        updateLocalTotalSums();
      });
    }
  }

  void updateLocalTotalSums() {
    if (mounted) {
      setState(() {
        // localTotalTrue = totalTrue;
        // localTotalFalse = totalFalse;
      });
    }
  }

  void updateSums(String userName, Map<dynamic, dynamic> values) {
    int trueSum = 0;
    int falseSum = 0;
    values.forEach((key, value) {
      int totalPrice = value['totalPrice'] ?? 0;
      bool status = value['status'] ?? false;
      if (status) {
        trueSum += totalPrice;
      } else {
        falseSum += totalPrice;
      }
    });

    userTrueTotalPriceSums[userName] = trueSum;
    userFalseTotalPriceSums[userName] = falseSum;

    calculateSums();
  }

  void calculateSums() {
    if (mounted) {
      setState(() {
        totalTrue = userTrueTotalPriceSums.isNotEmpty
            ? userTrueTotalPriceSums.values.reduce((a, b) => a + b)
            : 0;
        totalFalse = userFalseTotalPriceSums.isNotEmpty
            ? userFalseTotalPriceSums.values.reduce((a, b) => a + b)
            : 0;
        // localTotalTrue = totalTrue;
        // localTotalFalse = totalFalse;
      });
    }
  }

  void calculateLocalTotalSums() {
    for (var userName in widget.userNames) {
      int userTrueSum = userTrueTotalPriceSums[userName] ?? 0;
      int userFalseSum = userFalseTotalPriceSums[userName] ?? 0;
      int difference1 =
      (userTrueSum - userFalseSum).abs(); // Absolute difference
      int difference2 = (userFalseSum - userTrueSum).abs();
      if (userTrueSum > userFalseSum) {
        localTotalTrue += difference1;
      } else if (userTrueSum < userFalseSum) {
        localTotalFalse += difference2;
      }
    }

    if (mounted) {
      setState(() {
        if (kDebugMode) {
          print("Local Total True: $localTotalTrue");
          print("Local Total False: $localTotalFalse");
        }
      });
    }
  }

  int calculateTotalSum(Map<String, int> map) {
    int totalSum = 0;
    map.forEach((key, value) {
      totalSum += value;
    });
    return totalSum;
  }

  @override
  Widget build(BuildContext context) {
    int netNumber = 0;
    if (localTotalTrue > localTotalFalse) {
      netNumber = localTotalTrue - localTotalFalse;
    }
    if (localTotalFalse > localTotalTrue) {
      netNumber = localTotalFalse - localTotalTrue;
    }
    reversedUserNames = List.from(widget.userNames.reversed);

    // int totalSum = localTotalTrue + localTotalFalse;

    return Container(
        color: Colors.indigo[400], // Set the color of the scaffolds
        child: Scaffold(
          body: allDataFetched
              ? widget.userNames.isNotEmpty
              ? ListView.builder(
            itemCount: widget.userNames.length,
            itemBuilder: (context, index) {
              String userName = widget.userNames[index];
              return Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 5),
                  child: Card(
                    elevation: 5,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ExpandableListViewItem(
                            userNames: widget.userNames,
                            userName: userName,
                            userSignature: widget.userSignature,
                            dataCollection: widget.dataCollection,
                            currentPage: widget.currentPage,
                            trueTotalPriceSum:
                            userTrueTotalPriceSums[userName] ?? 0,
                            falseTotalPriceSum:
                            userFalseTotalPriceSums[userName] ??
                                0,
                            onTotalPriceSumsUpdated:
                                (trueTotal, falseTotal) {
                              setState(() {});
                            },
                            userPrices: userPrices[userName] ?? 0,
                            quantities: userQuantities[userName] ?? 0,
                            dataCollections: widget.dataCollections,
                            totalPriceSum: () {},
                          ),
                        ),
                      ],
                    ),
                  ));
            },
          )
              : const Center(
            child: Text(
              'لا يوجد بيانات لعرضها',
              style: TextStyle(
                  fontSize: 27.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          )
              : const Center(child: CircularProgressIndicator()),


          bottomNavigationBar: BottomAppBar(

            // height: 60,
            //  elevation: 8,
            // Add elevation for a premium look
            color: Colors.indigo[400],
            // Match the system navigation bar color
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  //  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'عليك',
                      style: TextStyle(
                        fontSize: 19.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[300],
                      ),
                    ),
                    Text(
                      '$localTotalTrue',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    localTotalTrue > localTotalFalse
                        ?
                    const Expanded(
                      child: Text(
                        'صافي ( عليك )',
                        style: TextStyle(
                          fontSize: 19.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    )
                        :
                    const Expanded(
                      child: Text(
                        'صافي( ليك )',
                        style: TextStyle(
                          fontSize:  19.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: Text(
                        '$netNumber',
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  // mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ليك',
                      style: TextStyle(
                        fontSize: 19.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '$localTotalFalse',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
