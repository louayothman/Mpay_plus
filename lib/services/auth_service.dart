import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sign in with email and password with error handling
  Future<UserCredential?> signInWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
      loadingMessage: 'جاري تسجيل الدخول...',
      successMessage: 'تم تسجيل الدخول بنجاح',
      errorMessage: 'فشل في تسجيل الدخول',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // Don't show success message for login
    );
  }
  
  // Register with email and password with error handling
  Future<UserCredential?> registerWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
      loadingMessage: 'جاري إنشاء الحساب...',
      successMessage: 'تم إنشاء الحساب بنجاح',
      errorMessage: 'فشل في إنشاء الحساب',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // Don't show success message for registration
    );
  }
  
  // Reset password with error handling
  Future<void> resetPassword({
    required BuildContext context,
    required String email,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _auth.sendPasswordResetEmail(email: email),
      loadingMessage: 'جاري إرسال رابط إعادة تعيين كلمة المرور...',
      successMessage: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      errorMessage: 'فشل في إرسال رابط إعادة تعيين كلمة المرور',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Sign out with error handling
  Future<void> signOut({
    required BuildContext context,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _auth.signOut(),
      loadingMessage: 'جاري تسجيل الخروج...',
      successMessage: 'تم تسجيل الخروج بنجاح',
      errorMessage: 'فشل في تسجيل الخروج',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // Don't show success message for logout
    );
  }
  
  // Update user profile with error handling
  Future<void> updateProfile({
    required BuildContext context,
    String? displayName,
    String? photoURL,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => user.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      ),
      loadingMessage: 'جاري تحديث الملف الشخصي...',
      successMessage: 'تم تحديث الملف الشخصي بنجاح',
      errorMessage: 'فشل في تحديث الملف الشخصي',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Update email with error handling
  Future<void> updateEmail({
    required BuildContext context,
    required String newEmail,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => user.updateEmail(newEmail),
      loadingMessage: 'جاري تحديث البريد الإلكتروني...',
      successMessage: 'تم تحديث البريد الإلكتروني بنجاح',
      errorMessage: 'فشل في تحديث البريد الإلكتروني',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Update password with error handling
  Future<void> updatePassword({
    required BuildContext context,
    required String newPassword,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => user.updatePassword(newPassword),
      loadingMessage: 'جاري تحديث كلمة المرور...',
      successMessage: 'تم تحديث كلمة المرور بنجاح',
      errorMessage: 'فشل في تحديث كلمة المرور',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Re-authenticate user with error handling
  Future<UserCredential?> reauthenticate({
    required BuildContext context,
    required String email,
    required String password,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => user.reauthenticateWithCredential(credential),
      loadingMessage: 'جاري إعادة المصادقة...',
      successMessage: 'تمت إعادة المصادقة بنجاح',
      errorMessage: 'فشل في إعادة المصادقة',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // Don't show success message for reauthentication
    );
  }
  
  // Delete user account with error handling
  Future<void> deleteAccount({
    required BuildContext context,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => user.delete(),
      loadingMessage: 'جاري حذف الحساب...',
      successMessage: 'تم حذف الحساب بنجاح',
      errorMessage: 'فشل في حذف الحساب',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // Get current user with error handling
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  // Check if user is signed in
  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
  
  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
