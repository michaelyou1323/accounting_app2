import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // For sharing file

class TransactionList extends StatefulWidget {
  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<Transaction> transactions = [];
  String? jsonFilePath; // Path to the selected JSON file
  Map<String, dynamic> originalJsonData = {}; // Store the full original JSON data

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result != null) {
      // Get the selected file path
      File file = File(result.files.single.path!);
      jsonFilePath = file.path;

      // Load the JSON data
      String jsonString = await file.readAsString();
      originalJsonData = jsonDecode(jsonString); // Store the full original JSON data

      // Parse the transactions
      transactions = originalJsonData.entries
          .map<Transaction>((entry) => Transaction.fromJson(entry.value, entry.key))
          .toList();

      calculateBalances();
      setState(() {});
    }
  }

  void calculateBalances() {
    int previousBalance = 0; // Starting balance
    for (var transaction in transactions) {
      // Determine the expected balance
      if (transaction.outflow > 0) {
        previousBalance -= transaction.outflow; // Outflow decreases balance
      } else {
        previousBalance += transaction.inflow; // Inflow increases balance
      }

      // Check if the calculated balance matches the actual balance
      transaction.color = transaction.balance == previousBalance ? Colors.green : Colors.red;
    }
  }

  // Correct all wrong balances and update the file
  void correctBalances() {
    int previousBalance = 0;
    for (var transaction in transactions) {
      // Correct the balance based on the inflow/outflow
      if (transaction.outflow > 0) {
        previousBalance -= transaction.outflow;
      } else {
        previousBalance += transaction.inflow;
      }
      transaction.balance = previousBalance; // Correct balance

      // Update only the 'number' field in the original JSON data
      originalJsonData[transaction.id]['number'] = transaction.balance;
    }

    // Save the updated data back to the file
    saveUpdatedJsonFile();
  }

  // Function to save the updated JSON file
  Future<void> saveUpdatedJsonFile() async {
    if (jsonFilePath == null) return; // Ensure a file is selected

    // Write the updated JSON data to the file
    File file = File(jsonFilePath!);
    await file.writeAsString(jsonEncode(originalJsonData)); // Save the full updated JSON data

    // Share the file via WhatsApp after saving
    Share.shareFiles([jsonFilePath!], text: 'Updated transactions file');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction List')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickJsonFile,
            child: Text('Pick JSON File'),
          ),
          transactions.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(transaction.description),
                  subtitle: Text('Date: ${transaction.date}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Balance: ${transaction.balance}',
                        style: TextStyle(color: transaction.color),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: correctBalances,
            child: Text('Correct Balances and Save'),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  String id;
  String date;
  String description;
  int balance;
  int inflow;
  int outflow;
  Color? color;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.balance,
    required this.inflow,
    required this.outflow,
  });

  factory Transaction.fromJson(Map<String, dynamic> json, String id) {
    return Transaction(
      id: id,
      date: json['dateAndTime'] ?? 'Unknown Date',
      description: json['description'] ?? 'No Description',
      balance: json['number'] ?? 0,
      inflow: json['status'] == false ? json['totalPrice'] ?? 0 : 0,
      outflow: json['status'] == true ? json['totalPrice'] ?? 0 : 0,
    );
  }
}