import 'package:flutter/material.dart';
import 'package:salespro/constants.dart';
import 'calculator.dart';
import 'transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';
import 'receipt.dart';
import 'package:http/http.dart' as http;
import 'scanner.dart';

class POSHomePage extends StatefulWidget {
  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cart = [];
  List<Map<String, String>> customers = [];
  FocusNode searchFocusNode = FocusNode();
  int salesId = 0;
  String name = '';
  String phone = '';
  String Bid = '';
  String servedBy = '';
  List<Map<String, dynamic>> payments = [];
  int? selectedIndex;
  int editPrice = 0;

  // String searchQuery = ''; // Declare as a state variable
  List<Map<String, String>> filteredCustomers =
      []; // Declare as a state variable

  final random = Random();

  // Generate a 12-digit number

  @override
  void initState() {
    super.initState();
    loadLocalData();
    loadCart();
    _loadCustomers();
    _sendUnsentCustomers();

    loadPayment();
  }

  void _navigateToScanner() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerPage()),
    );

    if (result == true) {
      setState(() {
        loadCart(); // Refresh the cart or any needed data
      });
    }
  }

  // Future<void> _loadCustomers() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? customersString = prefs.getString('myCustomers');

  //   if (customersString != null) {
  //     setState(() {
  //       customers = List<Map<String, String>>.from(json
  //           .decode(customersString)
  //           .map((e) => Map<String, String>.from(e)));
  //     });
  //   }
  // }
  Future<void> _loadCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customersString = prefs.getString('myCustomers');

    if (customersString != null) {
      setState(() {
        customers = List<Map<String, String>>.from(json
            .decode(customersString)
            .map((e) => Map<String, String>.from(e)));
        //filteredCustomers = List.from(customers); // Initialize filteredCustomers
      });
    }
  }

  Future<void> _addCustomer(String name, String phone) async {
    if (name.isEmpty) {
      return;
    }
    setState(() {
      customers.add({'name': name, 'phone': phone, 'sent': 'false'});
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('myCustomers', json.encode(customers));
  }

  Future<void> _sendUnsentCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCustomers = prefs.getString('myCustomers');
    List<Map<String, dynamic>> customers = storedCustomers != null
        ? List<Map<String, dynamic>>.from(json.decode(storedCustomers))
        : [];

    for (var customer in customers) {
      if (customer['sent'] == 'false') {
        bool success = await _sendToServer(customer);
        if (success) {
          customer['sent'] = 'true';
        }
      }
    }

    await prefs.setString('myCustomers', json.encode(customers));
  }

  Future<void> _fetchCustomer() async {
    print('fetching new customers.');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCustomers = prefs.getString('myCustomers');
    List<Map<String, dynamic>> customers = storedCustomers != null
        ? List<Map<String, dynamic>>.from(json.decode(storedCustomers))
        : [];

    // Ensure no contact has 'sent' status of false
    if (customers.any((customer) => customer['sent'] == 'false')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not Synchronized'),
          duration: Duration(seconds: 2),
        ),
      );
      _sendUnsentCustomers();
      return;
    }

    String? token = prefs.getString('apiKey');
    final url = Uri.parse('https://salespro.livepetal.com/v1/getcontact');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> fetchedCustomers =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        await prefs.setString('myCustomers', json.encode(fetchedCustomers));

        setState(() {
          customers = List<Map<String, String>>.from(
              fetchedCustomers.map((e) => Map<String, String>.from(e)));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contacts Synchronized'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error fetching customers: $e');
    }
  }

  Future<bool> _sendToServer(Map<String, dynamic> customer) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    final url = Uri.parse('https://salespro.livepetal.com/v1/addcontact');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body:
            json.encode({'name': customer['name'], 'phone': customer['phone']}),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error sending customer: $e');
    }
    return false;
  }

  Future<void> loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemDataString = prefs.getString('itemData');
    //print('itemDataString');
    if (itemDataString != null) {
      setState(() {
        servedBy = prefs.getString('userName') ?? '';
        editPrice = prefs.getInt('editPrice') ?? 0;
        Bid = prefs.getString('bid') ?? '';
        products = List<Map<String, dynamic>>.from(json.decode(itemDataString));
      });
    }
  }

  Future<void> loadPayment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPayment = prefs.getString('paymentMethod');
    // print('printing...... $storedPayment');
    List<Map<String, dynamic>> paymentss = storedPayment != null
        ? List<Map<String, dynamic>>.from(json.decode(storedPayment))
        : [];

    setState(() {
      payments = paymentss;
    });
  }

  Future<void> loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString('cart');
    if (cartData != null && cartData.isNotEmpty) {
      setState(() {
        cart = List<Map<String, dynamic>>.from(jsonDecode(cartData));
      });
    }
  }

  void saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cart', jsonEncode(cart));
  }

  void updateQuantity(int index, int change) {
    setState(() {
      cart[index]['qty'] = (cart[index]['qty'] ?? 1) + change;
      if (cart[index]['qty'] < 1) {
        cart[index]['qty'] = 1; // Prevent going below 1
      }
      cart[index]['amount'] = (cart[index]['price'] ?? 0) * cart[index]['qty'];
      saveCart();
    });
  }

  void addName(newName, newPhone) {
    setState(() {
      name = newName;
      phone = newPhone;
    });
  }

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      int index = cart.indexWhere((item) => item['id'] == product['id']);
      if (index == -1) {
        cart.add({...product, 'qty': 1, 'amount': product['price']});
      } else {
        cart[index]['qty'] += 1;
        cart[index]['amount'] = cart[index]['price'] * cart[index]['qty'];
      }
      saveCart();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title']} added to cart!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
      saveCart();
    });
  }

  void checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your cart is empty. Please add items to checkout.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (name.isEmpty) {
      _showAddCustomerModal(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add customer'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedPaymentMethod == 'Select Method') {
      _showPaymentOptions(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select payment method'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Generate a unique sales ID
    String salesID = '$Bid${DateTime.now().millisecondsSinceEpoch}';

    // Create a transaction log
    TransactionLog transactionLog = TransactionLog(
        salesID: salesID, // Add salesID to the transaction
        servedBy: servedBy,
        payMethod: payMethodid,
        name: name,
        phone: phone,
        cart: List.from(cart),
        total: cart.fold(0, (sum, item) => sum + (item['amount'] ?? 0)),
        sent: false);

    // Save the transaction log
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('transaction_logs') ?? [];
    logs.add(jsonEncode(transactionLog.toJson()));
    await prefs.setStringList('transaction_logs', logs);
    await prefs.setString('cart', '');
    selectedPaymentMethod = 'Select Method';

    // Navigate to receipt screen with the current cart items
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(salesLog: transactionLog.toJson()),
      ),
    );

    // Clear the cart
    setState(() {
      cart.clear();
      name = '';
      phone = '';
    });
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
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

  void showPriceInputDialog(BuildContext context, int index) {
    TextEditingController priceController =
        TextEditingController(text: cart[index]['price'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Price',
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
            controller: priceController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 28), // Increased input text size
            decoration: InputDecoration(
              hintText: 'Enter price',
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
                int newPrice =
                    int.tryParse(priceController.text) ?? cart[index]['price'];
                setState(() {
                  cart[index]['price'] = newPrice;
                  cart[index]['amount'] = cart[index]['qty'] * newPrice;
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
    products.sort((a, b) => a['title'].compareTo(b['title']));
    return Scaffold(
      appBar: AppBar(
        title: Text('POS',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300], // Light grey background
              borderRadius: BorderRadius.circular(14), // Border radius
              border: Border.all(color: Colors.grey, width: 1), // Grey border
            ),
            child: IconButton(
              icon: Icon(
                Icons.calculate_outlined,
                color: Colors.black,
                size: 32,
              ),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalculatorScreen()),
                );
              },
            ),
          ),
          SizedBox(
            width: 4,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300], // Light grey background
              borderRadius: BorderRadius.circular(14), // Border radius
              border: Border.all(color: Colors.grey, width: 1), // Grey border
            ),
            child: IconButton(
              icon: Icon(
                Icons.qr_code,
                color: Colors.black,
                size: 32,
              ),
              onPressed: () => _navigateToScanner(),
            ),
          ),
          SizedBox(
            width: 4,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300], // Light grey background
              borderRadius: BorderRadius.circular(14), // Border radius
              border: Border.all(color: Colors.grey, width: 1), // Grey border
            ),
            child: IconButton(
              icon: Icon(
                Icons.add,
                color: Colors.black,
                size: 32,
              ),
              onPressed: () async {
                await showSearch(
                  context: context,
                  delegate: ProductSearch(
                      products: products, addToCart: addToCart, cart: cart),
                );
              },
            ),
          ),
          SizedBox(
            width: 4,
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // Grey outline
                borderRadius: BorderRadius.circular(14), // Border radius
              ),
              padding: EdgeInsets.all(8), // Padding around the textF
              child: Text(
                '₦${formatNumber(cart.fold<num>(0, (sum, item) => sum + (item['amount'] ?? 0)))}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            width: 12,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the left
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 12,
              ),
              Container(
                height: 70, // Set height for the scrollable area
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    bool isSelected =
                        selectedIndex == index; // Check if item is selected

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index; // Update selected index
                        });
                        addToCart(product); // Add product to cart on tap
                      },
                      child: Container(
                        width: 140, // Width of each button
                        margin: EdgeInsets.symmetric(
                            horizontal: 8.0), // Spacing between items
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey), // Grey outline
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? Colors.deepOrange
                              : Colors.white, // Highlight selection
                        ),
                        child: Card(
                          elevation:
                              0, // Remove card elevation to prevent shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: Colors
                              .transparent, // Ensure background color from Container applies
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors
                                            .black, // White text when selected
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₦${product['price'] ?? '0.00'}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors
                                                .black, // White text when selected
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color: (product['qty'] ?? 0) > 0
                                            ? Colors.green // Green if qty > 0
                                            : const Color.fromARGB(255, 177, 40,
                                                30), // Red otherwise
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${product['qty'] ?? '0'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Text('Sales Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              ListView.builder(
                itemCount: cart.length,
                shrinkWrap: true, // Important for using ListView in a Column
                physics: NeverScrollableScrollPhysics(), // Disable scrolling
                itemBuilder: (context, index) {
                  var item = cart[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: item['localImagePath'] != null
                                  ? Image.file(
                                      File(item['localImagePath']),
                                      width: 95,
                                      height: 95,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Display a "no image available" placeholder
                                        return Container(
                                          width: 95,
                                          height: 95,
                                          color: Colors.grey[
                                              300], // Light grey background
                                          child: Icon(
                                            Icons
                                                .image_not_supported, // "No image found" icon
                                            size: 90,
                                            color: Colors.grey[700],
                                          ),
                                        );
                                      },
                                    )
                                  : Icon(Icons.image_not_supported,
                                      size: 90, color: Colors.grey),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => editPrice == 1
                                              ? showPriceInputDialog(
                                                  context, index)
                                              : '',
                                          child: Text(
                                            '${item['title']}\nUnit Price: ₦${formatNumber(item['price'])}',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: Colors.grey),
                                        onPressed: () => removeFromCart(index),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                                Icons.remove_circle_outline,
                                                size: 28),
                                            onPressed: () =>
                                                updateQuantity(index, -1),
                                          ),
                                          GestureDetector(
                                            onTap: () =>
                                                showQuantityInputDialog(
                                                    context, index),
                                            child: Text(
                                              '${item['qty']}',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add_circle_outline,
                                                size: 28),
                                            onPressed: () =>
                                                updateQuantity(index, 1),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "₦${formatNumber(item['amount'])}",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align children to the left
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildGroupedSection([
                    _buildSummaryItem('Subtotal',
                        '₦${formatNumber(cart.fold<num>(0, (sum, item) => sum + (item['amount'] ?? 0)))}'),
                    _buildSummaryItem('Charges', '₦0.00'),
                    _buildSummaryItem('Grand Total',
                        '₦${formatNumber(cart.fold<num>(0, (sum, item) => sum + (item['amount'] ?? 0)))}',
                        isTotal: true),
                    _buildSummaryItem('Payment method', selectedPaymentMethod,
                        onTap: () => _showPaymentOptions(context)),
                  ]),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Data',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.sync),
                            onPressed: () {
                              _fetchCustomer(); // Show add customer dialog
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.person_remove),
                            onPressed: () {
                              _noCustomerName(); // Show add customer dialog
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.person_add),
                            onPressed: () {
                              _showAddCustomerModal(
                                  context); // Show add customer dialog
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.person_search),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CustomerSearchPage(
                                        newName: name,
                                        newPhone: phone,
                                        addName: addName)),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildGroupedSection(
                    [
                      _buildSummaryItem('Name', name),
                      _buildSummaryItem('Phone Number', phone),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity, // Expand to full width
                    child: ElevatedButton(
                      onPressed: checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, // Background color
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                      child: Text(
                        'Complete Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _noCustomerName() {
    setState(() {
      name = 'Customer';
      phone = '';
    });
  }

// Function to show top modal for adding a new customer
  void _showAddCustomerModal(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(16)), // Rounded top corners
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Customer',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close modal
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      phone = value;
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // Close modal without saving
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle saving the new customer information

                          _addCustomer(name, phone);

                          setState(() {
                            name = name;
                            phone = phone;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text('Add Customer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedSection(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: tiles.map((tile) {
          return Column(
            children: [
              tile,
              if (tile != tiles.last) const Divider(height: 1.0),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Widget _buildListTile(String title, IconData icon,
  //     {String trailingText = '', VoidCallback? onTap}) {
  //   return ListTile(
  //     leading: Icon(icon),
  //     title: Text(title),
  //     trailing: trailingText.isNotEmpty
  //         ? Text(trailingText)
  //         : const Icon(Icons.chevron_right),
  //     onTap: onTap,
  //   );
  // }

  Widget _buildSummaryItem(String title, String amount,
      {bool isTotal = false, VoidCallback? onTap}) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (title.toLowerCase() == 'payment method')
                Icon(Icons.arrow_drop_down, color: Colors.blue),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    } else {
      return content;
    }
  }

  String selectedPaymentMethod = 'Select Method'; // Holds the selected method
  String payMethodid = '';

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Divider(),
              ...payments.map<Widget>((payment) {
                return _buildPaymentOption(
                    context, payment['title'], payment['id']);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

// Function to build each payment option
  Widget _buildPaymentOption(
      BuildContext context, String method, String payId) {
    return ListTile(
      title: Text(method, style: TextStyle(fontSize: 16)),
      onTap: () {
        setState(() {
          selectedPaymentMethod = method; // Update selected method
          payMethodid = payId;
        });
        Navigator.pop(context); // Close modal
      },
    );
  }
}

class ProductSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) addToCart;
  final List<Map<String, dynamic>> cart;
  bool _shouldClose = true; // Toggle to control closing behavior

  ProductSearch(
      {required this.products, required this.addToCart, required this.cart});

  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = '';
          close(context, {});
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products
        .where((product) =>
            product['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: product['localImagePath'] != null
              ? Image.file(File(product['localImagePath']),
                  width: 150, height: 150, fit: BoxFit.cover)
              : Icon(Icons.image_not_supported, size: 120, color: Colors.grey),
          title: Text(product['title']),
          subtitle: Text("Price: ${product['price']}"),
          trailing: ElevatedButton(
            onPressed: () {
              addToCart(product);
              // FocusScope.of(context)
              //    .unfocus(); // Unfocus to dismiss the keyboard
              close(context, product);
            },
            child: Text("Add"),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products
        .where((product) =>
            product['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Column(children: [
      // Toggle Switch to Control Closing Behavior
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Close on Add:", style: TextStyle(fontSize: 16)),
            Switch(
              value: _shouldClose,
              onChanged: (value) {
                _shouldClose = value;
                (context as Element).markNeedsBuild(); // Rebuild UI
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final product = suggestions[index];
            final isInCart = cart.any((item) =>
                item['id'] == product['id']); // Check if item is in cart

            return ListTile(
              leading: product['localImagePath'] != null
                  ? Image.file(
                      File(product['localImagePath']),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.image_not_supported,
                      size: 70, color: Colors.grey),
              title: Text(product['title']),
              subtitle: Text("Price: ₦${formatNumber(product['price'])}"),
              trailing: ElevatedButton(
                onPressed: isInCart
                    ? null // Disable button if item is already in cart
                    : () {
                        addToCart(product);
                        FocusScope.of(context).unfocus(); // Dismiss keyboard
                        if (_shouldClose) {
                          close(context, product);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: Colors.grey, width: 1),
                  backgroundColor: isInCart
                      ? Colors.green
                      : Colors.white, // Highlight if in cart
                  foregroundColor:
                      isInCart ? Colors.white : Colors.black, // Text color
                ),
                child: Text(isInCart ? "Added" : "Add"),
              ),
            );
          },
        ),
      )
    ]);
  }
}

class CustomerSearchPage extends StatefulWidget {
  final String newName;
  final String newPhone;
  final Function addName;

  CustomerSearchPage({
    required this.newName,
    required this.newPhone,
    required this.addName,
  });

  @override
  _CustomerSearchPageState createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  List<Map<String, String>> customers = [];
  List<Map<String, String>> filteredCustomers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers(); // Load customers when the page is initialized
  }

  Future<void> _loadCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customersString = prefs.getString('myCustomers');

    if (customersString != null) {
      setState(() {
        customers = List<Map<String, String>>.from(
          json.decode(customersString).map((e) => Map<String, String>.from(e)),
        );
        filteredCustomers =
            List.from(customers); // Initialize filteredCustomers
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      searchQuery = query;
      filteredCustomers = customers.where((customer) {
        return customer['name']!.toLowerCase().contains(query.toLowerCase()) ||
            customer['phone']!.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Customer Name or Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
              onChanged: _filterCustomers,
            ),
            SizedBox(height: 20),
            Expanded(
              child: filteredCustomers.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return ListTile(
                          title: Text(customer['name']!,
                              style: TextStyle(fontSize: 16)),
                          trailing: Text(
                            customer['phone']!,
                            style: TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            // Handle customer selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Customer Selected: ${customer['name']}, ${customer['phone']}'),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            widget.addName(customer['name'], customer['phone']);
                            Navigator.of(context)
                                .pop(); // Close modal on selection
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text('No customers found',
                          style: TextStyle(color: Colors.grey)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
