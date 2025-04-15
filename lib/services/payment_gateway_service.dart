import 'package:flutter/material.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'dart:async';
import 'dart:convert';

class PaymentGatewayService {
  final ApiIntegrationService _apiService = ApiIntegrationService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final ErrorHandler _errorHandler = ErrorHandler();
  final SecurityUtils _securityUtils = SecurityUtils();
  
  // Supported payment gateways
  static const List<String> supportedGateways = [
    'stripe',
    'paypal',
    'crypto',
    'sham_cash',
    'bank_transfer',
  ];
  
  // Supported cryptocurrencies
  static const List<String> supportedCryptoCurrencies = [
    'USDT_TRC20',
    'USDT_ERC20',
    'BTC',
    'ETH',
  ];
  
  // Singleton pattern
  static final PaymentGatewayService _instance = PaymentGatewayService._internal();
  
  factory PaymentGatewayService() {
    return _instance;
  }
  
  PaymentGatewayService._internal();
  
  // Initialize the service
  Future<void> initialize() async {
    // Ensure API service is initialized
    await _apiService.initialize();
    
    // Initialize security features
    await _securityUtils.initializePaymentSecurity();
  }
  
  // Get available payment methods for a user
  Future<List<PaymentMethod>> getAvailablePaymentMethods(String userId) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached payment methods if available
        final cachedMethods = await _getCachedPaymentMethods(userId);
        if (cachedMethods.isNotEmpty) {
          return cachedMethods;
        }
        
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Get payment methods from API
      final response = await _apiService.get(
        '/payments/methods',
        queryParams: {'userId': userId},
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      final List<PaymentMethod> paymentMethods = [];
      
      if (response['methods'] != null && response['methods'] is List) {
        for (final method in response['methods']) {
          paymentMethods.add(PaymentMethod.fromJson(method));
        }
      }
      
      // Cache payment methods
      await _cachePaymentMethods(userId, paymentMethods);
      
      return paymentMethods;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get available payment methods',
        ErrorSeverity.medium,
      );
      
      // Try to get cached payment methods as fallback
      final cachedMethods = await _getCachedPaymentMethods(userId);
      if (cachedMethods.isNotEmpty) {
        return cachedMethods;
      }
      
      // Return default payment methods if all else fails
      return _getDefaultPaymentMethods();
    }
  }
  
  // Get cached payment methods
  Future<List<PaymentMethod>> _getCachedPaymentMethods(String userId) async {
    try {
      final cachedData = await _firebaseService.getUserCachedData(
        userId,
        'payment_methods',
      );
      
      if (cachedData != null && cachedData['methods'] != null) {
        final List<PaymentMethod> paymentMethods = [];
        
        for (final method in cachedData['methods']) {
          paymentMethods.add(PaymentMethod.fromJson(method));
        }
        
        return paymentMethods;
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    return [];
  }
  
  // Cache payment methods
  Future<void> _cachePaymentMethods(String userId, List<PaymentMethod> methods) async {
    try {
      final methodsJson = methods.map((method) => method.toJson()).toList();
      
      await _firebaseService.setUserCachedData(
        userId,
        'payment_methods',
        {'methods': methodsJson},
      );
    } catch (e) {
      // Ignore cache errors
    }
  }
  
  // Get default payment methods
  List<PaymentMethod> _getDefaultPaymentMethods() {
    return [
      PaymentMethod(
        id: 'crypto',
        name: 'Cryptocurrency',
        description: 'Pay with cryptocurrency',
        icon: Icons.currency_bitcoin,
        isEnabled: true,
        supportedCurrencies: ['USD', 'EUR'],
        paymentType: PaymentType.crypto,
        processingFee: 0.0,
        minAmount: 10.0,
        maxAmount: 10000.0,
      ),
      PaymentMethod(
        id: 'sham_cash',
        name: 'Sham Cash',
        description: 'Pay with Sham Cash',
        icon: Icons.account_balance_wallet,
        isEnabled: true,
        supportedCurrencies: ['USD', 'EUR', 'SYP'],
        paymentType: PaymentType.electronic,
        processingFee: 1.0,
        minAmount: 5.0,
        maxAmount: 5000.0,
      ),
    ];
  }
  
  // Get cryptocurrency wallet addresses
  Future<Map<String, String>> getCryptoWalletAddresses() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached wallet addresses if available
        final cachedAddresses = await _getCachedWalletAddresses();
        if (cachedAddresses.isNotEmpty) {
          return cachedAddresses;
        }
        
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Get wallet addresses from API
      final response = await _apiService.get(
        '/payments/crypto/wallets',
        useCache: true,
        cacheDuration: const Duration(days: 1),
      );
      
      final Map<String, String> walletAddresses = {};
      
      if (response['wallets'] != null && response['wallets'] is Map) {
        for (final entry in response['wallets'].entries) {
          walletAddresses[entry.key] = entry.value.toString();
        }
      }
      
      // Cache wallet addresses
      await _cacheWalletAddresses(walletAddresses);
      
      return walletAddresses;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get cryptocurrency wallet addresses',
        ErrorSeverity.medium,
      );
      
      // Try to get cached wallet addresses as fallback
      final cachedAddresses = await _getCachedWalletAddresses();
      if (cachedAddresses.isNotEmpty) {
        return cachedAddresses;
      }
      
      // Return default wallet addresses if all else fails
      return _getDefaultWalletAddresses();
    }
  }
  
  // Get cached wallet addresses
  Future<Map<String, String>> _getCachedWalletAddresses() async {
    try {
      final cachedData = await _firebaseService.getAppCachedData('crypto_wallets');
      
      if (cachedData != null && cachedData['wallets'] != null) {
        final Map<String, String> walletAddresses = {};
        
        for (final entry in cachedData['wallets'].entries) {
          walletAddresses[entry.key] = entry.value.toString();
        }
        
        return walletAddresses;
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    return {};
  }
  
  // Cache wallet addresses
  Future<void> _cacheWalletAddresses(Map<String, String> addresses) async {
    try {
      await _firebaseService.setAppCachedData(
        'crypto_wallets',
        {'wallets': addresses},
      );
    } catch (e) {
      // Ignore cache errors
    }
  }
  
  // Get default wallet addresses
  Map<String, String> _getDefaultWalletAddresses() {
    return {
      'USDT_TRC20': 'TXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      'USDT_ERC20': '0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      'BTC': 'bc1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      'ETH': '0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    };
  }
  
  // Submit deposit request
  Future<DepositResult> submitDepositRequest({
    required String userId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    required String? reference,
    required String? proofImagePath,
    String? cryptoCurrency,
    String? walletAddress,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Validate deposit request
      _validateDepositRequest(
        paymentMethodId,
        amount,
        currency,
        cryptoCurrency,
      );
      
      // Prepare request data
      final requestData = {
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'reference': reference,
        'cryptoCurrency': cryptoCurrency,
        'walletAddress': walletAddress,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (additionalData != null) {
        requestData.addAll(additionalData);
      }
      
      // Encrypt sensitive data
      final encryptedData = await _securityUtils.encryptPaymentData(requestData);
      
      // Upload proof image if provided
      String? proofImageUrl;
      if (proofImagePath != null) {
        proofImageUrl = await _firebaseService.uploadDepositProofImage(
          userId,
          proofImagePath,
        );
      }
      
      // Submit deposit request
      final response = await _apiService.post(
        '/payments/deposit',
        body: {
          'encryptedData': encryptedData,
          'proofImageUrl': proofImageUrl,
        },
      );
      
      // Process response
      final depositId = response['depositId'];
      final status = response['status'];
      final message = response['message'];
      
      // Save deposit request to local database
      await _saveDepositRequest(
        userId,
        depositId,
        paymentMethodId,
        amount,
        currency,
        status,
        proofImageUrl,
      );
      
      return DepositResult(
        success: true,
        depositId: depositId,
        status: status,
        message: message,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to submit deposit request',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'Failed to process deposit request';
      String errorCode = 'unknown_error';
      
      if (e is PaymentException) {
        errorMessage = e.message;
        errorCode = e.code;
      }
      
      return DepositResult(
        success: false,
        depositId: null,
        status: 'failed',
        message: errorMessage,
        errorCode: errorCode,
      );
    }
  }
  
  // Validate deposit request
  void _validateDepositRequest(
    String paymentMethodId,
    double amount,
    String currency,
    String? cryptoCurrency,
  ) {
    // Check if payment method is supported
    if (!supportedGateways.contains(paymentMethodId)) {
      throw PaymentException(
        'Unsupported payment method',
        'invalid_payment_method',
      );
    }
    
    // Check amount
    if (amount <= 0) {
      throw PaymentException(
        'Invalid amount',
        'invalid_amount',
      );
    }
    
    // Check currency
    if (currency.isEmpty) {
      throw PaymentException(
        'Invalid currency',
        'invalid_currency',
      );
    }
    
    // Check crypto currency if applicable
    if (paymentMethodId == 'crypto' && cryptoCurrency != null) {
      if (!supportedCryptoCurrencies.contains(cryptoCurrency)) {
        throw PaymentException(
          'Unsupported cryptocurrency',
          'invalid_crypto_currency',
        );
      }
    }
  }
  
  // Save deposit request to local database
  Future<void> _saveDepositRequest(
    String userId,
    String depositId,
    String paymentMethodId,
    double amount,
    String currency,
    String status,
    String? proofImageUrl,
  ) async {
    try {
      await _firebaseService.saveUserTransaction(
        userId,
        {
          'id': depositId,
          'type': 'deposit',
          'paymentMethodId': paymentMethodId,
          'amount': amount,
          'currency': currency,
          'status': status,
          'proofImageUrl': proofImageUrl,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Log error but don't throw
      _errorHandler.handleError(
        e,
        'Failed to save deposit request to local database',
        ErrorSeverity.low,
      );
    }
  }
  
  // Submit withdrawal request
  Future<WithdrawalResult> submitWithdrawalRequest({
    required String userId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    required String? destinationAddress,
    String? cryptoCurrency,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Validate withdrawal request
      _validateWithdrawalRequest(
        paymentMethodId,
        amount,
        currency,
        destinationAddress,
        cryptoCurrency,
      );
      
      // Check user balance
      final hasBalance = await _checkUserBalance(userId, amount, currency);
      if (!hasBalance) {
        throw PaymentException(
          'Insufficient balance',
          'insufficient_balance',
        );
      }
      
      // Prepare request data
      final requestData = {
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'destinationAddress': destinationAddress,
        'cryptoCurrency': cryptoCurrency,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (additionalData != null) {
        requestData.addAll(additionalData);
      }
      
      // Encrypt sensitive data
      final encryptedData = await _securityUtils.encryptPaymentData(requestData);
      
      // Submit withdrawal request
      final response = await _apiService.post(
        '/payments/withdrawal',
        body: {
          'encryptedData': encryptedData,
        },
      );
      
      // Process response
      final withdrawalId = response['withdrawalId'];
      final status = response['status'];
      final message = response['message'];
      
      // Save withdrawal request to local database
      await _saveWithdrawalRequest(
        userId,
        withdrawalId,
        paymentMethodId,
        amount,
        currency,
        status,
        destinationAddress,
      );
      
      return WithdrawalResult(
        success: true,
        withdrawalId: withdrawalId,
        status: status,
        message: message,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to submit withdrawal request',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'Failed to process withdrawal request';
      String errorCode = 'unknown_error';
      
      if (e is PaymentException) {
        errorMessage = e.message;
        errorCode = e.code;
      }
      
      return WithdrawalResult(
        success: false,
        withdrawalId: null,
        status: 'failed',
        message: errorMessage,
        errorCode: errorCode,
      );
    }
  }
  
  // Validate withdrawal request
  void _validateWithdrawalRequest(
    String paymentMethodId,
    double amount,
    String currency,
    String? destinationAddress,
    String? cryptoCurrency,
  ) {
    // Check if payment method is supported
    if (!supportedGateways.contains(paymentMethodId)) {
      throw PaymentException(
        'Unsupported payment method',
        'invalid_payment_method',
      );
    }
    
    // Check amount
    if (amount <= 0) {
      throw PaymentException(
        'Invalid amount',
        'invalid_amount',
      );
    }
    
    // Check currency
    if (currency.isEmpty) {
      throw PaymentException(
        'Invalid currency',
        'invalid_currency',
      );
    }
    
    // Check destination address
    if (destinationAddress == null || destinationAddress.isEmpty) {
      throw PaymentException(
        'Destination address is required',
        'missing_destination_address',
      );
    }
    
    // Check crypto currency if applicable
    if (paymentMethodId == 'crypto' && cryptoCurrency != null) {
      if (!supportedCryptoCurrencies.contains(cryptoCurrency)) {
        throw PaymentException(
          'Unsupported cryptocurrency',
          'invalid_crypto_currency',
        );
      }
    }
  }
  
  // Check user balance
  Future<bool> _checkUserBalance(String userId, double amount, String currency) async {
    try {
      final userWallet = await _firebaseService.getUserWallet(userId);
      
      if (userWallet != null && userWallet[currency] != null) {
        final balance = userWallet[currency] as double;
        return balance >= amount;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to check user balance',
        ErrorSeverity.medium,
      );
      return false;
    }
  }
  
  // Save withdrawal request to local database
  Future<void> _saveWithdrawalRequest(
    String userId,
    String withdrawalId,
    String paymentMethodId,
    double amount,
    String currency,
    String status,
    String? destinationAddress,
  ) async {
    try {
      await _firebaseService.saveUserTransaction(
        userId,
        {
          'id': withdrawalId,
          'type': 'withdrawal',
          'paymentMethodId': paymentMethodId,
          'amount': amount,
          'currency': currency,
          'status': status,
          'destinationAddress': destinationAddress,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Log error but don't throw
      _errorHandler.handleError(
        e,
        'Failed to save withdrawal request to local database',
        ErrorSeverity.low,
      );
    }
  }
  
  // Get transaction history
  Future<List<Transaction>> getTransactionHistory(
    String userId, {
    TransactionType? type,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached transactions if available
        final cachedTransactions = await _getCachedTransactions(userId);
        return _filterTransactions(
          cachedTransactions,
          type,
          currency,
          startDate,
          endDate,
          limit,
          offset,
        );
      }
      
      // Prepare query parameters
      final queryParams = <String, dynamic>{
        'userId': userId,
        'limit': limit,
        'offset': offset,
      };
      
      if (type != null) {
        queryParams['type'] = type.toString().split('.').last;
      }
      
      if (currency != null) {
        queryParams['currency'] = currency;
      }
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      // Get transactions from API
      final response = await _apiService.get(
        '/payments/transactions',
        queryParams: queryParams,
        useCache: true,
        cacheDuration: const Duration(minutes: 15),
      );
      
      final List<Transaction> transactions = [];
      
      if (response['transactions'] != null && response['transactions'] is List) {
        for (final transaction in response['transactions']) {
          transactions.add(Transaction.fromJson(transaction));
        }
      }
      
      // Cache transactions
      await _cacheTransactions(userId, transactions);
      
      return transactions;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get transaction history',
        ErrorSeverity.medium,
      );
      
      // Try to get cached transactions as fallback
      final cachedTransactions = await _getCachedTransactions(userId);
      return _filterTransactions(
        cachedTransactions,
        type,
        currency,
        startDate,
        endDate,
        limit,
        offset,
      );
    }
  }
  
  // Get cached transactions
  Future<List<Transaction>> _getCachedTransactions(String userId) async {
    try {
      final cachedData = await _firebaseService.getUserTransactions(userId);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        final List<Transaction> transactions = [];
        
        for (final transaction in cachedData) {
          transactions.add(Transaction.fromJson(transaction));
        }
        
        return transactions;
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    return [];
  }
  
  // Cache transactions
  Future<void> _cacheTransactions(String userId, List<Transaction> transactions) async {
    try {
      final transactionsJson = transactions.map((transaction) => transaction.toJson()).toList();
      
      await _firebaseService.setUserCachedData(
        userId,
        'transactions',
        {'transactions': transactionsJson},
      );
    } catch (e) {
      // Ignore cache errors
    }
  }
  
  // Filter transactions
  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    TransactionType? type,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
    int offset,
  ) {
    List<Transaction> filteredTransactions = List.from(transactions);
    
    if (type != null) {
      filteredTransactions = filteredTransactions.where((t) => t.type == type).toList();
    }
    
    if (currency != null) {
      filteredTransactions = filteredTransactions.where((t) => t.currency == currency).toList();
    }
    
    if (startDate != null) {
      filteredTransactions = filteredTransactions.where((t) => t.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      filteredTransactions = filteredTransactions.where((t) => t.timestamp.isBefore(endDate)).toList();
    }
    
    // Sort by timestamp (newest first)
    filteredTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply pagination
    if (offset < filteredTransactions.length) {
      final endIndex = offset + limit < filteredTransactions.length
          ? offset + limit
          : filteredTransactions.length;
      
      return filteredTransactions.sublist(offset, endIndex);
    }
    
    return [];
  }
  
  // Get transaction details
  Future<Transaction?> getTransactionDetails(String userId, String transactionId) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Try to get from cached transactions
        final cachedTransactions = await _getCachedTransactions(userId);
        return cachedTransactions.firstWhere(
          (t) => t.id == transactionId,
          orElse: () => throw PaymentException(
            'Transaction not found in cache',
            'transaction_not_found',
          ),
        );
      }
      
      // Get transaction details from API
      final response = await _apiService.get(
        '/payments/transactions/$transactionId',
        queryParams: {'userId': userId},
        useCache: true,
      );
      
      if (response['transaction'] != null) {
        return Transaction.fromJson(response['transaction']);
      }
      
      return null;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get transaction details',
        ErrorSeverity.medium,
      );
      
      // Try to get from cached transactions as fallback
      try {
        final cachedTransactions = await _getCachedTransactions(userId);
        return cachedTransactions.firstWhere(
          (t) => t.id == transactionId,
          orElse: () => throw PaymentException(
            'Transaction not found',
            'transaction_not_found',
          ),
        );
      } catch (e) {
        return null;
      }
    }
  }
  
  // Get user wallet balance
  Future<Map<String, double>> getUserWalletBalance(String userId) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached balance if available
        final cachedBalance = await _getCachedWalletBalance(userId);
        if (cachedBalance.isNotEmpty) {
          return cachedBalance;
        }
        
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Get wallet balance from API
      final response = await _apiService.get(
        '/payments/wallet/balance',
        queryParams: {'userId': userId},
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );
      
      final Map<String, double> balance = {};
      
      if (response['balance'] != null && response['balance'] is Map) {
        for (final entry in response['balance'].entries) {
          balance[entry.key] = double.parse(entry.value.toString());
        }
      }
      
      // Cache wallet balance
      await _cacheWalletBalance(userId, balance);
      
      return balance;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get user wallet balance',
        ErrorSeverity.medium,
      );
      
      // Try to get cached balance as fallback
      final cachedBalance = await _getCachedWalletBalance(userId);
      if (cachedBalance.isNotEmpty) {
        return cachedBalance;
      }
      
      // Return empty balance if all else fails
      return {};
    }
  }
  
  // Get cached wallet balance
  Future<Map<String, double>> _getCachedWalletBalance(String userId) async {
    try {
      final userWallet = await _firebaseService.getUserWallet(userId);
      
      if (userWallet != null) {
        final Map<String, double> balance = {};
        
        for (final entry in userWallet.entries) {
          if (entry.value is num) {
            balance[entry.key] = (entry.value as num).toDouble();
          }
        }
        
        return balance;
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    return {};
  }
  
  // Cache wallet balance
  Future<void> _cacheWalletBalance(String userId, Map<String, double> balance) async {
    try {
      await _firebaseService.updateUserWallet(userId, balance);
    } catch (e) {
      // Ignore cache errors
    }
  }
}

// Payment method class
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final List<String> supportedCurrencies;
  final PaymentType paymentType;
  final double processingFee;
  final double minAmount;
  final double maxAmount;
  
  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isEnabled,
    required this.supportedCurrencies,
    required this.paymentType,
    required this.processingFee,
    required this.minAmount,
    required this.maxAmount,
  });
  
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: _getIconFromString(json['icon']),
      isEnabled: json['isEnabled'] ?? true,
      supportedCurrencies: List<String>.from(json['supportedCurrencies'] ?? []),
      paymentType: _getPaymentTypeFromString(json['paymentType']),
      processingFee: double.parse(json['processingFee']?.toString() ?? '0.0'),
      minAmount: double.parse(json['minAmount']?.toString() ?? '0.0'),
      maxAmount: double.parse(json['maxAmount']?.toString() ?? '10000.0'),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'isEnabled': isEnabled,
      'supportedCurrencies': supportedCurrencies,
      'paymentType': paymentType.toString().split('.').last,
      'processingFee': processingFee,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
    };
  }
  
  static IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }
  
  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.credit_card) {
      return 'credit_card';
    } else if (icon == Icons.account_balance) {
      return 'account_balance';
    } else if (icon == Icons.currency_bitcoin) {
      return 'currency_bitcoin';
    } else if (icon == Icons.account_balance_wallet) {
      return 'account_balance_wallet';
    } else if (icon == Icons.payment) {
      return 'payment';
    } else {
      return 'payment';
    }
  }
  
  static PaymentType _getPaymentTypeFromString(String? typeString) {
    switch (typeString) {
      case 'card':
        return PaymentType.card;
      case 'bank':
        return PaymentType.bank;
      case 'crypto':
        return PaymentType.crypto;
      case 'electronic':
        return PaymentType.electronic;
      case 'cash':
        return PaymentType.cash;
      default:
        return PaymentType.electronic;
    }
  }
}

// Payment type enum
enum PaymentType {
  card,
  bank,
  crypto,
  electronic,
  cash,
}

// Transaction type enum
enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  payment,
  refund,
}

// Transaction status enum
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  processing,
}

// Transaction class
class Transaction {
  final String id;
  final TransactionType type;
  final String paymentMethodId;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? reference;
  final String? destinationAddress;
  final String? proofImageUrl;
  final Map<String, dynamic>? additionalData;
  
  Transaction({
    required this.id,
    required this.type,
    required this.paymentMethodId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.timestamp,
    this.reference,
    this.destinationAddress,
    this.proofImageUrl,
    this.additionalData,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: _getTransactionTypeFromString(json['type']),
      paymentMethodId: json['paymentMethodId'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      status: _getTransactionStatusFromString(json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      reference: json['reference'],
      destinationAddress: json['destinationAddress'],
      proofImageUrl: json['proofImageUrl'],
      additionalData: json['additionalData'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      'currency': currency,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'reference': reference,
      'destinationAddress': destinationAddress,
      'proofImageUrl': proofImageUrl,
      'additionalData': additionalData,
    };
  }
  
  static TransactionType _getTransactionTypeFromString(String typeString) {
    switch (typeString) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'transfer':
        return TransactionType.transfer;
      case 'payment':
        return TransactionType.payment;
      case 'refund':
        return TransactionType.refund;
      default:
        return TransactionType.payment;
    }
  }
  
  static TransactionStatus _getTransactionStatusFromString(String statusString) {
    switch (statusString) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'processing':
        return TransactionStatus.processing;
      default:
        return TransactionStatus.pending;
    }
  }
}

// Deposit result class
class DepositResult {
  final bool success;
  final String? depositId;
  final String status;
  final String message;
  final String? errorCode;
  
  DepositResult({
    required this.success,
    this.depositId,
    required this.status,
    required this.message,
    this.errorCode,
  });
}

// Withdrawal result class
class WithdrawalResult {
  final bool success;
  final String? withdrawalId;
  final String status;
  final String message;
  final String? errorCode;
  
  WithdrawalResult({
    required this.success,
    this.withdrawalId,
    required this.status,
    required this.message,
    this.errorCode,
  });
}

// Payment exception class
class PaymentException implements Exception {
  final String message;
  final String code;
  
  PaymentException(this.message, this.code);
  
  @override
  String toString() => 'PaymentException: $message (Code: $code)';
}
