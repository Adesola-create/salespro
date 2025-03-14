import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';
import 'home_page.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> localItemData = [];
  List<dynamic> filteredItems = [];
  List<Map<String, dynamic>> cart = [];
  bool isFetching = true;
  String business = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLocalData();
    fetchItems();
    loadCart();
    searchController.addListener(_filterItems);
    _fetchPayment();
  }

  void _filterItems() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredItems = List.from(localItemData);
      } else {
        filteredItems = localItemData.where((item) {
          String title = (item['title'] ?? '').toLowerCase();
          String category = (item['category'] ?? '').toLowerCase();
          return title.contains(query) || category.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchPayment() async {
    //print('fetching payments.');
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('apiKey');
    final url = Uri.parse('https://salespro.livepetal.com/v1/getpaymethod');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> fetchPayment =
            List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
        await prefs.setString('paymentMethod', json.encode(fetchPayment));
      }
    } catch (e) {
      print('Error fetching: $e');
    }
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

  Future<void> loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemDataString = prefs.getString('itemData');
    print('Loading data');
    if (itemDataString != null) {
      setState(() {
        localItemData = json.decode(itemDataString);
        filteredItems = List.from(localItemData);
        isFetching = false;
        business = prefs.getString('business') ?? '';
      });
    }
  }

  Future<void> fetchItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // isFetching = true;
    });

    const String url = 'https://salespro.livepetal.com/v1/products';
    String? token = prefs.getString('apiKey'); // Use a valid token

    try {
      // Create headers
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // print('printing..... ${response.body}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> fetchedData = responseData['data'] ?? [];

        // Download and save images locally
        await saveImagesLocally(fetchedData);

        // Update local state
        setState(() {
          localItemData = fetchedData;
          isFetching = false;
        });
        // Update filtered items after fetching new data
        _filterItems();
      } else {
        debugPrint('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      // setState(() {
      //   isFetching = false;
      // });
    }
  }

  Future<void> saveImagesLocally(List<dynamic> data) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Dio dio = Dio();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var item in data) {
      String imageUrl = item['photo'];
      String imageName = imageUrl.split('/').last;
      String imagePath = '${appDocDir.path}/$imageName';

      if (!File(imagePath).existsSync()) {
        try {
          await dio.download(imageUrl, imagePath);
          item['localImagePath'] = imagePath;
        } catch (e) {
          debugPrint('Error downloading image: $e');
        }
      } else {
        item['localImagePath'] = imagePath;
      }
    }
    await prefs.setString('itemData', json.encode(data));
  }

String formatNumber(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }


  @override
  Widget build(BuildContext context) {
    // Group items by category
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in filteredItems) {
      String category = item['category'] ?? "Uncategorized";
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$business",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(selectedIndex: 1),
                    ),
                  );
                },
              ),
              if (cart.length > 0)
                Positioned(
                  right: 2,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator())
          : filteredItems.isEmpty
              ? Center(child: Text("No data available"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search your cravings...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.0),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),

                      // Display grouped items
                     Padding(
  padding: const EdgeInsets.all(12.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: groupedItems.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(
              entry.key,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
  height: 190,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: entry.value.map((item) {
      return Container(
        margin: EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
          //border: Border.all(color: Colors.grey.shade300), // Light border for flat look
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2), // Subtle shadow for depth
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0), // Ensure rounded corners on content
          child: Container(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                item['localImagePath'] != null
                    ? Image.file(
                        File(item['localImagePath']),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.image_not_supported,
                        size: 120,
                        color: Colors.grey,
                      ),
                SizedBox(height: 5),
                Text(
                  item['title'] ?? "No Title",
                  textAlign: TextAlign.left, // Align title to the left
                  maxLines: 1, // Limit to 1 line
                  overflow: TextOverflow.ellipsis, // Handle overflow
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '  ₦${formatNumber(item['price'] ?? '0.00')}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: (item['qty'] ?? 0) > 0
                            ? Colors.green // Green if qty > 0
                            : const Color.fromARGB(255, 177, 40, 30), // Red otherwise
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['qty'] ?? '0'}  ',
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
      );
    }).toList(),
  ),
),

        ],
      );
    }).toList(),
  ),
)
                    ],
                  ),
                ),
    );
  }
}
