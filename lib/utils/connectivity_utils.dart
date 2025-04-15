import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

class ConnectivityUtils {
  static final Connectivity _connectivity = Connectivity();
  static final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();
  
  // Check if device is connected to internet
  static Future<bool> isConnected() async {
    try {
      // First check connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Then verify actual internet connection
      return await _connectionChecker.hasConnection;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }
  
  // Stream to listen for connectivity changes
  static Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.asyncMap(
      (ConnectivityResult result) async {
        if (result == ConnectivityResult.none) {
          return false;
        } else {
          return await _connectionChecker.hasConnection;
        }
      }
    );
  }
  
  // Show connectivity status banner
  static Widget connectivityBanner(bool isConnected) {
    if (isConnected) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت. بعض الميزات قد لا تعمل بشكل صحيح.',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
  
  // Retry mechanism for network operations
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
  }
}
