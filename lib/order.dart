import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:salespro/constants.dart';
import 'orderdetail.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> allOrders = [];
  String selectedStatus = 'Upcoming';
  Map<String, List<Map<String, dynamic>>> categorizedOrders = {
    'Upcoming': [],
    'Completed': [],
    'Canceled': [],
  };
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    fetchOrders();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedStatus =
            ['Upcoming', 'Completed', 'Canceled'][_tabController.index];
        orders = categorizedOrders[selectedStatus] ?? [];
      });
    });
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });

    try {
      final response = await http.get(
        Uri.parse('https://salespro.livepetal.com/v1/businessorders'),
        headers: {
          'Authorization': 'p2cjbobmwa1mraiv175hji7d5xwewetvwtvte',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          List ordersFromApi = data['data'];

          allOrders.clear();
          categorizedOrders = {
            'Upcoming': [],
            'Completed': [],
            'Canceled': [],
          };

          for (var order in ordersFromApi) {
            int status = int.tryParse(order['status'].toString()) ?? 1;
            var orderData = {
              'customer_name': order['customer'],
              'phone': order['phone'],
              'total': order['total'],
              'address': 'Not Provided',
              'items': order['cart'].map((item) {
                return {
                  'image': item['image'] ?? '',
                  'name': item['title'],
                  'qty': item['qty'] ?? 1,
                  'price': item['price'],
                };
              }).toList(),
              'status': status,
            };
            print('$orderData');
            if (status == 1) {
              categorizedOrders['Upcoming']!.add(orderData);
            } else if (status == 2) {
              categorizedOrders['Completed']!.add(orderData);
            } else if (status == 3) {
              categorizedOrders['Canceled']!.add(orderData);
            }
          }

          if (mounted) {
            setState(() {
              orders = categorizedOrders['Upcoming'] ?? [];
              isLoading =
                  false; // Set loading state to false after data is loaded
            });
          }
        } else {
          throw Exception('Error fetching orders: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load orders: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading state to false in case of error
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Customer Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Selected tab color
          unselectedLabelColor: Colors.white54, // Unselected tab color
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Canceled'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator(), // Loader displayed while fetching
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(categorizedOrders['Upcoming']),
                _buildOrderList(categorizedOrders['Completed']),
                _buildOrderList(categorizedOrders['Canceled']),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>>? orderList) {
    if (orderList == null || orderList.isEmpty) {
      return Center(child: Text('No orders available.'));
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView.builder(
        itemCount: orderList.length,
        itemBuilder: (context, index) {
          var order = orderList[index];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(order['customer_name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone: ${order['phone']}',
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ' ₦${order['total']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsPage(order: order),
                  ),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    fetchOrders(); // Refresh the order list on the main page
                  }
                });
                            },
            ),
          );
        },
      ),
    );
  }
}
