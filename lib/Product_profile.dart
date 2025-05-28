import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'itemhistory.dart';
import 'dart:convert';

class ProductProfilePage extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<String> availableCategories;

  const ProductProfilePage({
    Key? key,
    required this.product,
    required this.availableCategories,
  }) : super(key: key);

  @override
  _ProductProfilePageState createState() => _ProductProfilePageState();
}

class _ProductProfilePageState extends State<ProductProfilePage> {
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  DateTime selectedDate = DateTime.now(); // Default to current date
  String? selectedCategory;
  String key = '';
  String value = '';

  @override
  void initState() {
    super.initState();
    priceController.text = widget.product['price']?.toString() ?? '';
    descriptionController.text = widget.product['description'] ?? '';
    nameController.text = widget.product['name'] ?? '';
    categoryController.text = widget.product['category'] ?? '';
    selectedCategory = widget.product['category'];
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath =
        prefs.getString('product_${widget.product['id']}_image');

    if (imagePath != null) {
      setState(() {
        widget.product['localImagePath'] = imagePath; // Set the loaded path
      });
    }
  }

 Future<void> _editImage(BuildContext context) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    String newImagePath = pickedFile.path;

    // Get the product ID
    String productId = widget.product['id'] ?? '';
    print('Product ID: $productId'); // Debugging line

    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Product ID is not assigned.')),
      );
      return; // Exit if product ID is not valid
    }

    // Upload the image to the server
    bool uploadSuccess = await _uploadImageToApi(File(newImagePath), productId);
    if (uploadSuccess) {
      setState(() {
        widget.product['localImagePath'] = newImagePath; // Update path
      });

      // Save the new image path to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'product_${widget.product['id']}_image', newImagePath
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update image.')),
      );
    }
  }
}

Future<bool> _uploadImageToApi(File imageFile, String productId) async {
  const String apiUrl = 'https://salespro.livepetal.com/v1/addphoto';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('apiKey');

  var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  // Add the image file
  request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

  // Add the product ID
  request.fields['id'] = productId;

  print('Uploading image with Product ID: $productId'); // Debugging line

  try {
    var response = await request.send();
    // Read the response body
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print('Image uploaded successfully');
      print('Response: $responseData');
      return true;
    } else {
      print('Failed to upload image: ${response.statusCode}');
      print('Response: $responseData');
      return false;
    }
  } catch (e) {
    print('Error uploading image: $e');
    return false;
  }
}
  Future<void> _updateProduct() async {
    final keyvalue = key == 'cid' ? widget.product['category'] : value;
    final updatedProduct = {
      "id": widget.product['id'],
      "key": key,
      "value": keyvalue,
    };
    //print(jsonEncode(updatedProduct));
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('apiKey');

      final response = await http.post(
        Uri.parse('https://salespro.livepetal.com/v1/updateproduct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedProduct),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        // Save to local storage as well
        await prefs.setString(
            'product_${widget.product['id']}', jsonEncode(updatedProduct));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product on server.')),
        );
      }
    } catch (e) {
      print("Error updating product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred during update.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product['title'] ??
              widget.product['name'] ??
              'Product Profile',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Stack(
  children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: widget.product['localImagePath'] != null &&
                                      File(widget.product['localImagePath']).existsSync()
          ? Image.file(
              File(widget.product['localImagePath']),
              fit: BoxFit.cover,
              height: 100,
              width: 100,
            )
          : Container(
              height: 100,
              width: 100,
              color: Colors.grey[300],
              child: Icon(Icons.image,
                  size: 50, color: Colors.grey),
            ),
    ),
    Positioned(
      bottom: -15,
      right: -15,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.add_circle,
              size: 40, color: Colors.white),
          onPressed: () => _editImage(context),
        ),
      ),
    ),
  ],
),            
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product['title'] ?? 'No Title',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Category: ${widget.product['category'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          'Price: ₦${widget.product['price']?.toString() ?? 'N/A'}',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200], // Grey background
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title:
                    Text('Product Name: ${widget.product['title'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    nameController.text =
                        widget.product['title'] ?? ''; // Set current name
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Edit Name'),
                          content: TextField(
                            controller: nameController,
                            decoration:
                                InputDecoration(hintText: "Enter new name"),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (nameController.text.trim().isNotEmpty) {
                                  setState(() {
                                    key = 'title';
                                    value = nameController.text
                                        .trim(); // Update if not empty
                                  });
                                  await _updateProduct();
                                }
                                Navigator.of(context)
                                    .pop(); // Close modal either way
                              },
                              child: Text('Update'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200], // Grey background
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                    'Product Price: ₦${widget.product['price']?.toString() ?? 'N/A'}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    priceController.text =
                        widget.product['price']?.toString() ??
                            ''; // Pre-fill with current price
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Edit Price'),
                          content: TextField(
                            controller: priceController,
                            decoration:
                                InputDecoration(hintText: "Enter new price"),
                            keyboardType: TextInputType.number,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (priceController.text.trim().isNotEmpty) {
                                  final parsedPrice =
                                      int.tryParse(priceController.text.trim());
                                  if (parsedPrice != null) {
                                    setState(() {
                                      key = 'price';
                                      value = parsedPrice.toString();
                                    });
                                    await _updateProduct();
                                  }
                                }
                                Navigator.of(context).pop();
                              },
                              child: Text('Update'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200], // Grey background
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                    'Product Category: ${widget.product['category'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    selectedCategory = widget
                        .product['category']; // Pre-fill with current category
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Edit Category'),
                          content: widget.availableCategories.isEmpty
                              ? Text("No categories available")
                              : DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: widget.availableCategories
                                      .map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedCategory = newValue;
                                    });
                                  },
                                ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (selectedCategory != null &&
                                    selectedCategory!.trim().isNotEmpty) {
                                  setState(() {
                                    key = 'cid';
                                    widget.product['category'] =
                                        selectedCategory;
                                  });
                                  await _updateProduct();
                                }
                                Navigator.of(context).pop();
                              },
                              child: Text('Update'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: const Text('Product Sales History'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemHistoryPage(
                        itemName: widget.product['title'] ?? "No Title",
                        salesDate: selectedDate,
                      ),
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
}
