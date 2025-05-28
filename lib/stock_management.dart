import 'package:flutter/material.dart';
import 'constants.dart';
import 'product_list.dart';
import 'categories.dart';



class StockManagementPage extends StatefulWidget {
  const StockManagementPage({Key? key}) : super(key: key);

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  List<String> availableCategories = []; // List to store categories
 Map<String, int> categoryProductCounts = {};

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Stock Management', style: TextStyle(color: Colors.white)),
      backgroundColor: primaryColor,
    ),
    body: ListView(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Space around the container
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
            border: Border.all(
              color: Colors.grey, // Border color
              width: 1.0, // Border width
            ),
          ),
          child: ListTile(
            title: const Text('Manage Stock'),
            trailing: const Icon(Icons.arrow_forward_ios), // Arrow icon
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductsPage(
                  onCategoriesFetched: (categories) {
                    setState(() {
                      availableCategories = categories; // Store fetched categories
                    });
                  },
                )),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Space around the container
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
            border: Border.all(
              color: Colors.grey, // Border color
              width: 1.0, // Border width
            ),
          ),
          child: ListTile(
            title: const Text('Categories'),
            trailing: const Icon(Icons.arrow_forward_ios), 
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoriesPage(availableCategories: availableCategories, categoryProductCounts: categoryProductCounts,),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}