import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userId = '';
  String business = '';
  String services = ''; 
  String address = ''; 

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadUserData();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _loadUserData();
    });
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail != null && userEmail.isNotEmpty) {
      // User is logged in, no need to navigate
    } else {
      // User is not logged in, navigate to Login Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Unknown User';
      userEmail = prefs.getString('userEmail') ?? 'Unknown Email';
      userPhone = prefs.getString('userPhone') ?? 'Unknown';
      userId = prefs.getString('userId') ?? 'Unknown ID';
      business = prefs.getString('business') ?? 'Not Provided';
      services = prefs.getString('services') ?? 'Not Provided';
      address = prefs.getString('address') ?? 'Not Provided';
    });
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _updateField(String field, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    
    String? newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter new $field'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(field.toLowerCase(), newValue);
      setState(() {
        switch (field.toLowerCase()) {
          case 'services':
            services = newValue;
            break;
          case 'address':
            address = newValue;
            break;
        }
      });
    }
  }

  Widget _buildGroupedSection(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: tiles.map((tile) {
          return Column(
            children: [
              tile,
              if (tile != tiles.last) const Divider(height: 1.0),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserInfo(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: value.length > 30
          ? Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            )
          : null,
      trailing: title == 'Services' || title == 'Address'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.length <= 30) 
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _updateField(title, value),
                ),
              ],
            )
          : value.length > 30
              ? null
              : Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          children: [
            const SizedBox(height: 20),
            _buildGroupedSection([
              _buildUserInfo('Name', userName, Icons.person),
              _buildUserInfo('Email', userEmail, Icons.email),
              _buildUserInfo('Phone Number', userPhone, Icons.phone),
            ]),
            const SizedBox(height: 20),
            _buildGroupedSection([
              _buildUserInfo('Company Name', business, Icons.business),
              _buildUserInfo('Services', services, Icons.design_services),
              _buildUserInfo('Address', address, Icons.location_on),
            ]),
            const SizedBox(height: 24.0),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    logoutUser(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Center(child: Text('Version 1.0.1 (0167)')),
          ],
        ),
      ),
    );
  }
}
