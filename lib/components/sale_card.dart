import 'package:flutter/material.dart';

import 'package:invenman/models/sale_record.dart';

class SaleCard extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;
  final VoidCallback? onTap;

  const SaleCard({
    super.key,
    required this.sale,
    required this.formattedDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitColor =
        sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 10,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      sale.category,
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sale.itemName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SaleMetricChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Qty',
                    value: '${sale.quantitySold}',
                  ),
                  _SaleMetricChip(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Cost',
                    value: sale.costPrice.toStringAsFixed(0),
                  ),
                  _SaleMetricChip(
                    icon: Icons.sell_outlined,
                    label: 'Sell',
                    value: sale.sellPrice.toStringAsFixed(0),
                  ),
                  _SaleMetricChip(
                    icon: Icons.trending_up_rounded,
                    label: 'Profit',
                    value: sale.profit.toStringAsFixed(0),
                    valueColor: profitColor,
                  ),
                ],
              ),
              if ((sale.customerName ?? '').trim().isNotEmpty ||
                  (sale.customerPhone ?? '').trim().isNotEmpty ||
                  (sale.customerAddress ?? '').trim().isNotEmpty ||
                  sale.warranties.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 10),
              ],
              if ((sale.customerName ?? '').trim().isNotEmpty)
                Text(
                  'Customer: ${sale.customerName}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if ((sale.customerPhone ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Phone: ${sale.customerPhone}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if ((sale.customerAddress ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Address: ${sale.customerAddress}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              if (sale.warranties.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sale.warranties.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value} mo',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SaleMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}