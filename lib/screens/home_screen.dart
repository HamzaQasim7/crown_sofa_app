import 'package:flutter/material.dart';

import '../data/models/order_model.dart';
import '../services/notifications_service.dart';
import '../services/order_services.dart';
import '../widgets/custom_choice_chip.dart';
import '../widgets/order_card.dart';
import '../widgets/search_bar_widget.dart';
import 'notification_screen.dart';
import 'order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  final NotificationService _notificationService = NotificationService();
  String _searchQuery = '';
  String _filterOption = 'last7Days';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update notification service context when dependencies change
    _notificationService.updateContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crown Sofa & Bed"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              hintText: 'Search by name, order ID or phone',
            ),
          ),

          // Filter Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  const Text(
                    'Filter: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CustomChoiceChip(
                    label: 'Last 7 Days',
                    isSelected: _filterOption == 'last7Days',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterOption = 'last7Days';
                        });
                      }
                    },
                  ),
                  CustomChoiceChip(
                    label: 'Previous Month',
                    isSelected: _filterOption == 'prevMonth',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterOption = 'prevMonth';
                        });
                      }
                    },
                  ),
                  CustomChoiceChip(
                    label: 'All Orders',
                    isSelected: _filterOption == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterOption = 'all';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Orders List
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    switch (_filterOption) {
      case 'last7Days':
        return _buildLastSevenDaysOrders();
      case 'prevMonth':
        return _buildPreviousMonthOrders();
      case 'all':
        return _buildAllOrders();
      default:
        return _buildLastSevenDaysOrders();
    }
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.searchOrders(_searchQuery),
      builder: (context, snapshot) {
        return _buildOrderListView(snapshot);
      },
    );
  }

  Widget _buildLastSevenDaysOrders() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getLastSevenDaysOrders(),
      builder: (context, snapshot) {
        return _buildOrderListView(snapshot);
      },
    );
  }

  Widget _buildPreviousMonthOrders() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getPreviousMonthOrders(),
      builder: (context, snapshot) {
        return _buildOrderListView(snapshot);
      },
    );
  }

  Widget _buildAllOrders() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrders(),
      builder: (context, snapshot) {
        return _buildOrderListView(snapshot);
      },
    );
  }

  Widget _buildOrderListView(AsyncSnapshot<List<OrderModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Error: ${snapshot.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final orders = snapshot.data ?? [];

    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders found', style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(orderId: order.id!),
              ),
            );
          },
        );
      },
    );
  }
}
