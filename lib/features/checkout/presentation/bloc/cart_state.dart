import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartState extends Equatable {
  final List<CartItemEntity> items;

  const CartState({this.items = const []});

  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.qty));
  
  double get discountTotal => items.fold(0.0, (sum, item) => sum + (item.discountAmount * item.qty));
  
  double get taxTotal => 0.0; // MorrusPOS default tax
  
  double get grandTotal => subtotal - discountTotal + taxTotal;

  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.qty.toInt());

  @override
  List<Object?> get props => [items];
}
