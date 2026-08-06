import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final ProductEntity product;

  const AddToCart(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateQty extends CartEvent {
  final String productId;
  final double qty;

  const UpdateQty(this.productId, this.qty);

  @override
  List<Object?> get props => [productId, qty];
}

class UpdateDiscount extends CartEvent {
  final String productId;
  final double discountAmount;

  const UpdateDiscount(this.productId, this.discountAmount);

  @override
  List<Object?> get props => [productId, discountAmount];
}

class ClearCart extends CartEvent {}
