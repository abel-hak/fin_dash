import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double amount;
  final String change;
  final bool isPositive;
  final bool isPrimary;
  final Color? color;

  const BalanceCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.change,
    required this.isPositive,
    required this.isPrimary,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF00BCD4) : (color ?? Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: isPrimary ? Colors.white70 : Colors.cyan,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isPrimary ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: isPrimary ? Colors.white60 : Colors.black45,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.black87,
              fontSize: isPrimary ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPrimary 
                    ? Colors.white70 
                    : (isPositive ? Colors.green : Colors.red),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPrimary 
                        ? Colors.white70 
                        : (isPositive ? Colors.green : Colors.red),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
