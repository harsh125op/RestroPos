import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_details_provider.dart';
import '../../../../core/widgets/common_widgets.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  const StoreDetailsScreen({super.key});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstController;
  late TextEditingController _cashierController;

  @override
  void initState() {
    super.initState();
    final details = ref.read(storeDetailsProvider);
    _nameController = TextEditingController(text: details.restaurantName);
    _addressController = TextEditingController(text: details.address);
    _phoneController = TextEditingController(text: details.phone);
    _gstController = TextEditingController(text: details.gstin);
    _cashierController = TextEditingController(text: details.cashierName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _cashierController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newDetails = StoreDetails(
        restaurantName: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        gstin: _gstController.text,
        cashierName: _cashierController.text,
      );
      
      await ref.read(storeDetailsProvider.notifier).updateDetails(newDetails);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details updated successfully!")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurant & Cashier"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "RESTAURANT DETAILS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildField("Restaurant Name", _nameController, Icons.restaurant_rounded),
              const SizedBox(height: 16),
              _buildField("Address", _addressController, Icons.location_on_rounded, maxLines: 2),
              const SizedBox(height: 16),
              _buildField("Phone Number", _phoneController, Icons.phone_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField("GSTIN (Optional)", _gstController, Icons.receipt_rounded),
              
              const SizedBox(height: 32),
              Text(
                "CASHIER DETAILS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildField("Cashier Name", _cashierController, Icons.person_rounded),
              
              const SizedBox(height: 48),
              CustomButton(
                label: "Save Changes",
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    {int maxLines = 1, TextInputType? keyboardType}
  ) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Field cannot be empty" : null,
    );
  }
}
