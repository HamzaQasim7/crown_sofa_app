import 'package:flutter/material.dart';
import 'package:form_order_app/screens/pdf_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../data/models/order_model.dart';
import '../services/order_services.dart';
import '../services/pdf_service.dart';
import '../widgets/order_image_galary.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  final PdfService _pdfService = PdfService();
  bool _isLoading = true;
  OrderModel? _order;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (_order == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final pdfFile = await _pdfService.generateOrderPdf(_order!);

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject:
            'Order Receipt for ${_order!.customerName} (#${_order!.id.substring(0, 6)})',
        // subject: 'Order #${_order!.id.substring(0, 6)} Receipt',
        text: 'Order receipt for ${_order!.customerName}',
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate PDF: $e';
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  void _navigateToPdfPreview() {
    if (_order == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfPreviewScreen(order: _order!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.navigate_before, color: Colors.white),
        ),
        title: Text(
          _order != null
              ? 'Order #${_order!.id.substring(0, 6)}'
              : 'Order Details',
        ),
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () => _navigateToPdfPreview(),
              tooltip: 'View Receipt',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOrder, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Order not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(),
          const SizedBox(height: 24),
          _buildCustomerInfo(),
          const SizedBox(height: 24),
          _buildOrderDetails(),
          const SizedBox(height: 24),
          _buildProductInfo(),
          const SizedBox(height: 32),
          if (_order?.imageUrls != null && _order!.imageUrls.isNotEmpty) ...[
            _buildOrderImages(),
            const SizedBox(height: 24),
          ],
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${_order!.id.substring(0, 6)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Ordered on: ${_order!.formattedOrderDate}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Delivery date: ${_order!.formattedDeliveryDate}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _order!.formattedPrice,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Name', _order!.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_outlined, 'Phone', _order!.phoneNumber),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Address',
              _order!.customerAddress,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.markunread_mailbox_outlined,
              'Postcode',
              _order!.postcode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.design_services_outlined,
              'Design',
              _order!.designName,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.palette_outlined,
              'Color & Fabric',
              _order!.colorFabric,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.category_outlined,
              'Combination',
              _order!.combinationText,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline, 'Seller', _order!.sellerName),
            if (_order!.orderDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Additional Notes:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_order!.orderDetails),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chair_outlined,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              title: Text(_order!.designName),
              subtitle: Text(
                '${_order!.colorFabric} • ${_order!.combinationText}',
              ),
              trailing: Text(
                _order!.formattedPrice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToPdfPreview,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate Receipt'),
        style: ElevatedButton.styleFrom(
          maximumSize: Size(double.infinity, 53),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildOrderImages() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Images',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 12),
            OrderImageGallery(imageUrls: _order?.imageUrls ?? [], height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textLightColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppTheme.textLightColor, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
