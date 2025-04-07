import 'package:flutter/material.dart';
import 'package:salespro/constants.dart'; // Ensure this import is correct
import 'cartorder.dart'; // Ensure this path is correct

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order; // Field to hold order data

  // Constructor to accept the order data
  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    // Check if 'cart' exists and is a List; default to empty list if null
    final cartItems = widget.order['cart'] ?? []; 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Check if the cart has items
            if (cartItems.isEmpty)
              Center(child: Text('No items in this order.'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];

                    int qty = item['qty'] ?? 1;  // Default quantity to 1 if null
                    double price = (item['price'] as num).toDouble();  // Ensure price is a double
                    double total = qty * price;  // Calculate total for current item

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: (item['image'] != null && item['image'].isNotEmpty)
                            ? Image.network(item['image'],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                        title: Text(item['title'] ?? 'Unnamed Item',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$qty x ₦${item['price']}',
                            style: TextStyle(color: Colors.grey[700])),
                        trailing: Text('₦${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            )),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartOrderPage(order: widget.order), // Replace with your actual cart order page
                      ),
                    );
                  },
                  child: Text('Process Order',
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