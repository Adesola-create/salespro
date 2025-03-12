import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'receipt.dart';

class ItemHistoryPage extends StatefulWidget {
  final String itemName;
  final DateTime salesDate;

  ItemHistoryPage({required this.itemName, required this.salesDate});

  @override
  _ItemHistoryPageState createState() => _ItemHistoryPageState();
}

class _ItemHistoryPageState extends State<ItemHistoryPage> {
  List<Map<String, dynamic>> _transactionLogs = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

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

    setState(() {
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
    String selectedDateString = DateFormat('yyyy-MM-dd').format(date);
    return allTransactions.where((transaction) {
      DateTime transactionDate = DateTime.parse(transaction['timestamp']);
      bool isSameDate = DateFormat('yyyy-MM-dd').format(transactionDate) ==
          selectedDateString;
      bool containsItem =
          transaction['cart'].any((item) => item['title'] == widget.itemName);
      return isSameDate && containsItem;
    }).toList();
  }

  Widget _buildFilterButton(DateTime filterDate) {
    bool isSelected = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(filterDate);
    String label = DateFormat('MMM d').format(filterDate);

    return GestureDetector(
      onTap: () => _changeDate(filterDate),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Date Filter Buttons
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(10),
            child: Row(
              children: List.generate(10, (index) {
                DateTime date =
                    DateTime.now().subtract(Duration(days: 9 - index));
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
                    ? Center(
                        child: Text(
                            'No transactions found for ${widget.itemName}'))
                    : ListView.builder(
                        itemCount: _transactionLogs.length,
                        itemBuilder: (context, index) {
                          final log = _transactionLogs[index];
                          final total = log['total'];
                          final name = log['name'];
                          // final salesID = log['salesID'];
                          //  final timestamp = log['timestamp'];

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
                                '$name: ₦${NumberFormat('#,###').format(total)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                                            style: TextStyle(
                                                color: Colors.black87),
                                          ))
                                      .toList(),
                                ],
                              ),
                              trailing: Icon(Icons.chevron_right),
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
