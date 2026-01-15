import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_service.dart';
import '../models/tracking.dart';
import '../state/auth_state.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _timer;
  Tracking? _tracking;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthState>().token;
      if (token == null) throw Exception('Not authenticated');

      final tracking = await context.read<ApiService>().getTracking(token: token, orderId: widget.orderId);
      if (!mounted) return;
      setState(() => _tracking = tracking);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markDelivered() async {
    final token = context.read<AuthState>().token;
    if (token == null) return;

    await context.read<ApiService>().markDelivered(token: token, orderId: widget.orderId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tracking;
    final delivered = (t?.orderStatus == 'delivered') || (t?.deliveryStatus == 'delivered');

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking #${widget.orderId}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (t == null && _error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (t != null)
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('Order: ${t.orderStatus}'),
                              Text('Delivery: ${t.deliveryStatus}'),
                              const SizedBox(height: 10),
                              Text('ETA: ${t.etaMinutes} minutes'),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Driver', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(t.driverName),
                              Text('Vehicle: ${t.vehicleType}'),
                              Text('Phone: ${t.driverPhone}'),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location (demo)', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('Lat: ${t.lat.toStringAsFixed(5)}'),
                              Text('Lng: ${t.lng.toStringAsFixed(5)}'),
                              const SizedBox(height: 8),
                              Text(
                                'This is a lightweight “near real-time” tracking via polling every 5 seconds.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _markDelivered,
                      child: const Text('Mark delivered (demo)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: delivered ? () => context.go('/feedback/${widget.orderId}') : null,
                      child: const Text('Leave feedback'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
