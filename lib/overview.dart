import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'constants.dart';
import 'itemhistory.dart';

class OverviewPage extends StatefulWidget {
  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  List<Map<String, dynamic>> transactions = [];
  DateTime selectedDate = DateTime.now(); // Default to Today
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> payments2 = [];
  

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    loadPayment();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd(); // Scroll to the end after the UI builds
    });
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
  Future<void> loadPayment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPayment = prefs.getString('paymentMethod');
    List<Map<String, dynamic>> paymentss = storedPayment != null
        ? List<Map<String, dynamic>>.from(json.decode(storedPayment))
        : [];

    setState(() {
      payments2 = paymentss;
    });
  }

  String? getPaymentTitleById(String paymentId) {
    final payment = payments2.firstWhere(
      (payment) => payment['id'] == paymentId,
      orElse: () => {'title': null}, // Return a default map
    );

    return payment['title']; // Return the title, which can be null if not found
  }

  double calculateSumByPaymentMethod(String selectedPayment) {
    double sum = 0.0;

    for (var transaction in transactions) {
      if (transaction['payMethod'] == selectedPayment &&
          transaction.containsKey('amount')) {
        sum +=
            transaction['amount'] ?? 0.0; // Add amount to the sum if it exists
      }
    }

    return sum;
  }

  Future<void> _generatePaymentMethods(DateTime selectedDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedTransactions = prefs.getStringList('transaction_logs');

    Map<String, double> paymentMethodSums = {};

    if (storedTransactions != null) {
      try {
        // Decode each transaction and filter by date
        for (var transactionJson in storedTransactions) {
          Map<String, dynamic> transaction = json.decode(transactionJson);

          // Check if the transaction matches the selected date
          if (transaction.containsKey('timestamp')) {
            DateTime transactionDate = DateTime.parse(transaction['timestamp']);
            if (transactionDate.year == selectedDate.year &&
                transactionDate.month == selectedDate.month &&
                transactionDate.day == selectedDate.day) {
              // Get the payment method and total
              String paymentMethod = transaction['payMethod'] ?? 'Unknown';
              double transactionTotal = transaction['total'] ?? 0.0;

              // Aggregate totals for each payment method
              if (paymentMethodSums.containsKey(paymentMethod)) {
                paymentMethodSums[paymentMethod] =
                    paymentMethodSums[paymentMethod]! + transactionTotal;
              } else {
                paymentMethodSums[paymentMethod] = transactionTotal;
              }
            }
          }
        }
      } catch (e) {
        print("Error decoding transactions: $e");
      }
    } else {
      print("No transactions found in SharedPreferences.");
    }

    // Update the state with the new payment method sums
    setState(() {
      payments.clear(); // Clear existing payments
      paymentMethodSums.forEach((key, value) {
        payments.add({'id': key, 'totalAmount': value}); // Update payment list
      });
    });
  }

  Future<void> _loadTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedTransactions = prefs.getStringList('transaction_logs');

    _generatePaymentMethods(selectedDate);

    if (storedTransactions != null) {
      try {
        List<Map<String, dynamic>> transactionList = storedTransactions
            .map((item) => json.decode(item) as Map<String, dynamic>)
            .toList();

        // Filter transactions by selected date
        List<Map<String, dynamic>> filteredTransactions =
            _filterTransactionsByDate(transactionList, selectedDate);

        // Debug: Check if filtering is working
        //  print("Filtered Transactions: $filteredTransactions");

        // Map to store aggregated items
        Map<String, Map<String, dynamic>> uniqueItems = {};

        for (var transaction in filteredTransactions) {
          if (transaction.containsKey('cart') && transaction['cart'] is List) {
            for (var item in transaction['cart']) {
              String title = item['title'] ?? "Unknown Item";
              int qty = (item['qty'] ?? 0);
              double price = (item['price'] ?? 0).toDouble();
              double amount = qty * price;
              String imagePath =
                  item['localImagePath'] ?? ""; // Image path (optional)

              if (uniqueItems.containsKey(title)) {
                uniqueItems[title]!['qty'] += qty;
                uniqueItems[title]!['amount'] += amount;
              } else {
                uniqueItems[title] = {
                  'title': title,
                  'qty': qty,
                  'amount': amount,
                  'price': price, // Keeping the reference price
                  'imagePath': imagePath, // Adding image path
                };
              }
            }
          }
        }

        List<Map<String, dynamic>> sortedTransactions = uniqueItems.values
            .toList()
          ..sort((a, b) => a['title'].compareTo(b['title']));

        setState(() {
          transactions = sortedTransactions;
        });
      } catch (e) {
        print("Error decoding transactions: $e");
      }
    } else {
      print("No transactions found in SharedPreferences.");
    }
  }

  /// **Format Number Function**
  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  /// **Filter transactions based on the selected date**
  List<Map<String, dynamic>> _filterTransactionsByDate(
      List<Map<String, dynamic>> allTransactions, DateTime date) {
    String selectedDateString = DateFormat('yyyy-MM-dd').format(date);

    return allTransactions.where((transaction) {
      if (!transaction.containsKey('timestamp') ||
          transaction['timestamp'] == null) {
        print("Skipping transaction with missing timestamp: $transaction");
        return false;
      }

      try {
        DateTime transactionDate = DateTime.parse(transaction['timestamp']);
        String formattedDate = DateFormat('yyyy-MM-dd').format(transactionDate);
        return formattedDate == selectedDateString;
      } catch (e) {
        print("Error parsing timestamp: ${transaction['timestamp']} - $e");
        return false;
      }
    }).toList();
  }

  /// **Change filter date**
  void _changeDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      _loadTransactions();
      // _generatePaymentMethods(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate Filter Dates
    DateTime today = DateTime.now();
    List<Widget> dateButtons = [];

    for (int i = -10; i < 1; i++) {
      DateTime date = today.add(Duration(days: i));
      String dateString = DateFormat('MMM dd').format(date);
      dateButtons.add(_buildFilterButton("📅 $dateString", date));
    }

    // Calculate Grand Total
    double grandTotal = transactions.fold(0.0, (sum, transaction) {
      double amount = transaction['amount'] ?? 0.0;
      return sum + amount;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Filter Buttons
               Container(
      height: 70, // Set a fixed height for the container
      child: SingleChildScrollView(
            controller: _scrollController, 
            scrollDirection: Axis.horizontal,
        child: Row(
          children: dateButtons,
        ),
      ),
    ),

              SizedBox(height: 10),

              // Grand Total Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: primaryColor, // Highlight color
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grand Total",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "₦${formatNumber(grandTotal)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    vertical: 8.0), // Add margin to the title
                child: Text(
                  'Payment Methods',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              Container(
                height: 100, // Set a fixed height for the scrollable area
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return GestureDetector(
                      child: Card(
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(horizontal: 8.0),
                        elevation: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getPaymentTitleById(payment['id']) ??
                                    payment['id'],
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₦${formatNumber(payment['totalAmount'])}',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // Transactions List
              Text(
                'Items Sold: ${DateFormat('MMMM dd, yyyy').format(selectedDate)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  /// **Build Filter Button**
 Widget _buildFilterButton(String label, DateTime filterDate) {
  String a = selectedDate.toString().substring(0, 10);
  String b = filterDate.toString().substring(0, 10);

  bool isSelected = a == b; // Check if selected

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0), // Optional padding
    child: GestureDetector(
      onTap: () => _changeDate(filterDate), // Change date on tap
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12), // Add padding
        margin: EdgeInsets.all(4), // Margin for buttons
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}

  /// **Build Transaction List**
  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No transactions found for this date.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        var item =
            transactions[index]; // Now transactions is a list of unique items

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            // Wrap with Padding to remove internal padding
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2), // Removes default ListTile padding
              dense: true, // Reduces tile height
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['imagePath'] != null &&
                        File(item['imagePath']).existsSync()
                    ? Image.file(
                        File(item['imagePath']),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.image_not_supported,
                        size: 60, color: Colors.grey),
              ),
              title: Text(
                item['title'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text("Total Sold: ${item['qty']} units",
                  style: TextStyle(fontSize: 14)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "₦${formatNumber(item['amount'])}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemHistoryPage(
                        itemName: item['title'], salesDate: selectedDate),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
