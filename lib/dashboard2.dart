import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:salespro/constants.dart';
import 'package:salespro/stock_management.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account.dart';
import 'customers.dart';
import 'dashboard.dart';
import 'package:intl/intl.dart';
import 'order.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int allOrders = 0, completed = 0, pending = 0, cancelled = 0;
  int customers = 0, numberOfProducts = 0, productCategories = 0;
  double totalSales = 0;
  int todaySales = 0, yesterdaySales = 0, thisMonthSales = 0;
  List<String> weekDays = [];
  List<double> weekSales = [];
  List<String> topSalesLabels = [];
  List<double> topSalesSeries = [];
  String userName = '';
  String business = '';
  int editPrice = 0;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadLocalData();
    // Only fetch data if local data is not available
    if (userName.isEmpty) {
      fetchDashboardData();
    } else {
      setState(() {
        isLoading = false; // Set loading to false if local data is loaded
      });
    }
  }

  Future<void> loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName') ?? '';
    business = prefs.getString('business') ?? 'Not Provided';
    editPrice = prefs.getInt('editPrice') ?? 0;
    allOrders = prefs.getInt('allOrders') ?? 0;
    completed = prefs.getInt('completed') ?? 0;
    pending = prefs.getInt('pending') ?? 0;
    cancelled = prefs.getInt('cancelled') ?? 0;
    customers = prefs.getInt('customers') ?? 0;
    numberOfProducts = prefs.getInt('numberOfProducts') ?? 0;
    productCategories = prefs.getInt('productCategories') ?? 0;
    totalSales = prefs.getDouble('totalSales') ?? 0.0;
    todaySales = prefs.getInt('todaySales') ?? 0;
    yesterdaySales = prefs.getInt('yesterdaySales') ?? 0; // Fix typo here
    thisMonthSales = prefs.getInt('thisMonthSales') ?? 0;
    weekDays = prefs.getStringList('weekDays') ?? [];
    topSalesLabels = prefs.getStringList('topSalesLabels') ?? [];
    weekSales = (prefs.getStringList('weekSales')?.map(double.parse).toList() ?? []);
    topSalesSeries = (prefs.getStringList('topSalesSeries')?.map(double.parse).toList() ?? []);
    
    // Set loading to false after loading local data
    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setInt('editPrice', editPrice);
    await prefs.setInt('allOrders', allOrders);
    await prefs.setInt('completed', completed);
    await prefs.setInt('pending', pending);
    await prefs.setInt('cancelled', cancelled);
    await prefs.setInt('customers', customers);
    await prefs.setInt('numberOfProducts', numberOfProducts);
    await prefs.setInt('productCategories', productCategories);
    await prefs.setDouble('totalSales', totalSales);
    await prefs.setInt('todaySales', todaySales);
    await prefs.setInt('yesterdaySales', yesterdaySales);
    await prefs.setInt('thisMonthSales', thisMonthSales);
    await prefs.setStringList('weekDays', weekDays);
    await prefs.setStringList('topSalesLabels', topSalesLabels);
    await prefs.setStringList('weekSales', weekSales.map((e) => e.toString()).toList());
    await prefs.setStringList('topSalesSeries', topSalesSeries.map((e) => e.toString()).toList());
  }

  @override
  void dispose() {
    saveLocalData(); // Save data when the page is disposed
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    const String url = 'https://salespro.livepetal.com/v1/getstatistics';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'];

        setState(() {
          allOrders = data['orders']?['all'] ?? 0;
          completed = data['orders']?['completed'] ?? 0;
          pending = data['orders']?['pending'] ?? 0;
          cancelled = data['orders']?['cancelled'] ?? 0;
          customers = data['orders']?['customers'] ?? 0;

          numberOfProducts = data['product'] ?? 0;
          productCategories = data['category'] ?? 0;

          totalSales = (data['sales']?['total'] ?? 0).toDouble();
          todaySales = data['sales']?['today'] ?? 0;
          yesterdaySales = data['sales']?['yesterday'] ?? 0; // Fix typo here
          thisMonthSales = data['sales']?['thismonth'] ?? 0;

          weekDays =
              (data['weekdates'] as List?)?.map((e) => e.toString()).toList() ??
                  [];
          weekSales = (data['weeksales'] as List?)
                  ?.map((e) => (e as num?)?.toDouble() ?? 0)
                  .toList() ??
              [];

          topSalesLabels = (data['topsales']?['label'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          topSalesSeries = (data['topsales']?['series'] as List?)
                  ?.map((e) => (e as num?)?.toDouble() ?? 0)
                  .toList() ??
              [];

          isLoading = false;
        });
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load dashboard data. Please try again.';
      });
    }
  }


  Widget _buildQuickLink(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: primaryColor.withOpacity(0.9),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          business,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Matches body padding
            child: IconButton(
              icon: const Icon(Icons.account_circle, size: 40), // Bigger icon
              tooltip: 'Account',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountPage()),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child:
                          Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(),
                          const SizedBox(height: 20),
                          const Text('Quick Links',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickLink(
                                  icon: Icons.shopping_bag,
                                  label: 'Orders',
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => OrderPage()));
                                  }),
                              _buildQuickLink(
                                  icon: Icons.people,
                                  label: 'Customers',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerPage(),
                                      ),
                                    );
                                  }),
                              _buildQuickLink(
                                icon: Icons.settings,
                                label: 'Manage Stock',
                                onTap: () {
                                  if (editPrice == 0) {
                                    // show a message to the user
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'You do not have permission to access stock.')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const StockManagementPage()),
                                  );
                                },
                              ),
                              _buildQuickLink(
                                  icon: Icons.inventory_2,
                                  label: 'Products',
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const DashboardScreen()));
                                  }),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Weekly Report',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          SizedBox(height: 200, child: _buildBarChart()),
                          const SizedBox(height: 40),
                          const Text('Products',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildSummaryCard(
                                      'Products', '$numberOfProducts')),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _buildSummaryCard(
                                      'Categories', '$productCategories')),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Orders',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildSummaryCard('All', '$allOrders'),
                                const SizedBox(width: 16),
                                _buildSummaryCard('Completed', '$completed'),
                                const SizedBox(width: 16),
                                _buildSummaryCard('Pending', '$pending'),
                                const SizedBox(width: 16),
                                _buildSummaryCard('Cancelled', '$cancelled'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Top Selling Items',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(height: 250, child: _buildPieChart()),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hello',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(userName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL SALES', style: TextStyle(fontSize: 14)),
                      Text(
                        '₦${NumberFormat('#,##0').format(totalSales)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            NumberFormat('#,##0').format(todaySales),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Text('Today', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(NumberFormat('#,##0').format(yesterdaySales),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text('Yesterday',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(NumberFormat('#,##0').format(thisMonthSales),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text('This Month',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade400),
      ),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (weekSales.isEmpty || weekDays.isEmpty) {
      return const Center(child: Text("No sales data"));
    }
    final maxY = weekSales.reduce((a, b) => a > b ? a : b) + 1000;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: List.generate(weekSales.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weekSales[index],
                color: const Color.fromARGB(255, 61, 82, 61),
                width: 10,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 5,
              getTitlesWidget: (value, _) {
                final formatted =
                    NumberFormat.decimalPattern().format(value.toInt());
                return Text('₦$formatted', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= weekDays.length) return const Text('');
                return RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    weekDays[index],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart() {
    if (topSalesLabels.isEmpty || topSalesSeries.isEmpty) {
      return const Center(child: Text("No top sales data"));
    }

    final colors = List.generate(
      topSalesLabels.length,
      (index) => Colors.primaries[index % Colors.primaries.length],
    );

    final sections = List.generate(topSalesLabels.length, (index) {
      return PieChartSectionData(
        value: topSalesSeries[index],
        // Pie chart label: displays the index + 1 (e.g., "1", "2", "3")
        title: (index + 1).toString(),
        color: colors[index],
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    });

    // Legend widget with wrapped text
    Widget legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Use min to prevent excessive height
      children: List.generate(topSalesLabels.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[index],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  // Legend: includes the index and item name only
                  '${index + 1}. ${topSalesLabels[index]}',
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        );
      }),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200, // Fixed width for the pie chart itself
          height: 200, // Fixed height for the pie chart itself
          child: PieChart(PieChartData(sections: sections)),
        ),
        const SizedBox(width: 16),
        Expanded( // Use Expanded to allow the legend to take remaining space
          child: legend,
        ),
      ],
    );
  }
}