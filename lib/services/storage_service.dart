import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'dart:io';
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload file with error handling
  Future<String?> uploadFile({
    required BuildContext context,
    required File file,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      },
      loadingMessage: 'جاري رفع الملف...',
      successMessage: 'تم رفع الملف بنجاح',
      errorMessage: 'فشل في رفع الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Upload data with error handling
  Future<String?> uploadData({
    required BuildContext context,
    required Uint8List data,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putData(data);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      },
      loadingMessage: 'جاري رفع البيانات...',
      successMessage: 'تم رفع البيانات بنجاح',
      errorMessage: 'فشل في رفع البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Download file with error handling
  Future<Uint8List?> downloadFile({
    required BuildContext context,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        final ref = _storage.ref().child(path);
        return await ref.getData();
      },
      loadingMessage: 'جاري تنزيل الملف...',
      successMessage: 'تم تنزيل الملف بنجاح',
      errorMessage: 'فشل في تنزيل الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // Don't show success message for downloads
    );
  }
  
  // Get download URL with error handling
  Future<String?> getDownloadURL({
    required BuildContext context,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        final ref = _storage.ref().child(path);
        return await ref.getDownloadURL();
      },
      loadingMessage: 'جاري الحصول على رابط التنزيل...',
      successMessage: 'تم الحصول على رابط التنزيل بنجاح',
      errorMessage: 'فشل في الحصول على رابط التنزيل',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // Don't show success message for getting URLs
    );
  }
  
  // Delete file with error handling
  Future<void> deleteFile({
    required BuildContext context,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        final ref = _storage.ref().child(path);
        return await ref.delete();
      },
      loadingMessage: 'جاري حذف الملف...',
      successMessage: 'تم حذف الملف بنجاح',
      errorMessage: 'فشل في حذف الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Upload profile picture with error handling
  Future<String?> uploadProfilePicture({
    required BuildContext context,
    required File file,
    required String userId,
    bool showLoading = true,
  }) async {
    final path = 'profile_pictures/$userId.jpg';
    return await uploadFile(
      context: context,
      file: file,
      path: path,
      showLoading: showLoading,
    );
  }
  
  // Upload transaction receipt with error handling
  Future<String?> uploadTransactionReceipt({
    required BuildContext context,
    required File file,
    required String transactionId,
    bool showLoading = true,
  }) async {
    final path = 'transaction_receipts/$transactionId.jpg';
    return await uploadFile(
      context: context,
      file: file,
      path: path,
      showLoading: showLoading,
    );
  }
}
