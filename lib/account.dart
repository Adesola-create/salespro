import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
//import 'chat.dart';

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
  String business = ''; // Company Name
  String services = ''; // Services Offered
  String address = ''; // Business Address

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
      subtitle: value.length > 30 // If long, move it to subtitle
          ? Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Limits to 2 lines
            )
          : null,
      trailing: value.length > 30
          ? null // Removes trailing if text is long
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
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.remove('userEmail');
                    });
                    _checkLoginStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: const Text('Log Out',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

// const SizedBox(height: 16.0),
//             Center(
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) =>  ChatScreen()),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 14.0),
//                   ),
//                   child: const Text('Go to Chat',
//                       style:
//                           TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 ),
//               ),
//             ),

            const SizedBox(height: 16.0),
            const Center(child: Text('Version 1.0.1 (0167)')),
          ],
        ),
      ),
    );
  }
}
