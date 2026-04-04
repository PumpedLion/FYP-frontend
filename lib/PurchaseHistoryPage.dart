import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/payment_service.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  List<dynamic> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final purchases = await PaymentService.getPurchaseHistory();
    if (mounted) {
      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    final date = DateTime.parse(dateStr).toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase History',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'All your past manuscript purchases',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_purchases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              Text(
                'No purchases yet',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your purchased manuscripts will appear here.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8B7D), Color(0xFFFF6B5B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8B7D).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                  Icons.shopping_bag_outlined,
                  '${_purchases.length}',
                  'Total Purchases'),
              _divider(),
              _summaryItem(
                  Icons.monetization_on_outlined,
                  'NPR ${_purchases.fold(0.0, (sum, p) => sum + (p['amount'] ?? 0)).toStringAsFixed(0)}',
                  'Total Spent'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('Manuscript',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          fontSize: 13))),
              Expanded(
                  flex: 1,
                  child: Text('Amount',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text('Gateway',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          fontSize: 13))),
              const SizedBox(width: 130),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Purchase rows
        ...List.generate(_purchases.length, (i) {
          final p = _purchases[i];
          return _purchaseRow(p, i);
        }),
      ],
    );
  }

  Widget _purchaseRow(dynamic purchase, int index) {
    final manuscript = purchase['manuscript'];
    final title = manuscript?['title'] ?? 'Untitled';
    final coverUrl = manuscript?['coverUrl'];
    final amount = (purchase['amount'] ?? 0).toDouble();
    final gateway = (purchase['gateway'] ?? '').toString();
    final date = _formatDate(purchase['createdAt']);
    final manuscriptId = purchase['manuscriptId'];

    Color gatewayColor;
    IconData gatewayIcon;
    if (gateway == 'KHALTI') {
      gatewayColor = const Color(0xFF5C2D91);
      gatewayIcon = Icons.account_balance_wallet_outlined;
    } else {
      gatewayColor = Colors.green.shade600;
      gatewayIcon = Icons.mobile_friendly_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover thumbnail
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    coverUrl ??
                        'https://picsum.photos/seed/${title.hashCode}/100/140',
                    width: 44,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 60,
                      color: const Color(0xFFFF8B7D).withOpacity(0.1),
                      child: const Icon(Icons.book,
                          color: Color(0xFFFF8B7D), size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1D2939),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              date,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          // Amount
          Expanded(
            flex: 1,
            child: Text(
              'NPR ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1D2939),
              ),
            ),
          ),

          // Gateway badge
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: gatewayColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gatewayColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(gatewayIcon, size: 13, color: gatewayColor),
                  const SizedBox(width: 5),
                  Text(
                    gateway,
                    style: TextStyle(
                        color: gatewayColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Invoice download button
          SizedBox(
            width: 130,
            child: ElevatedButton.icon(
              onPressed: () async {
                await PaymentService.downloadInvoice(manuscriptId);
              },
              icon: const Icon(Icons.download_rounded, size: 14),
              label: const Text('Invoice', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8B7D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white30,
    );
  }
}
