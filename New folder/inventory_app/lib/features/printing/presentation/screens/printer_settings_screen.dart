import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../providers/printing_providers.dart';
import '../../data/services/receipt_formatter.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkConnection();
  }

  Future<void> _loadDevices() async {
    setState(() { _isLoading = true; });
    final service = ref.read(bluetoothPrintServiceProvider);
    final devices = await service.getPairedDevices();
    setState(() {
      _devices = devices;
      _isLoading = false;
    });
  }

  Future<void> _checkConnection() async {
    final service = ref.read(bluetoothPrintServiceProvider);
    final connected = await service.isConnected();
    setState(() {
      _isConnected = connected;
    });
    ref.read(printerConnectedProvider.notifier).state = connected;
  }

  Future<void> _connect() async {
    if (_selectedDevice == null) return;
    setState(() { _isLoading = true; });
    final service = ref.read(bluetoothPrintServiceProvider);
    final success = await service.connect(_selectedDevice!.macAdress);
    setState(() {
      _isConnected = success;
      _isLoading = false;
    });
    ref.read(printerConnectedProvider.notifier).state = success;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connected successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect."), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _disconnect() async {
    final service = ref.read(bluetoothPrintServiceProvider);
    await service.disconnect();
    setState(() {
      _isConnected = false;
    });
    ref.read(printerConnectedProvider.notifier).state = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Disconnected.")),
    );
  }

  Future<void> _printTestReceipt() async {
    final service = ref.read(bluetoothPrintServiceProvider);
    final formatter = ref.read(receiptFormatterProvider);

    final receiptText = formatter.generateReceipt(
      restaurantName: "QuickPos Restaurant",
      phoneNumber: "+91 9876543210",
      address: "123 Foodie Street, City",
      invoiceNumber: "INV-TEST-001",
      dateTime: DateTime.now(),
      cashierName: "Test Cashier",
      items: [
        ReceiptItem(name: "Gulab Jamun", quantity: 1, price: 20, total: 20),
        ReceiptItem(name: "Orange Juice", quantity: 1, price: 50, total: 50),
      ],
      grandTotal: 70,
    );

    final success = await service.printReceipt(receiptText, 'assets/billlogo.png');
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to print. Is printer connected?"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.print, color: _isConnected ? Colors.green : Colors.grey, size: 28),
                        const SizedBox(width: 12),
                        const Text("Printer Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isConnected ? "Connected" : "Disconnected",
                      style: TextStyle(fontSize: 16, color: _isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("Paired Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              const Text("No paired devices found. Please pair your printer in your phone's Bluetooth settings first.", style: TextStyle(color: Colors.grey))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device.name ?? "Unknown Device"),
                      subtitle: Text(device.macAdress ?? ""),
                      trailing: _selectedDevice == device
                          ? const Icon(Icons.check_circle, color: Colors.teal)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            
            if (_selectedDevice != null && !_isConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.bluetooth_connected),
                  label: const Text("Connect"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                ),
              ),
            
            if (_isConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text("Disconnect"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isConnected ? _printTestReceipt : null,
                icon: const Icon(Icons.print),
                label: const Text("Print Test Receipt"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
