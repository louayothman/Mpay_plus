import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _hasMoreTransactions = true;
  int _currentPage = 1;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _transactions = [];
        _currentPage = 1;
        _hasMoreTransactions = true;
      });
    } else if (_isLoading || !_hasMoreTransactions) {
      return;
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }

      Query query = FirebaseFirestore.instance.collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true);

      // Apply filters
      if (_selectedFilter != 'all') {
        query = query.where('type', isEqualTo: _selectedFilter);
      }

      // Apply pagination
      query = query.limit(10 * _currentPage);

      final snapshot = await query.get();
      final List<Map<String, dynamic>> transactions = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      setState(() {
        _transactions = transactions;
        _isLoading = false;
        _hasMoreTransactions = transactions.length == 10 * _currentPage;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في تحميل المعاملات: $e'
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (!_hasMoreTransactions || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    await _loadTransactions();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير متوفر';
    
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
    
    return 'غير متوفر';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'مكتمل':
        return Colors.green;
      case 'pending':
      case 'قيد الانتظار':
        return Colors.orange;
      case 'rejected':
      case 'مرفوض':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
      case 'إيداع':
        return Icons.arrow_downward;
      case 'withdrawal':
      case 'سحب':
        return Icons.arrow_upward;
      case 'transfer':
      case 'تحويل':
        return Icons.swap_horiz;
      case 'exchange':
      case 'تبادل':
        return Icons.currency_exchange;
      default:
        return Icons.receipt_long;
    }
  }

  String _getTransactionTypeText(String type) {
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

  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المعاملات'),
        ),
        body: Column(
          children: [
            // Filter options
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'تصفية حسب:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'الكل'),
                          const SizedBox(width: 8),
                          _buildFilterChip('deposit', 'إيداع'),
                          const SizedBox(width: 8),
                          _buildFilterChip('withdrawal', 'سحب'),
                          const SizedBox(width: 8),
                          _buildFilterChip('transfer', 'تحويل'),
                          const SizedBox(width: 8),
                          _buildFilterChip('exchange', 'تبادل'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transactions list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadTransactions(refresh: true),
                child: _isLoading && _transactions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد معاملات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LazyLoadingListView(
                            itemCount: _transactions.length,
                            onEndReached: _hasMoreTransactions ? _loadMoreTransactions : null,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return _buildTransactionCard(transaction);
                            },
                            padding: const EdgeInsets.all(16),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadTransactions(refresh: true);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String? ?? 'unknown';
    final method = transaction['method'] as String? ?? '';
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String? ?? 'pending';
    final timestamp = transaction['timestamp'];
    final notes = transaction['notes'] as String? ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTransactionIcon(type),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTransactionTypeText(type),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          method,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${type.toLowerCase() == 'withdrawal' ? '-' : '+'} ${amount.toString()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: type.toLowerCase() == 'withdrawal' ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (notes.isNotEmpty)
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String? ?? 'unknown';
    final method = transaction['method'] as String? ?? '';
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String? ?? 'pending';
    final timestamp = transaction['timestamp'];
    final notes = transaction['notes'] as String? ?? '';
    final walletAddress = transaction['walletAddress'] as String? ?? '';
    final receiptUrl = transaction['receiptUrl'] as String? ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تفاصيل المعاملة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              _buildDetailRow('نوع المعاملة', _getTransactionTypeText(type)),
              _buildDetailRow('الطريقة', method),
              _buildDetailRow('المبلغ', amount.toString()),
              _buildDetailRow('الحالة', _getStatusText(status)),
              _buildDetailRow('التاريخ', _formatTimestamp(timestamp)),
              
              if (walletAddress.isNotEmpty)
                _buildDetailRow('عنوان المحفظة', walletAddress),
              
              if (notes.isNotEmpty)
                _buildDetailRow('ملاحظات', notes),
              
              if (receiptUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'صورة الإيصال',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OptimizedImage(
                    imageUrl: receiptUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              if (status.toLowerCase() == 'pending') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCancelTransactionDialog(transaction);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إلغاء المعاملة'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showCancelTransactionDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء المعاملة'),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTransaction(transaction);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTransaction(Map<String, dynamic> transaction) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }

      final transactionId = transaction['id'] as String;
      final type = transaction['type'] as String;
      final amount = transaction['amount'] as num;
      
      // Update transaction status
      await _firestoreService.updateDocument(
        context: context,
        collection: 'transactions',
        documentId: transactionId,
        data: {
          'status': 'cancelled',
          'notes': 'تم إلغاء المعاملة من قبل المستخدم',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // If it's a withdrawal, refund the amount to the wallet
      if (type.toLowerCase() == 'withdrawal') {
        String currency = transaction['method'].toString().split(' ')[0];
        if (transaction['method'] == 'Sham cash') {
          currency = 'ShamCash';
        }
        
        await _firestoreService.updateWalletBalance(
          context: context,
          userId: user.uid,
          currency: currency,
          amount: amount.toDouble(), // Refund the amount
        );
      }
      
      // Refresh transactions list
      await _loadTransactions(refresh: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء المعاملة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في إلغاء المعاملة: $e'
        );
      }
    }
  }
}
