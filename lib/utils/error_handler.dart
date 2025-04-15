import 'package:flutter/material.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class ErrorHandler {
  // Global error handling for widget exceptions
  static Widget buildErrorWidget(BuildContext context, FlutterErrorDetails error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حدث خطأ'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'عذراً، حدث خطأ غير متوقع',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'الرجاء إعادة تشغيل التطبيق والمحاولة مرة أخرى.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('العودة إلى الصفحة الرئيسية'),
            ),
          ],
        ),
      ),
    );
  }

  // Handle API errors
  static void handleApiError(BuildContext context, dynamic error, {VoidCallback? onRetry}) {
    String errorMessage = 'حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.';
    
    if (error.toString().contains('timeout')) {
      errorMessage = 'انتهت مهلة الاتصال. الرجاء التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
    } else if (error.toString().contains('connection refused')) {
      errorMessage = 'تعذر الاتصال بالخادم. الرجاء المحاولة لاحقاً.';
    } else if (error.toString().contains('not found')) {
      errorMessage = 'لم يتم العثور على البيانات المطلوبة.';
    } else if (error.toString().contains('permission')) {
      errorMessage = 'ليس لديك صلاحية للوصول إلى هذه البيانات.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إغلاق'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('إعادة المحاولة'),
            ),
        ],
      ),
    );
  }

  // Show a snackbar with error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show a loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'جاري التحميل...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Handle network errors with retry option
  static Future<T> handleNetworkOperation<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    required String loadingMessage,
    required String successMessage,
    required String errorMessage,
    bool showLoadingDialog = true,
    bool showSuccessMessage = true,
  }) async {
    if (showLoadingDialog) {
      ErrorHandler.showLoadingDialog(context, message: loadingMessage);
    }

    try {
      final isConnected = await ConnectivityUtils.isConnected();
      if (!isConnected) {
        if (showLoadingDialog) {
          ErrorHandler.hideLoadingDialog(context);
        }
        ErrorHandler.showErrorSnackBar(
          context, 
          'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.'
        );
        throw Exception('No internet connection');
      }

      final result = await ConnectivityUtils.retryOperation(operation);
      
      if (showLoadingDialog) {
        ErrorHandler.hideLoadingDialog(context);
      }
      
      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      return result;
    } catch (e) {
      if (showLoadingDialog) {
        ErrorHandler.hideLoadingDialog(context);
      }
      
      ErrorHandler.handleApiError(
        context, 
        e,
        onRetry: () async {
          await handleNetworkOperation(
            context: context,
            operation: operation,
            loadingMessage: loadingMessage,
            successMessage: successMessage,
            errorMessage: errorMessage,
            showLoadingDialog: showLoadingDialog,
            showSuccessMessage: showSuccessMessage,
          );
        },
      );
      
      rethrow;
    }
  }

  // Create a widget for empty states
  static Widget buildEmptyStateWidget({
    required String message,
    required IconData icon,
    VoidCallback? onRefresh,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ],
      ),
    );
  }
}
