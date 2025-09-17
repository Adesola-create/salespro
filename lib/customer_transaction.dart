import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
//import 'constants.dart';
import 'receipt.dart';
import 'package:http/http.dart' as http;

class CustomerHistoryPage extends StatefulWidget {
  final String customerName;
  final String customerPhone;

  const CustomerHistoryPage({
    super.key,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  _CustomerHistoryPageState createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
  List<Map<String, dynamic>> _transactionLogs = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now();
  Set<String> transactionDates = {};
  final ScrollController _scrollController = ScrollController();

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

    // Filter transactions based on the selected customer
    loadedLogs = loadedLogs.where((log) {
      return log['name'] == widget.customerName || log['phone'] == widget.customerPhone;
    }).toList();

    // Sort transactions by timestamp
    loadedLogs.sort((a, b) {
      DateTime dateA = DateTime.parse(a['timestamp']);
      DateTime dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA);
    });

    transactionDates.clear();
    for (var log in loadedLogs) {
      DateTime transactionDate = DateTime.parse(log['timestamp']);
      String formattedDate = DateFormat('yyyy-MM-dd').format(transactionDate);
      transactionDates.add(formattedDate);
    }

    setState(() {
      _transactionLogs = loadedLogs;
      _isLoading = false;
    });
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendPendingTransactions() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customerName}\'s Transactions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Date Filter Buttons (unchanged)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactionLogs.isEmpty
                    ? const Center(child: Text('No transaction history available'))
                    : ListView.builder(
                        controller: _scrollController, // Attach the controller
                        itemCount: _transactionLogs.length,
                        itemBuilder: (context, index) {
                          final log = _transactionLogs[index];
                          final total = log['total'];
                          final name = log['name'];
                          final timestamp = log['timestamp'];

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
                                '$name',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    DateTime.parse(timestamp)
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16),
                                  ),
                                  const SizedBox(width: 8),
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
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₦${formatNumber(total)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                          '${log['cart'].length} Items',
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
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

  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}