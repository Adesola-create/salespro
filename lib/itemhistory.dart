import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'receipt.dart';

class ItemHistoryPage extends StatefulWidget {
  final String itemName;
  final DateTime salesDate;

  const ItemHistoryPage({super.key, required this.itemName, required this.salesDate});

  @override
  _ItemHistoryPageState createState() => _ItemHistoryPageState();
}

class _ItemHistoryPageState extends State<ItemHistoryPage> {
  List<Map<String, dynamic>> _transactionLogs = [];
  List<Map<String, dynamic>> _transactionLogsAll = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  //Set<String> transactionDates = {}; // Set to track transaction dates
  Set<String> transactionItems = {}; // Set to track transaction dates

  @override
  void initState() {
    super.initState();
    _loadTransactionLogs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    selectedDate = widget.salesDate;
  }

  Future<void> _loadTransactionLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('transaction_logs') ?? [];

    List<Map<String, dynamic>> loadedLogs = logs.map((log) {
      return Map<String, dynamic>.from(jsonDecode(log));
    }).toList();

    loadedLogs.sort((a, b) {
      DateTime dateA = DateTime.parse(a['timestamp']);
      DateTime dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA);
    });

    // transactionDates.clear();
    // for (var log in loadedLogs) {
    //   DateTime transactionDate = DateTime.parse(log['timestamp']);
    //   String formattedDate = DateFormat('yyyy-MM-dd').format(transactionDate);
    //   transactionDates.add(formattedDate);
    // }

    setState(() {
      _transactionLogsAll = loadedLogs;
      _transactionLogs =
          _filterTransactionsByItemAndDate(loadedLogs, selectedDate);
      _isLoading = false;
    });
  }

  void _changeDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      _loadTransactionLogs();
    });
  }

  List<Map<String, dynamic>> _filterTransactionsByItemAndDate(
      List<Map<String, dynamic>> allTransactions, DateTime date) {
    return allTransactions.where((transaction) {
      DateTime transactionDate = DateTime.parse(transaction['timestamp']);
      bool isSameDate = DateFormat('yyyy-MM-dd').format(transactionDate) ==
          DateFormat('yyyy-MM-dd').format(date);
      bool containsItem =
          transaction['cart'].any((item) => item['title'] == widget.itemName);
      // Check if the date is "All" (i.e., when selectedDate is null)
      return (selectedDate == DateTime(0, 0, 0) || isSameDate) &&
          containsItem; // If selectedDate is set to a specific date, filter by that; otherwise, return all transactions.
    }).toList();
  }

  Widget _buildFilterButton(DateTime filterDate, {bool isAll = false}) {
    bool isSelected = isAll
        ? selectedDate == DateTime(0, 0, 0) // Check if "All" is selected
        : DateFormat('yyyy-MM-dd').format(selectedDate) ==
            DateFormat('yyyy-MM-dd').format(filterDate);
    String label = isAll ? "All" : DateFormat('MMM d').format(filterDate);
    //bool hasTransactions = transactionDates.contains(DateFormat('yyyy-MM-dd').format(filterDate));
    bool hasTransactions = _transactionLogsAll.any((log) {
      DateTime transactionDate = DateTime.parse(log['timestamp']);
      return DateFormat('yyyy-MM-dd').format(transactionDate) ==
              DateFormat('yyyy-MM-dd').format(filterDate) &&
          log['cart'].any((item) => item['title'] == widget.itemName);
    });

    return GestureDetector(
      onTap: () {
        if (isAll) {
          setState(() {
            selectedDate = DateTime(0, 0, 0); // Represents "All"
            _loadTransactionLogs();
          });
        } else {
          _changeDate(filterDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row( // Changed Stack to Row for horizontal arrangement
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTransactions) // Display indicator if there are transactions for this date
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.red, // Color for the indicator
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8), // Add space between the indicator and the label
          Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item History: ${widget.itemName}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Date Filter Buttons
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Add the "All" button at the start
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildFilterButton(DateTime.now(),
                      isAll: true), // "All" button
                ),
                // Generate the last 10 days of buttons
                ...List.generate(10, (index) {
                  DateTime date =
                      DateTime.now().subtract(Duration(days: 9 - index));
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildFilterButton(date),
                  );
                }),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactionLogs.isEmpty
                    ? Center(
                        child: Text(
                            'No transactions found for ${widget.itemName}'))
                    : ListView.builder(
                        itemCount: _transactionLogs.length,
                        itemBuilder: (context, index) {
                          final log = _transactionLogs[index];
                          final total = log['total'];
                          final name = log['name'];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: ListTile(
                              title: Text(
                                '$name: ₦${NumberFormat('#,###').format(total)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...log['cart']
                                      .where((item) =>
                                          item['title'] ==
                                          widget
                                              .itemName) // Filter items by name
                                      .map<Widget>((item) => Text(
                                            'Qty: ${item['qty']}, Price: ₦${NumberFormat('#,###').format(item['price'])}, Amount: ₦${NumberFormat('#,###').format(item['amount'])}',
                                            style: const TextStyle(
                                                color: Colors.black87),
                                          ))
                                      .toList(),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
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
}
