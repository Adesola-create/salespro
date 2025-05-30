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
import 'itemhistory.dart';
import 'account.dart';
import 'stock_management.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
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
  DateTime selectedDate = DateTime.now();

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    final url = Uri.parse('https://salespro.livepetal.com/v1/getpaymethod');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
    const String url = 'https://salespro.livepetal.com/v1/products';
    String? token = prefs.getString('apiKey');

    try {
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> fetchedData = responseData['data'] ?? [];
        await saveImagesLocally(fetchedData);

        setState(() {
          localItemData = fetchedData;
          isFetching = false;
        });
        _filterItems();
      } else {
        debugPrint('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
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

      if (!File(imagePath).existsSync() && imageName.isNotEmpty) {
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$business",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AccountPage()),
                    );
                  },
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
                //const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StockManagementPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color:
                  primaryColor, // Deep orange background for the external container
              borderRadius: const BorderRadius.vertical(
                  bottom:
                      Radius.circular(16.0)), // Rounded corners at the bottom
            ),
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search your store...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none, // Remove border color
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.black), // Change icon color to black
                      filled: true,
                      fillColor:
                          Colors.white, // Background color of the text field
                      hintStyle: const TextStyle(
                          color: Colors.black), // Hint text color
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0), // Reduce height
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white, // Change icon color to white
                        size: 28,
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
                    if (cart.isNotEmpty)
                      Positioned(
                        right: 2,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(
                  height: 52,
                ),
              ],
            ),
          ),
          isFetching
              ? const Center(child: CircularProgressIndicator())
              : filteredItems.isEmpty
                  ? const Center(child: Text("No data available"))
                  : Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedItems.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 0),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 190,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: entry.value.map((item) {
                                        return Container(
                                          margin: const EdgeInsets.all(6.0),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                blurRadius: 5,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ItemHistoryPage(
                                                      itemName: item['title'] ??
                                                          "No Title",
                                                      salesDate: selectedDate,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 120,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    item['localImagePath'] !=
                                                                null &&
                                                            File(item[
                                                                    'localImagePath'])
                                                                .existsSync()
                                                        ? Image.file(
                                                            File(item[
                                                                'localImagePath']),
                                                            width: 120,
                                                            height: 120,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 120,
                                                            color: Colors.grey,
                                                          ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      item['title'] ??
                                                          "No Title",
                                                      textAlign: TextAlign.left,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          '₦${formatNumber(item['price'] ?? '0.00')}',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical:
                                                                      4.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: (item['qty'] ??
                                                                        0) >
                                                                    0
                                                                ? Colors.green
                                                                : const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    177,
                                                                    40,
                                                                    30),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            '${item['qty'] ?? '0'} ',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
