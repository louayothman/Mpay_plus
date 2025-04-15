import 'package:flutter/material.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/business/business_analytics_manager.dart';
import 'dart:async';
import 'dart:convert';

class AdminDashboardManager {
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Firebase service
  final FirebaseService _firebaseService = FirebaseService();
  
  // API service
  final ApiIntegrationService _apiService = ApiIntegrationService();
  
  // Connectivity utils
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  
  // Business analytics manager
  final BusinessAnalyticsManager _analyticsManager = BusinessAnalyticsManager();
  
  // Dashboard data
  Map<String, dynamic> _dashboardData = {};
  
  // Admin settings
  Map<String, dynamic> _adminSettings = {};
  
  // System alerts
  List<SystemAlert> _systemAlerts = [];
  
  // Pending approvals
  List<PendingApproval> _pendingApprovals = [];
  
  // Last refresh time
  DateTime? _lastRefreshTime;
  
  // Singleton pattern
  static final AdminDashboardManager _instance = AdminDashboardManager._internal();
  
  factory AdminDashboardManager() {
    return _instance;
  }
  
  AdminDashboardManager._internal();
  
  // Initialize the manager
  Future<void> initialize() async {
    try {
      // Ensure API service is initialized
      await _apiService.initialize();
      
      // Ensure analytics manager is initialized
      await _analyticsManager.initialize();
      
      // Load cached dashboard data
      await _loadCachedDashboardData();
      
      // Refresh dashboard data if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      if (hasConnection) {
        await refreshDashboardData();
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize admin dashboard manager',
        ErrorSeverity.high,
      );
    }
  }
  
  // Load cached dashboard data
  Future<void> _loadCachedDashboardData() async {
    try {
      final dashboardData = await _firebaseService.getAppCachedData('admin_dashboard');
      if (dashboardData != null) {
        _dashboardData = dashboardData;
      }
      
      final adminSettings = await _firebaseService.getAppCachedData('admin_settings');
      if (adminSettings != null) {
        _adminSettings = adminSettings;
      }
      
      final systemAlertsData = await _firebaseService.getAppCachedData('system_alerts');
      if (systemAlertsData != null && systemAlertsData['alerts'] != null) {
        _systemAlerts = (systemAlertsData['alerts'] as List)
            .map((alert) => SystemAlert.fromJson(alert))
            .toList();
      }
      
      final approvalsData = await _firebaseService.getAppCachedData('pending_approvals');
      if (approvalsData != null && approvalsData['approvals'] != null) {
        _pendingApprovals = (approvalsData['approvals'] as List)
            .map((approval) => PendingApproval.fromJson(approval))
            .toList();
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to load cached dashboard data',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Save dashboard data to cache
  Future<void> _saveDashboardDataToCache() async {
    try {
      await _firebaseService.setAppCachedData('admin_dashboard', _dashboardData);
      await _firebaseService.setAppCachedData('admin_settings', _adminSettings);
      
      await _firebaseService.setAppCachedData('system_alerts', {
        'alerts': _systemAlerts.map((alert) => alert.toJson()).toList(),
      });
      
      await _firebaseService.setAppCachedData('pending_approvals', {
        'approvals': _pendingApprovals.map((approval) => approval.toJson()).toList(),
      });
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save dashboard data to cache',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh dashboard data
  Future<void> refreshDashboardData() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      await Future.wait([
        _refreshDashboardSummary(),
        _refreshSystemAlerts(),
        _refreshPendingApprovals(),
        _refreshAdminSettings(),
      ]);
      
      // Update last refresh time
      _lastRefreshTime = DateTime.now();
      
      // Save updated data to cache
      await _saveDashboardDataToCache();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh dashboard data',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh dashboard summary
  Future<void> _refreshDashboardSummary() async {
    try {
      // Get dashboard summary from API
      final response = await _apiService.get(
        '/admin/dashboard/summary',
        useCache: true,
        cacheDuration: const Duration(minutes: 15),
      );
      
      _dashboardData = response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh dashboard summary',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh system alerts
  Future<void> _refreshSystemAlerts() async {
    try {
      // Get system alerts from API
      final response = await _apiService.get(
        '/admin/system/alerts',
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );
      
      if (response['alerts'] != null && response['alerts'] is List) {
        _systemAlerts = (response['alerts'] as List)
            .map((alert) => SystemAlert.fromJson(alert))
            .toList();
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh system alerts',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh pending approvals
  Future<void> _refreshPendingApprovals() async {
    try {
      // Get pending approvals from API
      final response = await _apiService.get(
        '/admin/approvals/pending',
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );
      
      if (response['approvals'] != null && response['approvals'] is List) {
        _pendingApprovals = (response['approvals'] as List)
            .map((approval) => PendingApproval.fromJson(approval))
            .toList();
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh pending approvals',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh admin settings
  Future<void> _refreshAdminSettings() async {
    try {
      // Get admin settings from API
      final response = await _apiService.get(
        '/admin/settings',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      _adminSettings = response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh admin settings',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Get dashboard summary
  Map<String, dynamic> getDashboardSummary() {
    return Map.from(_dashboardData);
  }
  
  // Get system alerts
  List<SystemAlert> getSystemAlerts() {
    return List.from(_systemAlerts);
  }
  
  // Get pending approvals
  List<PendingApproval> getPendingApprovals() {
    return List.from(_pendingApprovals);
  }
  
  // Get admin settings
  Map<String, dynamic> getAdminSettings() {
    return Map.from(_adminSettings);
  }
  
  // Get last refresh time
  DateTime? getLastRefreshTime() {
    return _lastRefreshTime;
  }
  
  // Get user count
  int getUserCount() {
    return _dashboardData['userCount'] ?? 0;
  }
  
  // Get transaction count
  int getTransactionCount() {
    return _dashboardData['transactionCount'] ?? 0;
  }
  
  // Get total volume
  double getTotalVolume() {
    return (_dashboardData['totalVolume'] ?? 0).toDouble();
  }
  
  // Get revenue
  double getRevenue() {
    return (_dashboardData['revenue'] ?? 0).toDouble();
  }
  
  // Get active users
  int getActiveUsers() {
    return _dashboardData['activeUsers'] ?? 0;
  }
  
  // Get system status
  String getSystemStatus() {
    return _dashboardData['systemStatus'] ?? 'Unknown';
  }
  
  // Get critical alerts count
  int getCriticalAlertsCount() {
    return _systemAlerts.where((alert) => alert.severity == AlertSeverity.critical).length;
  }
  
  // Get high priority alerts count
  int getHighPriorityAlertsCount() {
    return _systemAlerts.where((alert) => alert.severity == AlertSeverity.high).length;
  }
  
  // Get pending approvals count
  int getPendingApprovalsCount() {
    return _pendingApprovals.length;
  }
  
  // Get pending withdrawals count
  int getPendingWithdrawalsCount() {
    return _pendingApprovals.where((approval) => approval.type == ApprovalType.withdrawal).length;
  }
  
  // Get pending deposits count
  int getPendingDepositsCount() {
    return _pendingApprovals.where((approval) => approval.type == ApprovalType.deposit).length;
  }
  
  // Get pending verifications count
  int getPendingVerificationsCount() {
    return _pendingApprovals.where((approval) => approval.type == ApprovalType.verification).length;
  }
  
  // Process approval
  Future<bool> processApproval(String approvalId, bool approved, String? notes) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Process approval via API
      final response = await _apiService.post(
        '/admin/approvals/process',
        body: {
          'approvalId': approvalId,
          'approved': approved,
          'notes': notes,
          'processedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response['success'] ?? false;
      
      if (success) {
        // Remove from pending approvals
        _pendingApprovals.removeWhere((approval) => approval.id == approvalId);
        
        // Save updated data to cache
        await _saveDashboardDataToCache();
        
        // Refresh dashboard data
        await refreshDashboardData();
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to process approval',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  // Update system settings
  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Update settings via API
      final response = await _apiService.post(
        '/admin/settings/update',
        body: {
          'settings': settings,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response['success'] ?? false;
      
      if (success) {
        // Update local settings
        settings.forEach((key, value) {
          _adminSettings[key] = value;
        });
        
        // Save updated data to cache
        await _saveDashboardDataToCache();
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to update system settings',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  // Resolve system alert
  Future<bool> resolveSystemAlert(String alertId, String resolution) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Resolve alert via API
      final response = await _apiService.post(
        '/admin/system/alerts/resolve',
        body: {
          'alertId': alertId,
          'resolution': resolution,
          'resolvedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response['success'] ?? false;
      
      if (success) {
        // Remove from system alerts
        _systemAlerts.removeWhere((alert) => alert.id == alertId);
        
        // Save updated data to cache
        await _saveDashboardDataToCache();
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to resolve system alert',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  // Get user details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get user details from API
      final response = await _apiService.get(
        '/admin/users/$userId',
        useCache: true,
      );
      
      return response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get user details',
        ErrorSeverity.medium,
      );
      
      return {};
    }
  }
  
  // Get transaction details
  Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get transaction details from API
      final response = await _apiService.get(
        '/admin/transactions/$transactionId',
        useCache: true,
      );
      
      return response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get transaction details',
        ErrorSeverity.medium,
      );
      
      return {};
    }
  }
  
  // Update user status
  Future<bool> updateUserStatus(String userId, UserStatus status, String? reason) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Update user status via API
      final response = await _apiService.post(
        '/admin/users/$userId/status',
        body: {
          'status': status.toString().split('.').last,
          'reason': reason,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      
      return response['success'] ?? false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to update user status',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  // Get system logs
  Future<List<SystemLog>> getSystemLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? minLevel,
    int limit = 100,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Prepare query parameters
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      if (minLevel != null) {
        queryParams['minLevel'] = minLevel.toString().split('.').last;
      }
      
      // Get system logs from API
      final response = await _apiService.get(
        '/admin/system/logs',
        queryParams: queryParams,
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );
      
      if (response['logs'] != null && response['logs'] is List) {
        return (response['logs'] as List)
            .map((log) => SystemLog.fromJson(log))
            .toList();
      }
      
      return [];
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get system logs',
        ErrorSeverity.medium,
      );
      
      return [];
    }
  }
  
  // Get admin wallet balance
  Future<Map<String, double>> getAdminWalletBalance() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get admin wallet balance from API
      final response = await _apiService.get(
        '/admin/wallet/balance',
        useCache: true,
        cacheDuration: const Duration(minutes: 15),
      );
      
      if (response['balance'] != null && response['balance'] is Map) {
        final Map<String, double> balance = {};
        
        (response['balance'] as Map).forEach((key, value) {
          balance[key.toString()] = (value as num).toDouble();
        });
        
        return balance;
      }
      
      return {};
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get admin wallet balance',
        ErrorSeverity.medium,
      );
      
      return {};
    }
  }
  
  // Send funds from admin wallet
  Future<bool> sendFundsFromAdminWallet({
    required String userId,
    required String currency,
    required double amount,
    required String reason,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Send funds via API
      final response = await _apiService.post(
        '/admin/wallet/send',
        body: {
          'userId': userId,
          'currency': currency,
          'amount': amount,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      return response['success'] ?? false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to send funds from admin wallet',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  // Generate admin dashboard report
  String generateAdminDashboardReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('# Admin Dashboard Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    if (_lastRefreshTime != null) {
      buffer.writeln('Last Data Refresh: $_lastRefreshTime');
    }
    buffer.writeln();
    
    buffer.writeln('## Dashboard Summary');
    buffer.writeln('- User Count: ${getUserCount()}');
    buffer.writeln('- Transaction Count: ${getTransactionCount()}');
    buffer.writeln('- Total Volume: ${getTotalVolume().toStringAsFixed(2)}');
    buffer.writeln('- Revenue: ${getRevenue().toStringAsFixed(2)}');
    buffer.writeln('- Active Users: ${getActiveUsers()}');
    buffer.writeln('- System Status: ${getSystemStatus()}');
    buffer.writeln();
    
    buffer.writeln('## Pending Approvals');
    buffer.writeln('- Total Pending: ${getPendingApprovalsCount()}');
    buffer.writeln('- Pending Withdrawals: ${getPendingWithdrawalsCount()}');
    buffer.writeln('- Pending Deposits: ${getPendingDepositsCount()}');
    buffer.writeln('- Pending Verifications: ${getPendingVerificationsCount()}');
    buffer.writeln();
    
    buffer.writeln('### Recent Pending Approvals');
    final recentApprovals = getPendingApprovals().take(5).toList();
    if (recentApprovals.isEmpty) {
      buffer.writeln('No pending approvals.');
    } else {
      for (final approval in recentApprovals) {
        buffer.writeln('- ID: ${approval.id}');
        buffer.writeln('  Type: ${approval.type.toString().split('.').last}');
        buffer.writeln('  User: ${approval.userId}');
        buffer.writeln('  Amount: ${approval.amount?.toStringAsFixed(2) ?? 'N/A'} ${approval.currency ?? ''}');
        buffer.writeln('  Submitted: ${approval.submittedAt}');
        buffer.writeln();
      }
    }
    
    buffer.writeln('## System Alerts');
    buffer.writeln('- Critical Alerts: ${getCriticalAlertsCount()}');
    buffer.writeln('- High Priority Alerts: ${getHighPriorityAlertsCount()}');
    buffer.writeln();
    
    buffer.writeln('### Recent Alerts');
    final recentAlerts = getSystemAlerts().take(5).toList();
    if (recentAlerts.isEmpty) {
      buffer.writeln('No system alerts.');
    } else {
      for (final alert in recentAlerts) {
        buffer.writeln('- ID: ${alert.id}');
        buffer.writeln('  Title: ${alert.title}');
        buffer.writeln('  Severity: ${alert.severity.toString().split('.').last}');
        buffer.writeln('  Created: ${alert.createdAt}');
        buffer.writeln('  Message: ${alert.message}');
        buffer.writeln();
      }
    }
    
    buffer.writeln('## Admin Settings');
    final settings = getAdminSettings();
    if (settings.isEmpty) {
      buffer.writeln('No settings data available.');
    } else {
      for (final entry in settings.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }
    buffer.writeln();
    
    return buffer.toString();
  }
  
  // Save admin dashboard report to file
  Future<void> saveAdminDashboardReport(String filePath) async {
    try {
      final report = generateAdminDashboardReport();
      final file = File(filePath);
      await file.writeAsString(report);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save admin dashboard report',
        ErrorSeverity.medium,
      );
    }
  }
}

// System alert class
class SystemAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  final String? source;
  final Map<String, dynamic>? additionalData;
  
  SystemAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.source,
    this.additionalData,
  });
  
  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      severity: _getAlertSeverityFromString(json['severity']),
      createdAt: DateTime.parse(json['createdAt']),
      source: json['source'],
      additionalData: json['additionalData'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'additionalData': additionalData,
    };
  }
  
  static AlertSeverity _getAlertSeverityFromString(String severityString) {
    switch (severityString.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      default:
        return AlertSeverity.medium;
    }
  }
}

// Alert severity enum
enum AlertSeverity {
  critical,
  high,
  medium,
  low,
}

// Pending approval class
class PendingApproval {
  final String id;
  final ApprovalType type;
  final String userId;
  final double? amount;
  final String? currency;
  final DateTime submittedAt;
  final Map<String, dynamic>? data;
  
  PendingApproval({
    required this.id,
    required this.type,
    required this.userId,
    this.amount,
    this.currency,
    required this.submittedAt,
    this.data,
  });
  
  factory PendingApproval.fromJson(Map<String, dynamic> json) {
    return PendingApproval(
      id: json['id'],
      type: _getApprovalTypeFromString(json['type']),
      userId: json['userId'],
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      currency: json['currency'],
      submittedAt: DateTime.parse(json['submittedAt']),
      data: json['data'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'submittedAt': submittedAt.toIso8601String(),
      'data': data,
    };
  }
  
  static ApprovalType _getApprovalTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'withdrawal':
        return ApprovalType.withdrawal;
      case 'deposit':
        return ApprovalType.deposit;
      case 'verification':
        return ApprovalType.verification;
      case 'other':
        return ApprovalType.other;
      default:
        return ApprovalType.other;
    }
  }
}

// Approval type enum
enum ApprovalType {
  withdrawal,
  deposit,
  verification,
  other,
}

// User status enum
enum UserStatus {
  active,
  suspended,
  blocked,
  unverified,
  deleted,
}

// System log class
class SystemLog {
  final String id;
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? source;
  final String? userId;
  final Map<String, dynamic>? data;
  
  SystemLog({
    required this.id,
    required this.level,
    required this.message,
    required this.timestamp,
    this.source,
    this.userId,
    this.data,
  });
  
  factory SystemLog.fromJson(Map<String, dynamic> json) {
    return SystemLog(
      id: json['id'],
      level: _getLogLevelFromString(json['level']),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      userId: json['userId'],
      data: json['data'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'userId': userId,
      'data': data,
    };
  }
  
  static LogLevel _getLogLevelFromString(String levelString) {
    switch (levelString.toLowerCase()) {
      case 'error':
        return LogLevel.error;
      case 'warning':
        return LogLevel.warning;
      case 'info':
        return LogLevel.info;
      case 'debug':
        return LogLevel.debug;
      default:
        return LogLevel.info;
    }
  }
}

// Log level enum
enum LogLevel {
  error,
  warning,
  info,
  debug,
}
