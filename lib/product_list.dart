import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'Product_profile.dart';

class ProductsPage extends StatefulWidget {
  final Function(List<String>)?
      onCategoriesFetched; // Add this line for callback

  const ProductsPage({super.key, this.onCategoriesFetched});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> products = [];
  bool isFetching = true; // Track if data is being fetched
  List<Map<String, dynamic>> localItemData = []; // Store fetched data
  
  // Category modal controllers
  TextEditingController categoryTitleController = TextEditingController();
  TextEditingController categoryDescriptionController = TextEditingController();
  TextEditingController categoryOtherInfoController = TextEditingController();
  
  // Product modal controllers
  TextEditingController productTitleController = TextEditingController();
  TextEditingController productDescriptionController = TextEditingController();
  TextEditingController productOtherInfoController = TextEditingController();
  TextEditingController sellingPriceController = TextEditingController();
  TextEditingController barcodeController = TextEditingController();
  
  List<String> availableCategories = []; // List to store categories from API
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    loadLocalData();
  }

   Future<void> loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String itemDataString = prefs.getString('itemData') ?? '';
    List<dynamic> fetchedData = jsonDecode(itemDataString);
    List<Map<String, dynamic>> typedFetchedData =
        fetchedData.map((item) => item as Map<String, dynamic>).toList();

    List<String> storedCategories =
        prefs.getStringList('availableCategories') ?? [];

    if (storedCategories.isEmpty) {
      Set<String> uniqueCategories = {};
      for (var item in typedFetchedData) {
        if (item['category'] != null) {
          uniqueCategories.add(item['category'].toString());
        }
      }
      storedCategories = uniqueCategories.toList();
    }

    if (widget.onCategoriesFetched != null) {
      widget.onCategoriesFetched!(storedCategories);
    }

    setState(() {
      products = List<Map<String, dynamic>>.from(json.decode(itemDataString));
      products.sort((a, b) =>
          (a['title'] ?? '').toString().toLowerCase().compareTo(
              (b['title'] ?? '').toString().toLowerCase()));
      isFetching = false;
      availableCategories = storedCategories;
    });
  }

  Future<void> _addCategory(String title, String note, String info) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    const String apiUrl = 'https://salespro.livepetal.com/v1/addcategory';

    final String formattedTitle = _capitalizeFirstLetter(title);

    final Map<String, dynamic> categoryData = {
      'title': formattedTitle,
      'note': note,
      'info': info,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(categoryData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('see updated category response hereeeeee: ${response.body}');
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );

        // Add to local availableCategories
        setState(() {
          availableCategories.add(formattedTitle);
        });

        // Persist to SharedPreferences
        prefs.setStringList('availableCategories', availableCategories);

        Navigator.of(context).pop(); // Close modal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }

  String _capitalizeFirstLetter(String text) {
    return text.isNotEmpty
        ? text[0].toUpperCase() + text.substring(1).toLowerCase()
        : '';
  }

  Future<void> fetchItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    const String url = 'https://salespro.livepetal.com/v1/products';
    String? token = prefs.getString('apiKey');
    print('Using API Key: $token');

    String? localData = prefs.getString('localProducts');
    if (localData != null) {
      List<Map<String, dynamic>> loadedProducts =
          List<Map<String, dynamic>>.from(json.decode(localData));
      loadedProducts.sort((a, b) =>
          (a['title'] ?? '').toString().toLowerCase().compareTo(
              (b['title'] ?? '').toString().toLowerCase()));
      setState(() {
        products = loadedProducts;
        isFetching = false;
      });
    } else {
      try {
        Map<String, String> headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };

        final response = await http.post(Uri.parse(url), headers: headers);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          List<dynamic> fetchedData = responseData['data'] ?? [];
          List<Map<String, dynamic>> typedFetchedData =
              fetchedData.map((item) => item as Map<String, dynamic>).toList();
          await saveImagesLocally(typedFetchedData);

          prefs.setString('localProducts', json.encode(typedFetchedData));

          Set<String> uniqueCategories = {};
          for (var item in typedFetchedData) {
            if (item['category'] != null) {
              uniqueCategories.add(item['category'].toString());
            }
          }
          List<String> typedCategories = uniqueCategories.toList();

          if (widget.onCategoriesFetched != null) {
            widget.onCategoriesFetched!(typedCategories);
          }

          String? addedProductsRaw = prefs.getString('addedProducts');
          List<Map<String, dynamic>> locallyAddedProducts = [];

          if (addedProductsRaw != null) {
            List<dynamic> parsed = json.decode(addedProductsRaw);
            locallyAddedProducts =
                parsed.map((item) => item as Map<String, dynamic>).toList();
          }

          List<Map<String, dynamic>> combinedProducts = [
            ...typedFetchedData,
            ...locallyAddedProducts
          ];

          combinedProducts.sort((a, b) =>
              (a['title'] ?? '').toString().toLowerCase().compareTo(
                  (b['title'] ?? '').toString().toLowerCase()));

          prefs.setString('localProducts', json.encode(combinedProducts));

          setState(() {
            products = combinedProducts;
            availableCategories = typedCategories;
            isFetching = false;
          });
        } else {
          debugPrint('Error: ${response.statusCode} ${response.body}');
          setState(() {
            isFetching = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching data: $e');
        setState(() {
          isFetching = false;
        });
      }
    }
  }
  // Function to add a new product
  Future<void> _addProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    const String apiUrl = 'https://salespro.livepetal.com/v1/addproduct';

    final Map<String, dynamic> productData = {
      'title': productTitleController.text,
      'note': productDescriptionController.text,
      'category': selectedCategory,
      'price': double.tryParse(sellingPriceController.text) ?? 0,
      'barcode': barcodeController.text,
      'info': productOtherInfoController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(productData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('see the response body here naaaaaaaaa: $productData');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );

        // Save product locally
        await _saveProductLocally(productData);
        Navigator.of(context).pop(); // Close the modal
        fetchItems(); // Refresh the product list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  Future<void> _saveProductLocally(Map<String, dynamic> productData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    const String localKey = 'storedProducts';

    List<String> existing = prefs.getStringList(localKey) ?? [];
    existing.add(json.encode(productData)); // Add new product
    await prefs.setStringList(localKey, existing);
  }

  Future<void> saveImagesLocally(List<Map<String, dynamic>> items) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    for (var item in items) {
      if (item['photo'] != null) {
        String imageUrl = item['photo'];
        String imageName =
            path.basename(imageUrl); // Extract the image name from the URL
        String localImagePath =
            path.join(appDocPath, imageName); // Construct full file path

        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            File imageFile = File(localImagePath);
            await imageFile.writeAsBytes(response.bodyBytes);
            item['localImagePath'] = localImagePath;
          } else {
            item['localImagePath'] = null;
          }
        } catch (e) {
          item['localImagePath'] = null;
        }
      } else {
        item['localImagePath'] = null;
      }
    }
  }

  String formatNumber(dynamic number) {
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[400],
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    BackButton(),
                    Text('Product List'),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showAddCategoryModal(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Category'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showAddProductModal(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Product'),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      loadLocalData(); // Reset to original list if search is empty
                    } else {
                      products = products.where((product) {
                        final title = (product['title'] ?? '').toString().toLowerCase();
                        final category = (product['category'] ?? '').toString().toLowerCase();
                        final searchTerm = value.toLowerCase();
                        return title.contains(searchTerm) || category.contains(searchTerm);
                      }).toList();
                    }
                  });
                },
              ),
            ),
          ],
        ),
        toolbarHeight: 120,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 16),
            Expanded(
              child: isFetching
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loading indicator
                  : products.isEmpty
                      ? const Center(
                          child: Text(
                              'No products found.')) // Handle empty product list
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];

                            return ListTile(
                              leading: product['localImagePath'] != null &&
                                      File(product['localImagePath']).existsSync()
                                  ? Image.file(
                                      File(product['localImagePath']),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.image_not_supported,
                                      size: 70,
                                      color: Colors.grey,
                                    ),
                              title: Text(
                                product['title'] ??
                                    product['name'] ??
                                    'No Title',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['category'] ?? 'N/A',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    "Price: ₦${formatNumber(product['price'])} | Qty: ${product['qty'] ?? 0}",
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                              
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: () {
                                  _openProductProfile(product);
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProductProfile(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductProfilePage(
          product: product,
          availableCategories: availableCategories,
        ),
      ),
    );
  }

  void _showAddCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Product Category',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: categoryTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: categoryDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: categoryOtherInfoController,
                    decoration: const InputDecoration(
                      labelText: 'Other Information',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _addCategory(
                        categoryTitleController.text,
                        categoryDescriptionController.text,
                        categoryOtherInfoController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddProductModal(BuildContext context) {
    selectedCategory = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Product',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  availableCategories.isEmpty
                      ? const Text("No categories available")
                      : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedCategory,
                          hint: const Text('Select category'),
                          items: availableCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory =
                                  newValue; // Update the local selected category
                            });
                          },
                        ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: productTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: productDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: productOtherInfoController,
                    decoration: const InputDecoration(
                      labelText: 'Other Information',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: sellingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _addProduct(); // Call the add product logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 50), // Make button full width
                    ),
                    child: const Center(child: Text('Add Product')), // Center the text
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
