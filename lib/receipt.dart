// import 'dart:convert';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:printing/printing.dart';
//import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
//import 'package:esc_pos_utils/esc_pos_utils.dart';

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

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    loadLocalData();
    loadPayment();
    sendPendingTransactions();
    _getBluetoothDevices();
    
  }

  void _getBluetoothDevices() async {
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
      });

      // Try to auto-connect to the saved printer
      _autoConnect();
    } catch (e) {
      print("Error getting Bluetooth devices: $e");
    }
  }

  /// Auto-connect to the last selected printer
  void _autoConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('printer_address');

    if (savedAddress != null) {
      BluetoothDevice? savedDevice =
          _devices.firstWhere((d) => d.address == savedAddress);

      setState(() {
        _selectedDevice = savedDevice;
      });
      _disconnect();
    }
  }

  /// Connect to selected Bluetooth printer
  void _connect({bool auto = false}) async {
    if (_selectedDevice == null) return;
    try {
      bool? isConnected = await bluetooth.connect(_selectedDevice!);
      if (isConnected == true) {
        setState(() {
          _connected = true;
        });

        // Save the selected printer address
        if (!auto) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('printer_address', _selectedDevice!.address ?? '');
        }
      }
    } catch (e) {
      print("Connection error: $e");
    }
  }

  /// Disconnect Bluetooth printer
  void _disconnect() async {
    await bluetooth.disconnect();
    setState(() {
      _connected = false;
    });
    _connect(auto: true);
  }

  /// Print sample text
  // void _print() {
  //   if (!_connected) return;
  //   bluetooth.printNewLine();
  //   bluetooth.printCustom(
  //     "Hello from BraveIQ! Make sure to download BraveIQ app from Play Store",
  //     2,
  //     1,
  //   );
  //   bluetooth.printNewLine();
  //   bluetooth.printQRcode("https://livepetal.com", 200, 200, 1);
  //   bluetooth.printNewLine();
  //   bluetooth.printNewLine();
  // }

  Future<void> loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      business = prefs.getString('business') ?? '';
      services = prefs.getString('services') ?? '';
      address = prefs.getString('address') ?? '';
    });
    //printReceipt();
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
        title: Text('Receipt'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _isVisible = false; // Toggle visibility
              });
            },
          ),
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
            Visibility(
              visible: _isVisible ||
                  !_connected, // Show if _isVisible or _connected is false
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceEvenly, // Ensures equal spacing between the children
                children: [
                  // Icon and Connection Status
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.wifi, // Network icon
                          color: _connected
                              ? Colors.green
                              : Colors
                                  .red, // Green if connected, red if disconnected
                          size: 30, // Adjust size if needed
                        ),
                        onPressed: _connect,
                      ),
                      Text(
                        _connected ? "Connected" : "Disconnected", // Label text
                        style: TextStyle(
                          color: _connected
                              ? Colors.green
                              : Colors.red, // Same color as icon
                          fontSize: 8, // Adjust font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Dropdown with border
                  Container(
                    // Removed the border property
                    child: DropdownButton<BluetoothDevice>(
                      hint: Text("Select Printer"),
                      value: _selectedDevice,
                      onChanged: (device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                      items: _devices.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 16.0,
                                top: 4.0,
                                bottom: 4.0), // Reduced vertical padding
                            child: Text(device.name ?? "Unknown"),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Connect / Disconnect button
                  ElevatedButton(
                    onPressed: _connected ? _disconnect : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Remove background color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                        side: BorderSide(
                            color: _connected
                                ? Colors.red
                                : Colors
                                    .green), // Border color based on connection status
                      ),
                    ),
                    child: Text(
                      _connected ? "Disconnect" : "Connect",
                      style: TextStyle(
                        color: _connected
                            ? Colors.red
                            : Colors.green, // Text color matching border
                      ),
                    ),
                  )
                ],
              ),
            ),
            // ElevatedButton(
            //       onPressed: _print,
            //       child: Text("Print Sample"),
            //     ),
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
                style: TextStyle(fontSize: 14)),
            Text(
              'Date: ${DateTime.parse(widget.salesLog['timestamp']).toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 14),
            ),
            Text('salesID: ${widget.salesLog['salesID']}',
                style: TextStyle(fontSize: 14)),
            Text(
                'Payment Method: ${getPaymentTitleById(widget.salesLog['payMethod'])}',
                style: TextStyle(fontSize: 14)),
            Text('Served by: ${widget.salesLog['servedBy']}',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 20),
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero, // Remove padding
                  dense: true, // Reduce tile height
                  leading: Text(
                    'Qty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  title: Text(
                    'Item',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Eliminate extra spacing
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                          width: 5), // Minimal space between price and amount
                      Text(
                        'Amount',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                          style: TextStyle(fontSize: 14)),
                      title:
                          Text(item['title'], style: TextStyle(fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // No extra spacing
                        children: [
                          Text('₦${formatNumber(item['price'])}',
                              style: TextStyle(fontSize: 14)),
                          SizedBox(width: 16),
                          Text('₦${formatNumber(item['amount'])}',
                              style: TextStyle(fontSize: 14)),
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
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₦${formatNumber(total)}',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
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

  void printReceipt() async {
    // List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    // if (devices.isEmpty) {
    //   print("No paired Bluetooth devices found.");
    //   return;
    // }

    // Select the first available Bluetooth printer
    // BluetoothDevice device = devices.first;
    // await bluetooth.connect(device);

    bluetooth.printCustom(business, 1, 1); // Business name, bold size
    //bluetooth.printCustom('($services)', 0, 1);
    bluetooth.printCustom(address, 0, 1);
    bluetooth.printNewLine();

    // Customer Info
    bluetooth.printCustom("Customer: ${widget.salesLog['name']}", 0, 0);
    bluetooth.printCustom(
        'Date: ${DateTime.parse(widget.salesLog['timestamp']).toLocal().toString().substring(0, 16)}',
        0,
        0);
    bluetooth.printCustom("Sales ID: ${widget.salesLog['salesID']}", 0, 0);
    bluetooth.printCustom("Served by:  ${widget.salesLog['servedBy']}", 0, 0);

    bluetooth.printCustom("--------------------------------", 0, 1);

    // Table Header
    bluetooth.printCustom("Qty Item           Price Amount", 0, 1);
    bluetooth.printCustom("--------------------------------", 0, 1);

    // Items
    for (var item in cart) {
      String qty = '${item['qty']}';
      String title = item['title'].length > 12
          ? item['title'].substring(0, 12)
          : item['title'];
      String price = '${formatNumber(item['price'])}';
      String amount = '${formatNumber(item['amount'])}';

      bluetooth.printLeftRight("$qty  $title", "$price  $amount", 0);
    }
    bluetooth.printCustom("--------------------------------", 0, 1);

    // Grand Total

    bluetooth.printLeftRight(
        "Grand Total:",
        'N${formatNumber(cart.fold(0, (sum, item) => sum + (item['amount'] ?? 0)))}',
        1);

    bluetooth.printCustom("--------------------------------", 0, 1);

    // Footer
    bluetooth.printCustom("Thank you for your patronage!", 0, 1);
    bluetooth.printCustom("Powered by www.livepetal.com", 0, 1);

    // Cut paper
    bluetooth.paperCut();
  }
}
