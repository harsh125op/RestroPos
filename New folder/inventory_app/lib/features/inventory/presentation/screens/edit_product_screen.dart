import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_providers.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/widgets/common_widgets.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final ProductEntity product;
  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late String _selectedCategory;

  final List<String> _categories = ['Sweets', 'Chaat', 'Juice', 'Coffee'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedProduct = widget.product.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
        );

        await ref.read(productListProvider.notifier).updateProduct(updatedProduct);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Menu item updated successfully!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Menu Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Item Name", prefixIcon: Icon(Icons.restaurant)),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "Category", prefixIcon: Icon(Icons.category)),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Price", prefixIcon: Icon(Icons.currency_rupee)),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        final price = double.tryParse(val);
                        if (price == null) return "Invalid number";
                        if (price <= 0) return "Must be > 0";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: "Stock Qty", prefixIcon: Icon(Icons.storage)),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        final qty = int.tryParse(val);
                        if (qty == null) return "Invalid number";
                        if (qty < 0) return "Must be >= 0";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: "Update Item",
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
