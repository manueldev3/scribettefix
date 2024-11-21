import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribettefix/feature/products/domain/products_repository.dart';

part 'products_state.g.dart';

@riverpod
class ProductsState extends _$ProductsState {
  final repository = ProductsRepository();

  @override
  FutureOr<List<ProductDetails>> build() {
    return repository.fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.fetch);
  }
}
