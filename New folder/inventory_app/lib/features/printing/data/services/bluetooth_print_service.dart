import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/logger.dart';

class BluetoothPrintService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// Gets list of paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      AppLogger.e("Failed to get paired devices", e);
      return [];
    }
  }

  /// Connects to a device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      return true;
    } catch (e) {
      AppLogger.e("Failed to connect to device", e);
      return false;
    }
  }

  /// Disconnects from device
  Future<void> disconnect() async {
    await _bluetooth.disconnect();
  }

  /// Checks if connected
  Future<bool?> isConnected() async {
    return await _bluetooth.isConnected;
  }

  /// Prints receipt with logo and text
  Future<bool> printReceipt(String text, [String? logoPath]) async {
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected != true) {
        AppLogger.e("Printer not connected");
        return false;
      }

      if (logoPath != null) {
        try {
          // Load asset
          final ByteData bytes = await rootBundle.load(logoPath);
          final Uint8List imageBytes = bytes.buffer.asUint8List(
            bytes.offsetInBytes, 
            bytes.lengthInBytes
          );
          
          // Save to temp file
          final directory = await getTemporaryDirectory();
          final path = "${directory.path}/billlogo.png";
          final file = File(path);
          await file.writeAsBytes(imageBytes);
          
          // Print image from file
          await _bluetooth.printImage(path);
          await _bluetooth.printNewLine();
        } catch (e) {
          AppLogger.e("Failed to print logo image", e);
          // Don't fail the whole print if logo fails
        }
      }

      // Print text line by line
      final lines = text.split('\n');
      for (final line in lines) {
        if (line.isEmpty) {
          await _bluetooth.printNewLine();
        } else {
          await _bluetooth.printCustom(line, 0, 0);
        }
      }
      
      // Feed paper
      await _bluetooth.printNewLine();
      await _bluetooth.printNewLine();

      return true;
    } catch (e) {
      AppLogger.e("Failed to print receipt", e);
      return false;
    }
  }
}
