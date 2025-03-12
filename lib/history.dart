import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'receipt.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _transactionLogs = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now(); // Default to today

  @override
  void initState() {
    super.initState();
    _loadTransactionLogs();
    sendPendingTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd(); // Scroll to the end after the UI builds
    });
  }

  Future<void> _loadTransactionLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('transaction_logs') ?? [];

    List<Map<String, dynamic>> loadedLogs = logs.map((log) {
      return Map<String, dynamic>.from(jsonDecode(log));
    }).toList();
    //print("this is my ${loadedLogs.length}");

    loadedLogs.sort((a, b) {
      DateTime dateA = DateTime.parse(a['timestamp']);
      DateTime dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _transactionLogs = loadedLogs; // Store all transactions
      _transactionLogs =
          _filterTransactionsByDate(_transactionLogs, selectedDate);
      _isLoading = false;
    });
  }

  // void _changeDate(DateTime newDate) {
  //   setState(() {
  //     selectedDate = newDate;
  //     _loadTransactionLogs();
  //   });
  // }

  void _changeDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      _isLoading = true;
      _loadTransactionLogs();
    });

    // Instead of reloading from storage, filter from memory
//  Future.delayed(Duration(milliseconds: 300), () {

    // });
  }

  List<Map<String, dynamic>> _filterTransactionsByDate(
      List<Map<String, dynamic>> allTransactions, DateTime date) {
    String selectedDateString = DateFormat('yyyy-MM-dd').format(date);
    return allTransactions.where((transaction) {
      DateTime transactionDate = DateTime.parse(transaction['timestamp']);
      bool isSameDate = DateFormat('yyyy-MM-dd').format(transactionDate) ==
          selectedDateString;
      return isSameDate;
    }).toList();
  }

  Widget _buildFilterButton(DateTime filterDate) {
    String a = selectedDate.toString().substring(0, 10);
    String b = filterDate.toString().substring(0, 10);

    bool isSelected = a == b ? true : false; // Check if selected
    String label = DateFormat('dd').format(filterDate);
    String label2 = DateFormat('E').format(filterDate);

    return GestureDetector(
      onTap: () => _changeDate(filterDate),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          // Use Column to stack the texts vertically
          mainAxisSize: MainAxisSize.min, // Keep the column size compact
          children: [
            Text(
              label, // First label
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24),
            ),
            //SizedBox(height: 4), // Space between the two labels
            Text(
              label2, // Second label below
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 14, // Slightly smaller font size for distinction
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ScrollController _scrollController =
      ScrollController(); // Add Scroll Controller

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Date Filter Buttons
          SingleChildScrollView(
            controller: _scrollController, // Attach the controller
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(10),
            child: Row(
              children: List.generate(10, (index) {
                DateTime date = DateTime.now()
                    .subtract(Duration(days: 9 - index)); // Ascending order
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _buildFilterButton(date),
                );
              }),
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _transactionLogs.isEmpty
                    ? Center(child: Text('No transaction history available'))
                    : ListView.builder(
                        itemCount: _transactionLogs.length,
                        itemBuilder: (context, index) {
                          final log = _transactionLogs[index];
                          final total = log['total'];
                          final name = log['name'];
                          // final salesID = log['salesID'];
                          final timestamp = log['timestamp'];

                          return Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: ListTile(
                              title: Text(
                                '$name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    DateTime.parse(timestamp)
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16),
                                  ),
                                  SizedBox(width: 8),

                                  Icon(
                                    log['sent'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: log['sent'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize:
                                    MainAxisSize.min, // Minimize the row size
                                crossAxisAlignment: CrossAxisAlignment
                                    .center, // Center align vertically
                                children: [
                                  // Add space between icon and amount
                                  Column(
                                    mainAxisSize: MainAxisSize
                                        .min, // Minimize the column size
                                    crossAxisAlignment: CrossAxisAlignment
                                        .end, // Align text to the end
                                    children: [
                                      Text(
                                        '₦${formatNumber(total)}', // Amount
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                          '${log['cart'].length} Items', // Items count
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons
                                        .arrow_forward_ios, // Forward arrow icon
                                    size: 18,
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReceiptScreen(salesLog: log),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void sendPendingTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('transaction_logs') ?? [];

    List<Map<String, dynamic>> allLogs =
        logs.map((log) => jsonDecode(log) as Map<String, dynamic>).toList();
    for (var transaction in allLogs) {
      if (transaction['sent'] == false) {
        try {
          const String url = 'https://salespro.livepetal.com/v1/addhistory';
          String token = prefs.getString('apiKey') ?? '';

          Map<String, String> headers = {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          };

          final response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(transaction),
          );

          if (response.statusCode == 200) {
            transaction['sent'] = true;
            // Save entire logs
            prefs.setStringList('transaction_logs',
                allLogs.map((log) => jsonEncode(log)).toList());
          }
        } catch (e) {
          print('Error sending transaction: $e');
        }
      }
    }
  }

  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}
