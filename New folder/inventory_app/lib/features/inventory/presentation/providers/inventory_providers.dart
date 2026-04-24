import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/database/app_database.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/repositories/product_repository_impl.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(databaseProvider));
});

final productListProvider = AsyncNotifierProvider<ProductListNotifier, List<ProductEntity>>(() {
  return ProductListNotifier();
});

class ProductListNotifier extends AsyncNotifier<List<ProductEntity>> {
  @override
  Future<List<ProductEntity>> build() async {
    return ref.read(productRepositoryProvider).getProducts();
  }

  Future<void> addProduct(ProductEntity product) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).addProduct(product);
      return ref.read(productRepositoryProvider).getProducts();
    });
  }

  Future<void> deleteProduct(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).deleteProduct(id);
      return ref.read(productRepositoryProvider).getProducts();
    });
  }

  Future<void> updateProduct(ProductEntity product) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).updateProduct(product);
      return ref.read(productRepositoryProvider).getProducts();
    });
  }
}
