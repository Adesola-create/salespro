import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String? scannedData;
  final MobileScannerController _controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance
  List<Map<String, dynamic>> cart = [];
  String scannedItem = '';

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString('cart');
    if (cartData != null) {
      setState(() {
        cart = List<Map<String, dynamic>>.from(jsonDecode(cartData));
      });
    }
  }

// Function to play sound
  Future<void> _playScanSound() async {
    await _audioPlayer.play(AssetSource('sounds/store-scanner-beep.mp3'));
  }

  void addToCartBarcode(String barcode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemDataString = prefs.getString('itemData');
    if (itemDataString == null) return;

    List<Map<String, dynamic>> products =
        List<Map<String, dynamic>>.from(json.decode(itemDataString));

    Map<String, dynamic>? product = products
        .firstWhere((item) => item['barcode'] == barcode, orElse: () => {});

    if (product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      int index = cart.indexWhere((item) => item['id'] == product['id']);
      if (index == -1) {
        cart.add({...product, 'qty': 1, 'amount': product['price']});
      } else {
        cart[index]['qty'] += 1;
        cart[index]['amount'] = cart[index]['price'] * cart[index]['qty'];
      }
      saveCart();

// Play the scan sound
    _playScanSound();

    });
    setState(() {
      scannedItem = product['title'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title']} added to cart!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cart', jsonEncode(cart));
  }

  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  void showQuantityInputDialog(BuildContext context, int index) {
    TextEditingController qtyController =
        TextEditingController(text: cart[index]['qty'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Quantity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5), // Small space between title and subtitle
              Text(
                '${cart[index]['title']}',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 28), // Increased input text size
            decoration: InputDecoration(
              hintText: 'Enter quantity',
              hintStyle: TextStyle(fontSize: 20), // Increased hint size
            ),
            autofocus: true, // Automatically focuses on input field
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                int newQty =
                    int.tryParse(qtyController.text) ?? cart[index]['qty'];
                setState(() {
                  cart[index]['qty'] = newQty;
                  cart[index]['amount'] = cart[index]['price'] * newQty;
                  saveCart();
                });
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double cartTotal = cart.fold(0, (sum, item) => sum + item['amount']);
    // int? editingIndex; // Track which item is being edited
    //TextEditingController qtyController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode/QR Scanner'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Return `true` to indicate refresh
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner takes 50% of the screen
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: MobileScanner(
              controller: _controller,
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null &&
                      barcode.rawValue != scannedData) {
                    addToCartBarcode(barcode.rawValue!);
                    setState(() {
                      scannedData = barcode.rawValue!;
                    });
                    debugPrint('Scanned: ${barcode.rawValue}');
                    break;
                  }
                }
              },
            ),
          ),

          // Cart section
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.white, // Background color
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cart',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: ₦${formatNumber(cartTotal)}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Scrollable item list
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: cart.asMap().entries.map((entry) {
                          int index = entry.key;
                          var item = entry.value;

                          return GestureDetector(
                            onTap: () => showQuantityInputDialog(
                                context, index), // Trigger dialog on tap
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 3.0),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          Text('Qty: ${item['qty']}, '),
                                          Text(
                                              'Price: ₦${formatNumber(item['price'])}, '),
                                          Text(
                                              'Amount: ₦${formatNumber(item['amount'])}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
