import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'receipt.dart';
import 'package:http/http.dart' as http;

class AdminHistory extends StatefulWidget {
  const AdminHistory({super.key});

  @override
  _AdminHistoryState createState() => _AdminHistoryState();
}

class _AdminHistoryState extends State<AdminHistory> {
  List<Map<String, dynamic>> _transactionLogs = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now(); // Default to today
  DateTime endDate = DateTime.now(); // Default to today
  Set<String> transactionDates = {}; // Set to track transaction dates
  bool isFetching = false;
  int historyLength = 10;

  @override
  void initState() {
    super.initState();
    _loadTransactionLogs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd(); // Scroll to the end after the UI builds
    });
  }

  int computeDaysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

//DateTime convertedDate = DateTime.parse('2025-06-25');
  Future<void> _loadTransactionLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('admintransaction_logs') ?? [];

    List<Map<String, dynamic>> loadedLogs = logs.map((log) {
      return Map<String, dynamic>.from(jsonDecode(log));
    }).toList();
    //print("this is my ${loadedLogs.length}");

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

  Future<void> fetchHistory(DateTime startDate, DateTime endDates) async {
    setState(() {
      isFetching = true;
    });
    print('$startDate $endDates');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    const String url = 'https://salespro.livepetal.com/v1/getadminhistory';
    String? token = prefs.getString('apiKey');

    try {
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'start': '$startDate', 'end': '$endDates'}),
      );

      if (response.statusCode == 200) {
        print('Response status: ${response.statusCode}');
        print('Response body..................: ${response.body}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> fetchedData = responseData['data'] ?? [];
        //prefs.setStringList('admintransaction_logs', jsonEncode(fetchedData).toList());
        prefs.setStringList('admintransaction_logs',
            fetchedData.map((log) => jsonEncode(log)).toList());

//convertedDate = DateTime.parse('2025-06-25');
        setState(() {
          endDate = endDates;
          historyLength = computeDaysBetween(startDate, endDates) + 1;
          isFetching = false;
        });
        _loadTransactionLogs();
        //_filterItems();
      } else {
        debugPrint('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

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

    bool isSelected = a == b; // Check if selected
    String label = DateFormat('dd').format(filterDate);
    String label2 = DateFormat('E').format(filterDate);

    bool hasTransactions =
        transactionDates.contains(DateFormat('yyyy-MM-dd').format(filterDate));

    return GestureDetector(
      onTap: () => _changeDate(filterDate),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep the column size compact
          children: [
            if (hasTransactions) // Display indicator if there are transactions for this date
              Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.red, // Color for the indicator
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label, // First label
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            // SizedBox(height: 4), // Space between the two labels
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Agents History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        // automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: () {
              // fetchHistory();
              showDateRangeBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter Buttons
          SingleChildScrollView(
            controller: _scrollController, // Attach the controller
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: List.generate(historyLength, (index) {
                DateTime date = endDate.subtract(Duration(
                    days: historyLength - 1 - index)); // Ascending order
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildFilterButton(date),
                );
              }),
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactionLogs.isEmpty
                    ? const Center(child: Text('No transaction history available'))
                    : ListView.builder(
                        itemCount: _transactionLogs.length,
                        itemBuilder: (context, index) {
                          final log = _transactionLogs[index];
                          final total = log['total'];
                          final name = log['name'];
                          // final salesID = log['salesID'];
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
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
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
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                          '${log['cart'] == null ? 0 : log['cart'].length} Items', // Items count
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons
                                        .arrow_forward_ios, // Forward arrow icon
                                    size: 18,
                                  ),
                                ],
                              ),
                              onTap: () {
                                final cart = log['cart'] ?? [];

                                if (cart.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No items in the cart to view receipt')),
                                  );
                                  return;
                                }

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

  void showDateRangeBottomSheet() {
    DateTime? startDate;
    DateTime? endDate;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Start Date Field
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          hintText: 'Choose a start date',
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        controller: TextEditingController(
                          text: startDate != null
                              ? startDate!.toLocal().toString().substring(0, 10)
                              : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // End Date Field
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime
                            .now(), // This disables selection of future dates,
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          hintText: 'Choose an end date',
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        controller: TextEditingController(
                          text: endDate != null
                              ? endDate!.toLocal().toString().substring(0, 10)
                              : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (startDate != null && endDate != null) {
                          if (startDate!.isAfter(endDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Start date cannot be after end date')),
                            );
                            return;
                          }

                          Navigator.pop(context); // Close modal
                          fetchHistory(
                              startDate!, endDate!); // Proceed with valid range
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please select both start and end dates')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
