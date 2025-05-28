import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoriesPage extends StatefulWidget {
  final List<String> availableCategories;
  final Map<String, int> categoryProductCounts;

  const CategoriesPage({
    Key? key,
    required this.availableCategories,
    required this.categoryProductCounts,
  }) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    // If the categoryProductCounts map is empty, calculate product counts
    if (widget.categoryProductCounts.isEmpty) {
      _calculateProductCounts();
    }
  }

  // Method to calculate the number of products in each category
  Future<void> _calculateProductCounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemDataString = prefs.getString('itemData');

    if (itemDataString != null) {
      List<dynamic> products = json.decode(itemDataString);

      // Count products by category
      Map<String, int> counts = {};
      for (var product in products) {
        String category = product['category'] ?? 'Uncategorized';
        counts[category] = (counts[category] ?? 0) + 1;
      }

      // Update the counts in the widget's map
      setState(() {
        widget.categoryProductCounts.clear();
        widget.categoryProductCounts.addAll(counts);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: ListView.builder(
        itemCount: widget.availableCategories.length,
        itemBuilder: (context, index) {
          String category = widget.availableCategories[index];
          // Get product count inside build method to ensure it updates
          int productCount = widget.categoryProductCounts[category] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              child: ListTile(
                title: Text(category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$productCount',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () async {
                  final updatedName = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryProductsPage(category: category),
                    ),
                  );

                  if (updatedName != null &&
                      updatedName is String &&
                      updatedName != category) {
                    // Trigger a recount of products after update
                    await _calculateProductCounts();
                    setState(() {
                      // Replace old name in availableCategories
                      final index =
                          widget.availableCategories.indexOf(category);
                      if (index != -1) {
                        widget.availableCategories[index] = updatedName;
                      }
                    });
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryProductsPage extends StatefulWidget {
  final String category;

  const CategoryProductsPage({Key? key, required this.category})
      : super(key: key);

  @override
  _CategoryProductsPageState createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<dynamic> categoryProducts = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
  }

  Future<void> _loadCategoryProducts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemDataString = prefs.getString('itemData');

    if (itemDataString != null) {
      List<dynamic> allProducts = json.decode(itemDataString);
      setState(() {
        categoryProducts = allProducts
            .where((product) => product['category'] == widget.category)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category} Products',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final TextEditingController controller =
                  TextEditingController(text: widget.category);
              final String? newCategoryName = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Edit Category Name'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                          hintText: 'Enter new category name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );

              if (newCategoryName != null &&
                  newCategoryName.trim() != widget.category) {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('apiKey') ?? '';
                debugPrint('Stored API Key: ${prefs.getString('apiKey')}');

                final url = Uri.parse(
                    'https://salespro.livepetal.com/v1/updatecategory');

                try {
                  final response = await http.post(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: json.encode({
                      'oldcategory': widget.category,
                      'newcategory': newCategoryName,
                    }),
                  );

                  if (response.statusCode == 200) {
                    //  Update local storage
                    String? itemDataString = prefs.getString('itemData');
                    if (itemDataString != null) {
                      List<dynamic> allProducts = json.decode(itemDataString);
                      for (var product in allProducts) {
                        if (product['category'] == widget.category) {
                          product['category'] = newCategoryName;
                        }
                      }
                      await prefs.setString(
                          'itemData', json.encode(allProducts));
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Category updated successfully')),
                    );

                    // Reload products and pop back to categories
                    if (mounted) {
                      Navigator.pop(context,
                          newCategoryName); // Return new name to parent
                    }
                  } else {
                    debugPrint('API Error Response: ${response.body}');
                    throw Exception('API error: ${response.reasonPhrase}');
                  }
                } catch (e) {
                  debugPrint('Exception: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(4.0),
        itemCount: categoryProducts.length,
        itemBuilder: (context, index) {
          final product = categoryProducts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.grey.withOpacity(0.5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(4.0),
              title: Text(
                product['title'] ?? 'Unnamed Product',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₦${product['price']?.toString() ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quantity: ${product['quantity']?.toString() ?? '0'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
