import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:salespro/constants.dart';
import 'orderdetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    loadOrders();
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
 String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  String formatSalesDate(String salesDate) {
  // Parse the original sales date
  DateTime dateTime = DateTime.parse(salesDate); // Use DateTime.parse if the format is ISO 8601

  // Format the date
  String formattedDate = DateFormat('MMM d, HH:mm').format(dateTime);
  
  // Get the day of the month and determine the suffix (st, nd, rd, th)
  String dayWithSuffix = '${dateTime.day}${getDaySuffix(dateTime.day)}';
  
  // Combine formatted parts
  return '${formattedDate.replaceFirst('${dateTime.day}', dayWithSuffix)}';
}

// Function to determine the suffix
String getDaySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th'; // Special case for 11th, 12th, 13th
  }
  switch (day % 10) {
    case 1: return 'st';
    case 2: return 'nd';
    case 3: return 'rd';
    default: return 'th';
  }
}

  Future<void> loadOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
   String orderString = prefs.getString('orders') ?? '';
    Map<String, dynamic> jsonData = jsonDecode(orderString);
  categorizedOrders = {
        'Upcoming': List<Map<String, dynamic>>.from(jsonData['Upcoming']),
        'Completed': List<Map<String, dynamic>>.from(jsonData['Completed']),
        'Canceled': List<Map<String, dynamic>>.from(jsonData['Canceled']),
      };
    setState(() {
      // orders = categorizedOrders['Completed'] ?? [];
      isLoading = false; 
    });
  }

  Future<void> fetchOrders() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  try {
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('https://salespro.livepetal.com/v1/businessorders'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Log the full response to check structure
      print('API Response: $data');

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

          // Check if 'cart' exists and contains items
          var cartItems = order['cart'] ?? [];

          var orderData = {
            'customer_name': order['customer'] ?? 'Unknown',
            'phone': order['phone'] ?? 'No Phone',
            'total': order['total'] ?? 0.0,
            'address': order['address'] ?? 'Not Provided',
            'salesdate': order['salesdate'] ?? '',
            'salesid': order['salesid'] ?? '',
            'cart': cartItems.map((item) {
              return {
                'id': item['id'] ?? '',
                'title': item['title'] ?? 'Unnamed Item',
                'qty': item['qty'] ?? 1,
                'price': item['price'] ?? 0,
              };
            }).toList(),
            'status': status,
          };

          // Add the order data to the appropriate category
          if (status == 1) {
            categorizedOrders['Upcoming']!.add(orderData);
          } else if (status == 2) {
            categorizedOrders['Completed']!.add(orderData);
          } else if (status == 0) {
            categorizedOrders['Canceled']!.add(orderData);
          }
        }

        // Sort the orders by sales date in descending order
        _sortOrdersByDate(categorizedOrders['Upcoming']);
        _sortOrdersByDate(categorizedOrders['Completed']);
        _sortOrdersByDate(categorizedOrders['Canceled']);

        await prefs.setString('orders', json.encode(categorizedOrders));
        if (mounted) {
          setState(() {
            orders = categorizedOrders['Upcoming'] ?? [];
            isLoading = false; // Set loading state to false after data is loaded
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

// Helper method to sort orders by sales date
void _sortOrdersByDate(List<Map<String, dynamic>>? ordersList) {
  if (ordersList != null) {
    ordersList.sort((b, a) {
      DateTime dateA = DateTime.parse(a['salesdate']); // Parse salesdate
      DateTime dateB = DateTime.parse(b['salesdate']); // Parse salesdate
      return dateA.compareTo(dateB); // Sort in descending order
    });
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
         automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Selected tab color
          unselectedLabelColor: Colors.white54, // Unselected tab color
          tabs: [
            Tab(
              child: Text(
                'Upcoming',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Bold font for the tab
                  fontSize: 16.0, // Increased font size for the tab
                ),
              ),
            ),
            Tab(
              child: Text(
                'Completed',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Bold font for the tab
                  fontSize: 16.0, // Increased font size for the tab
                ),
              ),
            ),
            Tab(
              child: Text(
                'Canceled',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Bold font for the tab
                  fontSize: 16.0, // Increased font size for the tab
                ),
              ),
            ),
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
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  elevation: 0,
  margin: EdgeInsets.symmetric(vertical: 5),
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white),
    ),
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            order['customer_name'] ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis, // Prevent overflow if the name is too long
          ),
        ),
        Text(
          "₦${formatNumber(num.parse(order['total'] ?? '0'))}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    ),
    subtitle: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${order['phone'] ?? ''}',
            style: TextStyle(color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis, // Prevent overflow if the phone number is too long
          ),
        ),
        Text(
          formatSalesDate(order['salesdate'] ?? ''),
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
