import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_service.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/tracking_screen.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState(api: api)..init()),
        ChangeNotifierProvider(create: (_) => CartState()),
        Provider.value(value: api),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthState>();

          final router = GoRouter(
            refreshListenable: auth,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/restaurants',
                builder: (context, state) => const RestaurantsScreen(),
              ),
              GoRoute(
                path: '/restaurants/:id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Invalid restaurant')));
                  return MenuScreen(restaurantId: id);
                },
              ),
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
              GoRoute(
                path: '/checkout/:restaurantId',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['restaurantId'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Invalid checkout')));
                  return CheckoutScreen(restaurantId: id);
                },
              ),
              GoRoute(
                path: '/tracking/:orderId',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['orderId'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Invalid order')));
                  return TrackingScreen(orderId: id);
                },
              ),
              GoRoute(
                path: '/feedback/:orderId',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['orderId'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Invalid order')));
                  return FeedbackScreen(orderId: id);
                },
              ),
            ],
            redirect: (context, state) {
              final loggedIn = auth.isLoggedIn;
              final goingToLogin = state.matchedLocation == '/';

              if (!loggedIn && !goingToLogin) return '/';
              if (loggedIn && goingToLogin) return '/restaurants';
              return null;
            },
          );

          return MaterialApp.router(
            title: 'Food Delivery',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E7A4C)),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
