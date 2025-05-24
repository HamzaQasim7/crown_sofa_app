import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 6)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),

                  // Text(
                  //   order.formattedPrice,
                  //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //     color: AppTheme.primaryColor,
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.textLightColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.customerName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Spacer(),
                  Chip(
                    label: Text(
                      order.designName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              // const SizedBox(height: 4),
              // Row(
              //   children: [
              //     const Icon(
              //       Icons.calendar_today,
              //       size: 16,
              //       color: AppTheme.textLightColor,
              //     ),
              //     const SizedBox(width: 4),
              //     Text(
              //       'Ordered: ${order.formattedOrderDate}',
              //       style: Theme.of(context).textTheme.bodyMedium,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 4),
              // Row(
              //   children: [
              //     const Icon(
              //       Icons.local_shipping_outlined,
              //       size: 16,
              //       color: AppTheme.textLightColor,
              //     ),
              //     const SizedBox(width: 4),
              //     Text(
              //       'Delivery: ${order.formattedDeliveryDate}',
              //       style: Theme.of(context).textTheme.bodyMedium,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 8),
              // Row(
              //   children: [
              //     Expanded(
              //       child: Chip(
              //         label: Text(
              //           order.designName,
              //           style: const TextStyle(fontSize: 12),
              //         ),
              //         backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              //         padding: EdgeInsets.zero,
              //         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     const Icon(Icons.arrow_forward_ios, size: 16),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
