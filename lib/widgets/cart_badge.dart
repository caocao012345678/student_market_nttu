import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../screens/cart_screen.dart';

class CartBadge extends StatelessWidget {
  final Color? color;
  final double size;

  const CartBadge({
    Key? key,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final cartService = Provider.of<CartService>(context);
    final userId = authService.currentUser?.uid ?? '';
    
    // Tải giỏ hàng nếu chưa tải
    if (userId.isNotEmpty && cartService.cartItems.isEmpty && !cartService.isLoading) {
      Future.microtask(() => cartService.fetchCartItems(userId));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: color ?? theme.colorScheme.onPrimary,
            size: size,
          ),
          onPressed: () {
            print("Nút giỏ hàng được nhấn");
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            );
          },
        ),
        if (cartService.itemCount > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                cartService.itemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
} 