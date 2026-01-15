import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_service.dart';
import '../models/order.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';

class CheckoutScreen extends StatefulWidget {
  final int restaurantId;

  const CheckoutScreen({super.key, required this.restaurantId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();

  String _paymentMethod = 'card';
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final address = context.read<AuthState>().user?.address;
    if (_addressCtrl.text.isEmpty && address != null && address.isNotEmpty) {
      _addressCtrl.text = address;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      if (!(_formKey.currentState?.validate() ?? false)) {
        setState(() => _loading = false);
        return;
      }

      final auth = context.read<AuthState>();
      final cart = context.read<CartState>();
      final api = context.read<ApiService>();

      final token = auth.token;
      if (token == null) throw Exception('Not authenticated');
      if (cart.isEmpty) throw Exception('Cart is empty');

      final Order order = await api.createOrder(
        token: token,
        restaurantId: widget.restaurantId,
        cartLines: cart.lines,
        paymentMethod: _paymentMethod,
        address: _addressCtrl.text.trim(),
      );

      // Simulate successful payment in demo.
      await api.payOrder(token: token, orderId: order.orderId);

      cart.clear();
      if (!mounted) return;

      context.go('/tracking/${order.orderId}');
    } catch (e) {
      setState(() => _error = 'Failed to place order: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order total: \$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Estimated delivery time: ~35 minutes'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().length < 5) return 'Enter a valid address.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'PayPal', child: Text('PayPal')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  ],
                  onChanged: _loading ? null : (v) => setState(() => _paymentMethod = v ?? 'card'),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _placeOrder,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Place order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
