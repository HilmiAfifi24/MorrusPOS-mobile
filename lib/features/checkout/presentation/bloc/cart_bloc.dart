import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item_entity.dart';
import 'cart_event.dart';
import 'cart_state.dart';

export 'cart_event.dart';
export 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQty>(_onUpdateQty);
    on<UpdateDiscount>(_onUpdateDiscount);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final existingIndex = state.items.indexWhere((item) => item.productId == event.product.id);
    final List<CartItemEntity> updatedItems = List.from(state.items);

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      // Prevent exceeding stock
      final double newQty = existingItem.qty + 1;
      if (newQty <= existingItem.availableStock) {
        updatedItems[existingIndex] = existingItem.copyWith(qty: newQty);
      }
    } else {
      if (event.product.qtyOnHand > 0) {
        updatedItems.add(CartItemEntity(
          productId: event.product.id,
          productName: event.product.name,
          sku: event.product.sku,
          unitPrice: event.product.basePrice,
          qty: 1,
          discountAmount: 0.0,
          availableStock: event.product.qtyOnHand,
        ));
      }
    }

    emit(CartState(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items.where((item) => item.productId != event.productId).toList();
    emit(CartState(items: updatedItems));
  }

  void _onUpdateQty(UpdateQty event, Emitter<CartState> emit) {
    final index = state.items.indexWhere((item) => item.productId == event.productId);
    if (index >= 0) {
      final List<CartItemEntity> updatedItems = List.from(state.items);
      if (event.qty <= 0) {
        updatedItems.removeAt(index);
      } else {
        final item = state.items[index];
        // Clamp qty to available stock
        final double finalQty = event.qty > item.availableStock ? item.availableStock : event.qty;
        updatedItems[index] = item.copyWith(qty: finalQty);
      }
      emit(CartState(items: updatedItems));
    }
  }

  void _onUpdateDiscount(UpdateDiscount event, Emitter<CartState> emit) {
    final index = state.items.indexWhere((item) => item.productId == event.productId);
    if (index >= 0) {
      final List<CartItemEntity> updatedItems = List.from(state.items);
      final item = state.items[index];
      // Prevent discount from exceeding unit price
      final double finalDiscount = event.discountAmount > item.unitPrice ? item.unitPrice : event.discountAmount;
      updatedItems[index] = item.copyWith(discountAmount: finalDiscount);
      emit(CartState(items: updatedItems));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
  }
}
