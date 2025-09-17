import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_transaction.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  List<Map<String, String>> customers = [];
  List<Map<String, String>> filteredCustomers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customersString = prefs.getString('myCustomers');

    if (customersString != null) {
      setState(() {
        customers = List<Map<String, String>>.from(
          json.decode(customersString).map((e) => Map<String, String>.from(e)),
        );
        filteredCustomers = List.from(customers);
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
      appBar: AppBar(title: const Text('Customers')),
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
            const SizedBox(height: 20),
            Expanded(
              child: filteredCustomers.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final initial = customer['name']!.isNotEmpty
                            ? customer['name']![0].toUpperCase()
                            : '';

                        return Container(
                          // Removed margin to reduce space
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding:
                                    EdgeInsets.zero, // Remove padding
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customer['name']!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: Text(
                                  customer['phone']!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                onTap: () {
                                  // Navigate to the TransactionsPage
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CustomerHistoryPage(
                                        customerName: customer['name']!,
                                        customerPhone: customer['phone']!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                  height: 1.0), // Reduced height of the divider
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

