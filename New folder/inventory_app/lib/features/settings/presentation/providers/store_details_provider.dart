import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreDetails {
  final String restaurantName;
  final String address;
  final String phone;
  final String gstin;
  final String cashierName;

  StoreDetails({
    this.restaurantName = 'QuickPOS Restaurant',
    this.address = '123 Foodie Street, City',
    this.phone = '+91 9876543210',
    this.gstin = 'NOTSET',
    this.cashierName = 'Admin',
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'address': address,
      'phone': phone,
      'gstin': gstin,
      'cashierName': cashierName,
    };
  }

  factory StoreDetails.fromMap(Map<String, dynamic> map) {
    return StoreDetails(
      restaurantName: map['restaurantName'] ?? 'QuickPOS Restaurant',
      address: map['address'] ?? '123 Foodie Street, City',
      phone: map['phone'] ?? '+91 9876543210',
      gstin: map['gstin'] ?? 'NOTSET',
      cashierName: map['cashierName'] ?? 'Admin',
    );
  }

  StoreDetails copyWith({
    String? restaurantName,
    String? address,
    String? phone,
    String? gstin,
    String? cashierName,
  }) {
    return StoreDetails(
      restaurantName: restaurantName ?? this.restaurantName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      cashierName: cashierName ?? this.cashierName,
    );
  }
}

final storeDetailsProvider = StateNotifierProvider<StoreDetailsNotifier, StoreDetails>((ref) {
  return StoreDetailsNotifier();
});

class StoreDetailsNotifier extends StateNotifier<StoreDetails> {
  StoreDetailsNotifier() : super(StoreDetails()) {
    _loadDetails();
  }

  static const _key = 'store_details';

  Future<void> _loadDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      state = StoreDetails.fromMap(jsonDecode(data));
    }
  }

  Future<void> updateDetails(StoreDetails details) async {
    state = details;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(details.toMap()));
  }
}
