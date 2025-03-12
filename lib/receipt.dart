// import 'dart:convert';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

class ReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> salesLog;

  ReceiptScreen({required this.salesLog});

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  List<Map<String, dynamic>> get cart =>
      List<Map<String, dynamic>>.from(widget.salesLog['cart'] ?? []);
  String business = '';
  String services = '';
  String address = '';
  List<Map<String, dynamic>> payments = [];


  @override
  void initState() {
    super.initState();
    loadLocalData();
    loadPayment();
    sendPendingTransactions();
  }

  Future<void> loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      business = prefs.getString('business') ?? '';
      services = prefs.getString('services') ?? '';
      address = prefs.getString('address') ?? '';
    });
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

  Future<void> loadPayment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPayment = prefs.getString('paymentMethod');
    print('printing...... $storedPayment');
    List<Map<String, dynamic>> paymentss = storedPayment != null
        ? List<Map<String, dynamic>>.from(json.decode(storedPayment))
        : [];

    setState(() {
      payments = paymentss;
    });
  }

  String? getPaymentTitleById(String paymentId) {
    final payment = payments.firstWhere(
      (payment) => payment['id'] == paymentId,
      orElse: () => {'title': null}, // Return a default map
    );

    return payment['title']; // Return the title, which can be null if not found
  }

  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    double total = cart.fold(0, (sum, item) => sum + (item['amount'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Receipt'),
        actions: [
          ElevatedButton(
            onPressed: () {
              printReceipt();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300], // Grey background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey), // Grey border
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, color: Colors.black), // Print Icon
                SizedBox(width: 5),
                Text('Print', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(business,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 4),
            Center(
              child: Text('($services)', style: TextStyle(fontSize: 16)),
            ),
            Center(
              child: Text(address, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            Text('Customer: ${widget.salesLog['name']}',
                style: TextStyle(fontSize: 16)),
            Text(
              'Date: ${DateTime.parse(widget.salesLog['timestamp']).toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 16),
            ),
            Text('salesID: ${widget.salesLog['salesID']}',
                style: TextStyle(fontSize: 16)),
            Text(
                'Payment Method: ${getPaymentTitleById(widget.salesLog['payMethod'])}',
                style: TextStyle(fontSize: 16)),
            Text('Served by: ${widget.salesLog['servedBy']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero, // Remove padding
                  dense: true, // Reduce tile height
                  leading: Text(
                    'Qty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  title: Text(
                    'Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Eliminate extra spacing
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                          width: 5), // Minimal space between price and amount
                      Text(
                        'Amount',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 1, height: 0), // No extra space between rows
                ListView.separated(
                  itemCount: cart.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => Divider(
                      thickness: 1, height: 0), // No space between items
                  itemBuilder: (context, index) {
                    var item = cart[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero, // Remove padding
                      dense: true, // Reduce height
                      leading: Text('${item['qty']}',
                          style: TextStyle(fontSize: 16)),
                      title:
                          Text(item['title'], style: TextStyle(fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // No extra spacing
                        children: [
                          Text('₦${formatNumber(item['price'])}',
                              style: TextStyle(fontSize: 16)),
                          SizedBox(width: 16),
                          Text('₦${formatNumber(item['amount'])}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, height: 0), // No extra space
                Padding(
                  padding: EdgeInsets.zero, // Remove padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₦${formatNumber(total)}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Center(
              child: Text('Thank you for your patronage!',
                  style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  //import 'package:pdf/pdf.dart'; // Ensure this is imported

  void printReceipt() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Optimized for receipt printers
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Business Information
            pw.Center(
              child: pw.Text(business,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text('($services)', style: pw.TextStyle(fontSize: 12)),
            ),
            pw.Center(
              child: pw.Text(address, style: pw.TextStyle(fontSize: 12)),
            ),
            pw.SizedBox(height: 10),

            // Customer Info
            pw.Text('Customer: ${widget.salesLog['name']}',
                style: pw.TextStyle(fontSize: 12)),
            pw.Text(
              'Date: ${DateTime.parse(widget.salesLog['timestamp']).toLocal().toString().substring(0, 16)}',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Text('Sales ID: ${widget.salesLog['salesID']}',
                style: pw.TextStyle(fontSize: 12)),
            pw.Text('Served by: ${widget.salesLog['servedBy']}',
                style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),

            // Table Header
            pw.Container(
              padding: pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Qty ',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(
                    child: pw.Text('Item',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Text('Price  ',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Amount',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),

            // Table Rows for Items
            ...cart.map((item) => pw.Container(
                  padding: pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item['qty']}  ',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Expanded(
                        child: pw.Text(item['title'],
                            style: pw.TextStyle(fontSize: 12)),
                      ),
                      pw.Text('N${formatNumber(item['price'])} ',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text(' N${formatNumber(item['amount'])}',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                )),

            // Grand Total
            pw.SizedBox(height: 8),
            pw.Container(
              padding: pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                    top: pw.BorderSide(width: 1),
                    bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Grand Total:',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'N${formatNumber(cart.fold(0, (sum, item) => sum + (item['amount'] ?? 0)))}',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),

            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('Thank you for your patronage!',
                  style: pw.TextStyle(fontSize: 14)),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text('Powered By: www.livepetal.com',
                  style: pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
