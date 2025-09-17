import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro/constants.dart'; // Ensure this import is correct
import 'package:shared_preferences/shared_preferences.dart';
import 'cartorder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order; // Field to hold order data

  // Constructor to accept the order data
  const OrderDetailsPage({super.key, required this.order});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
 Future<void> cancelOrder(String salesId, BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Processing...'),
      duration: Duration(seconds: 2),
    ),
  );

  const url = 'https://salespro.livepetal.com/v1/cancelorder';
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiKey') ?? ''; // Retrieve apiKey from SharedPreferences

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key not found. Please login again.'),
          duration: Duration(seconds: 3),
        ),
      );
      return; // Stop execution if the API key is not available
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include the Bearer token here
      },
      body: json.encode({
        'salesid': salesId,
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful cancellation
      print('Order cancelled successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      //  Navigator.push replacement to avoid context errors:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(selectedIndex: 2),
        ),
      );
    } else {
      // Handle errors
      print('Failed to cancel order: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: ${response.body}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (error) {
    // Handle network errors or other unexpected errors
    print('Error occurred: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error occurred: $error'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
  String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Check if 'cart' exists and is a List; default to empty list if null
    final cartItems = widget.order['cart'] ?? [];
    // final total = widget.order['total'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
         automaticallyImplyLeading: false,
        actions: [
          if (widget.order['status'] == 1) // Check order status
            Padding(
              padding: const EdgeInsets.only(
                  right: 16.0), // Specify the right padding here
              child: GestureDetector(
                onTap: () {
                  // Call the cancel order function with the salesid
                  cancelOrder(widget.order['salesid'], context); // Pass the sales ID and auth token
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10), // Padding around the text
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Background color of the button
                    border: Border.all(
                        color: Colors.white, width: 1), // Grey border
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  child: const Text(
                    'Cancel Order',
                    style: TextStyle(
                      color: Colors.white, // Text color
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Check if the cart has items
            if (cartItems.isEmpty)
              const Center(child: Text('No items in this order.'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    int qty = item['qty'] ?? 1; // Default quantity to 1 if null
                    double price = (item['price'] as num)
                        .toDouble(); // Ensure price is a double
                    double total = qty * price; // Calculate total for current item

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading:
                            (item['image'] != null && item['image'].isNotEmpty)
                                ? Image.network(item['image'],
                                    width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey),
                        title: Text(item['title'] ?? 'Unnamed Item',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '$qty x ₦${formatNumber(item['price'])}',
                            style: TextStyle(color: Colors.grey[700])),
                        trailing: Text(
                          '₦${formatNumber(total)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (widget.order['status'] == 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      print(widget.order);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartOrderPage(
                              order: widget
                                  .order), // Replace with your actual cart order page
                        ),
                      );
                    },
                    child: const Text('Process Order',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
