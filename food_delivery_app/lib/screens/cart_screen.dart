import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/cart_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: SafeArea(
        child: cart.isEmpty
            ? const Center(child: Text('Your cart is empty.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: cart.lines.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final line = cart.lines[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line.item.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text('\$${(line.item.price * line.quantity).toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (line.note.trim().isNotEmpty)
                            Text('Customization: ${line.note}', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => cart.setQuantity(line.item.menuId, line.quantity - 1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(
                                onPressed: () => cart.setQuantity(line.item.menuId, line.quantity + 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const Spacer(),
                              Text('\$${line.item.price.toStringAsFixed(2)} each'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total'),
                          Text(
                            '\$${cart.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: cart.clear,
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final restaurantId = cart.restaurantId;
                        if (restaurantId == null) return;
                        context.push('/checkout/$restaurantId');
                      },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
