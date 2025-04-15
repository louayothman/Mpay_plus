import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpay_app/screens/wallet/deposit_screen.dart';
import 'package:mpay_app/screens/wallet/withdraw_screen.dart';
import 'package:mpay_app/screens/wallet/transactions_screen.dart';
import 'package:mpay_app/utils/cache_manager.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CacheManager _cacheManager = CacheManager();
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  List<String> _supportedCurrencies = [
    'USDT',
    'BTC',
    'ETH',
    'ShamCash',
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Try to get wallet data from cache first
      final walletData = await _cacheManager.getWalletData(forceRefresh: false);
      
      if (mounted) {
        setState(() {
          _walletData = walletData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في تحميل بيانات المحفظة: $e'
        );
      }
    }
  }

  double _getBalance(String currency) {
    if (_walletData == null || !_walletData!.containsKey('balances')) {
      return 0.0;
    }
    
    final balances = _walletData!['balances'] as Map<String, dynamic>?;
    if (balances == null) {
      return 0.0;
    }
    
    return balances[currency] as double? ?? 0.0;
  }

  void _navigateToDeposit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DepositScreen(),
      ),
    ).then((_) => _loadWalletData());
  }

  void _navigateToWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WithdrawScreen(),
      ),
    ).then((_) => _loadWalletData());
  }

  void _navigateToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionsScreen(),
      ),
    ).then((_) => _loadWalletData());
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحفظة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWalletData,
              tooltip: 'تحديث',
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: _navigateToTransactions,
              tooltip: 'المعاملات',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWalletData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance cards
                      ..._supportedCurrencies.map((currency) => _buildBalanceCard(currency)),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.arrow_downward,
                              label: 'إيداع',
                              color: Colors.green,
                              onPressed: _navigateToDeposit,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.arrow_upward,
                              label: 'سحب',
                              color: Colors.red,
                              onPressed: _navigateToWithdraw,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Recent transactions
                      const Text(
                        'آخر المعاملات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentTransactions(),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _navigateToTransactions,
                          child: const Text('عرض جميع المعاملات'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard(String currency) {
    final balance = _getBalance(currency);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _getCurrencyIcon(currency),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              balance.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الرصيد المتاح',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCurrencyIcon(String currency) {
    IconData iconData;
    Color iconColor;
    
    switch (currency) {
      case 'USDT':
        iconData = Icons.monetization_on;
        iconColor = Colors.green;
        break;
      case 'BTC':
        iconData = Icons.currency_bitcoin;
        iconColor = Colors.orange;
        break;
      case 'ETH':
        iconData = Icons.diamond;
        iconColor = Colors.purple;
        break;
      case 'ShamCash':
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.attach_money;
        iconColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return OptimizedFutureBuilder<List<Map<String, dynamic>>?>(
      futureBuilder: () => _firestoreService.getUserTransactions(
        context: context,
        showLoading: false,
        limit: 5,
      ).then((snapshot) {
        if (snapshot == null) return [];
        
        return snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      }),
      cacheKey: 'recent_transactions',
      builder: (context, transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد معاملات حديثة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Column(
          children: transactions.map((transaction) {
            final type = transaction['type'] as String? ?? 'unknown';
            final method = transaction['method'] as String? ?? '';
            final amount = transaction['amount'] as num? ?? 0;
            final status = transaction['status'] as String? ?? 'pending';
            final timestamp = transaction['timestamp'];
            
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                ),
              ),
              title: Text(_getTypeText(type)),
              subtitle: Text(method),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${type.toLowerCase() == 'withdrawal' ? '-' : '+'} ${amount.toString()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: type.toLowerCase() == 'withdrawal' ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
              onTap: () => _navigateToTransactions(),
            );
          }).toList(),
        );
      },
      loadingBuilder: (context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'فشل في تحميل المعاملات',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[600],
                ),
              ),
              TextButton(
                onPressed: _loadWalletData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Icons.arrow_downward;
      case 'withdrawal':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'exchange':
        return Icons.currency_exchange;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Colors.green;
      case 'withdrawal':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      case 'exchange':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'إيداع';
      case 'withdrawal':
        return 'سحب';
      case 'transfer':
        return 'تحويل';
      case 'exchange':
        return 'تبادل';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
