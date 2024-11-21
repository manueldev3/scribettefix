import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';

class ProductsRepository extends FirebaseRepository {
  final inAppPurchase = InAppPurchase.instance;

  Future<List<ProductDetails>> fetch() async {
    List<String> productIds = ['monthly'];

    ProductDetailsResponse response = await inAppPurchase.queryProductDetails(
      productIds.toSet(),
    );

    if (response.error != null) {
      debugPrint(
        "Error al recuperar los detalles del producto: ${response.error}",
      );
      return [];
    }

    if (response.productDetails.isEmpty) {
      debugPrint("No se encontraron productos disponibles.");
      return [];
    }

    return response.productDetails;
  }
}
