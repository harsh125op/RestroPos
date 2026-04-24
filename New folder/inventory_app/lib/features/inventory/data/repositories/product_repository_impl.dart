import 'package:drift/drift.dart';
import 'package:inventory_app/data/database/app_database.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final AppDatabase _db;

  ProductRepositoryImpl(this._db);

  @override
  Future<List<ProductEntity>> getProducts() async {
    final result = await _db.select(_db.products).get();
    return result.map((p) => ProductEntity(
      id: p.id,
      name: p.name,
      category: p.category,
      quantity: p.quantity,
      price: p.price,
    )).toList();
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    await _db.into(_db.products).insert(ProductsCompanion.insert(
      name: product.name,
      category: product.category,
      quantity: product.quantity,
      price: product.price,
    ));
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    if (product.id == null) return;
    await (_db.update(_db.products)..where((t) => t.id.equals(product.id!)))
        .write(ProductsCompanion(
      name: Value(product.name),
      category: Value(product.category),
      quantity: Value(product.quantity),
      price: Value(product.price),
    ));
  }

  @override
  Future<void> deleteProduct(int id) async {
    await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
  }
}
