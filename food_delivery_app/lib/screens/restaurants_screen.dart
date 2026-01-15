import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_service.dart';
import '../models/restaurant.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  late Future<List<Restaurant>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().getRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: cart.isEmpty ? null : () => context.push('/cart'),
            icon: Badge(
              isLabelVisible: !cart.isEmpty,
              label: Text('${cart.lines.length}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthState>().logout();
              if (!context.mounted) return;
              context.go('/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Restaurant>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Failed to load restaurants.'),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() => _future = context.read<ApiService>().getRestaurants()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final restaurants = snapshot.data ?? const [];
            if (restaurants.isEmpty) {
              return const Center(child: Text('No restaurants yet. Seed the database.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: restaurants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = restaurants[i];
                return InkWell(
                  onTap: () => context.push('/restaurants/${r.restaurantId}'),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            child: Icon(Icons.storefront, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text('${r.cuisineType} • Rating ${r.rating.toStringAsFixed(1)}'),
                                const SizedBox(height: 6),
                                Text(
                                  r.address,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
