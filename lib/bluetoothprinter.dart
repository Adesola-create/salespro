// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:flutter/material.dart';

// class BluetoothPrinterScreen extends StatefulWidget {
//   @override
//   _BluetoothPrinterScreenState createState() => _BluetoothPrinterScreenState();
// }

// class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
//   BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
//   List<BluetoothDevice> _devices = [];
//   BluetoothDevice? _selectedDevice;
//   bool _connected = false;

//   @override
//   void initState() {
//     super.initState();
//     _getBluetoothDevices();
//   }

//   /// Get available Bluetooth devices
//   void _getBluetoothDevices() async {
//     try {
//       List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
//       setState(() {
//         _devices = devices;
//       });
//     } catch (e) {
//       print("Error getting Bluetooth devices: $e");
//     }
//   }

//   /// Connect to selected Bluetooth printer
//   void _connect() async {
//     if (_selectedDevice == null) return;
//     try {
//       bool? isConnected = await bluetooth.connect(_selectedDevice!);
//       if (isConnected == true) {
//         setState(() {
//           _connected = true;
//         });
//       }
//     } catch (e) {
//       print("Connection error: $e");
//     }
//   }

//   /// Disconnect Bluetooth printer
//   void _disconnect() async {
//     await bluetooth.disconnect();
//     setState(() {
//       _connected = false;
//     });
//   }

//   /// Print sample text
//   void _print() {
//     if (!_connected) return;
//     bluetooth.printNewLine();
//     bluetooth.printCustom("Hello from Flutter!", 2, 1);
//     bluetooth.printNewLine();
//     bluetooth.printQRcode("https://example.com", 200, 200, 1);
//     bluetooth.printNewLine();
//     bluetooth.printNewLine();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Bluetooth Printer")),
//       body: Column(
//         children: [
//           DropdownButton<BluetoothDevice>(
//             hint: Text("Select Printer"),
//             value: _selectedDevice,
//             onChanged: (device) {
//               setState(() {
//                 _selectedDevice = device;
//               });
//             },
//             items: _devices.map((device) {
//               return DropdownMenuItem(
//                 value: device,
//                 child: Text(device.name ?? "Unknown"),
//               );
//             }).toList(),
//           ),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: _connect,
//             child: Text(_connected ? "Connected" : "Connect"),
//           ),
//           ElevatedButton(
//             onPressed: _disconnect,
//             child: Text("Disconnect"),
//           ),
//           ElevatedButton(
//             onPressed: _print,
//             child: Text("Print Sample"),
//           ),
//         ],
//       ),
//     );
//   }
// }
