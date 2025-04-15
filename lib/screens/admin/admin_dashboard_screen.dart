import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _pendingUsers = 0;
  int _totalTransactions = 0;
  int _pendingTransactions = 0;
  int _totalDeposits = 0;
  int _totalWithdrawals = 0;
  Map<String, double> _totalBalances = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _recentUsers = [];
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final isAdmin = userData['isAdmin'] ?? false;
          
          setState(() {
            _isAdmin = isAdmin;
          });
          
          if (isAdmin) {
            await _loadDashboardData();
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadDashboardData() async {
    try {
      // Load user statistics
      final usersQuery = await _firestore.collection('users').get();
      final activeUsersQuery = await _firestore.collection('users').where('status', isEqualTo: 'active').get();
      final pendingUsersQuery = await _firestore.collection('users').where('status', isEqualTo: 'pending').get();
      
      // Load transaction statistics
      final transactionsQuery = await _firestore.collection('transactions').get();
      final pendingTransactionsQuery = await _firestore.collection('transactions').where('status', isEqualTo: 'pending').get();
      final depositsQuery = await _firestore.collection('transactions').where('type', isEqualTo: 'deposit').get();
      final withdrawalsQuery = await _firestore.collection('transactions').where('type', isEqualTo: 'withdraw').get();
      
      // Load admin wallet balances
      final adminWalletDoc = await _firestore.collection('admin_wallet').doc('main').get();
      
      if (adminWalletDoc.exists) {
        final walletData = adminWalletDoc.data() as Map<String, dynamic>;
        final balances = walletData['balances'] as Map<String, dynamic>;
        
        Map<String, double> formattedBalances = {};
        
        for (var entry in balances.entries) {
          formattedBalances[entry.key] = (entry.value as num).toDouble();
        }
        
        setState(() {
          _totalBalances = formattedBalances;
        });
      }
      
      // Load recent transactions
      final recentTransactionsQuery = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      List<Map<String, dynamic>> recentTransactions = [];
      
      for (var doc in recentTransactionsQuery.docs) {
        final transactionData = doc.data() as Map<String, dynamic>;
        transactionData['id'] = doc.id;
        recentTransactions.add(transactionData);
      }
      
      // Load recent users
      final recentUsersQuery = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      List<Map<String, dynamic>> recentUsers = [];
      
      for (var doc in recentUsersQuery.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        recentUsers.add(userData);
      }
      
      setState(() {
        _totalUsers = usersQuery.docs.length;
        _activeUsers = activeUsersQuery.docs.length;
        _pendingUsers = pendingUsersQuery.docs.length;
        _totalTransactions = transactionsQuery.docs.length;
        _pendingTransactions = pendingTransactionsQuery.docs.length;
        _totalDeposits = depositsQuery.docs.length;
        _totalWithdrawals = withdrawalsQuery.docs.length;
        _recentTransactions = recentTransactions;
        _recentUsers = recentUsers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'deposit':
        return 'إيداع';
      case 'withdraw':
        return 'سحب';
      case 'transfer':
        return 'تحويل';
      case 'exchange':
        return 'مبادلة';
      case 'fee':
        return 'رسوم';
      case 'refund':
        return 'استرداد';
      case 'adjustment':
        return 'تعديل';
      default:
        return type;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(
                  child: Text(
                    'ليس لديك صلاحية الوصول إلى هذه الصفحة',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics cards
                        _buildStatisticsSection(),
                        const SizedBox(height: 24),
                        
                        // Admin wallet balances
                        const Text(
                          'أرصدة المحفظة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWalletBalances(),
                        const SizedBox(height: 24),
                        
                        // Recent transactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'أحدث المعاملات',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminTransactionsScreen(),
                                  ),
                                );
                              },
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _recentTransactions.isEmpty
                            ? const Card(
                                elevation: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('لا توجد معاملات حديثة'),
                                  ),
                                ),
                              )
                            : Column(
                                children: _recentTransactions.map((transaction) {
                                  return _buildTransactionCard(transaction);
                                }).toList(),
                              ),
                        const SizedBox(height: 24),
                        
                        // Recent users
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'أحدث المستخدمين',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminUserManagementScreen(),
                                  ),
                                );
                              },
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _recentUsers.isEmpty
                            ? const Card(
                                elevation: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('لا يوجد مستخدمين جدد'),
                                  ),
                                ),
                              )
                            : Column(
                                children: _recentUsers.map((user) {
                                  return _buildUserCard(user);
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'لوحة تحكم المشرف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _auth.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('الرئيسية'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('محفظة المشرف'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminWalletScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('إدارة المستخدمين'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminUserManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('إدارة المعاملات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminTransactionsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('إعدادات التطبيق'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to app settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await _auth.signOut();
              Navigator.pop(context);
              // Navigate to login screen
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'المستخدمين',
                value: _totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'المستخدمين النشطين',
                value: _activeUsers.toString(),
                icon: Icons.person_outline,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'المعاملات',
                value: _totalTransactions.toString(),
                icon: Icons.swap_horiz,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'المعاملات المعلقة',
                value: _pendingTransactions.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'الإيداعات',
                value: _totalDeposits.toString(),
                icon: Icons.add_circle_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'السحوبات',
                value: _totalWithdrawals.toString(),
                icon: Icons.remove_circle_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWalletBalances() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _totalBalances.length,
      itemBuilder: (context, index) {
        final currency = _totalBalances.keys.elementAt(index);
        final balance = _totalBalances[currency]!;
        
        Color cardColor;
        IconData currencyIcon;
        
        switch (currency) {
          case 'USD':
            cardColor = Colors.green.shade100;
            currencyIcon = Icons.attach_money;
            break;
          case 'EUR':
            cardColor = Colors.blue.shade100;
            currencyIcon = Icons.euro;
            break;
          case 'SYP':
            cardColor = Colors.red.shade100;
            currencyIcon = Icons.money;
            break;
          case 'SAR':
            cardColor = Colors.purple.shade100;
            currencyIcon = Icons.money;
            break;
          case 'AED':
            cardColor = Colors.orange.shade100;
            currencyIcon = Icons.money;
            break;
          case 'TRY':
            cardColor = Colors.teal.shade100;
            currencyIcon = Icons.money;
            break;
          default:
            cardColor = Colors.grey.shade100;
            currencyIcon = Icons.money;
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      currencyIcon,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCurrencyName(currency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _formatAmount(balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = (transaction['amount'] as num).toDouble();
    final currency = transaction['currency'] as String;
    final timestamp = transaction['timestamp'] as Timestamp;
    final status = transaction['status'] as String;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: type == 'deposit' ? Colors.green.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == 'deposit' ? Icons.add : Icons.remove,
                color: type == 'deposit' ? Colors.green : Colors.red,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTransactionTypeText(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDate(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${type == 'deposit' ? '+' : '-'} ${_formatAmount(amount)} $currency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: type == 'deposit' ? Colors.green : Colors.red,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? Colors.green.shade100
                        : status == 'pending'
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status == 'completed'
                        ? 'مكتملة'
                        : status == 'pending'
                            ? 'قيد الانتظار'
                            : 'فشلت',
                    style: TextStyle(
                      fontSize: 10,
                      color: status == 'completed'
                          ? Colors.green.shade800
                          : status == 'pending'
                              ? Colors.orange.shade800
                              : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserCard(Map<String, dynamic> user) {
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final status = user['status'] as String? ?? 'active';
    final createdAt = user['createdAt'] as Timestamp? ?? Timestamp.now();
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getUserStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getUserStatusText(status),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getUserStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getUserStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'suspended':
        return 'معلق';
      case 'blocked':
        return 'محظور';
      case 'pending':
        return 'قيد التفعيل';
      default:
        return status;
    }
  }
  
  Color _getUserStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  String _getCurrencyName(String code) {
    switch (code) {
      case 'USD':
        return 'دولار أمريكي';
      case 'EUR':
        return 'يورو';
      case 'SYP':
        return 'ليرة سورية';
      case 'SAR':
        return 'ريال سعودي';
      case 'AED':
        return 'درهم إماراتي';
      case 'TRY':
        return 'ليرة تركية';
      default:
        return code;
    }
  }
}

// Import other admin screens
import 'package:mpay_app/screens/admin/admin_wallet_screen.dart';
import 'package:mpay_app/screens/admin/admin_user_management_screen.dart';
import 'package:mpay_app/screens/admin/admin_transactions_screen.dart';
