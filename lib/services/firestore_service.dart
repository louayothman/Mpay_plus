import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generic method to get a document with error handling
  Future<DocumentSnapshot?> getDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    bool showLoading = true,
    bool showSuccess = false,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _firestore.collection(collection).doc(documentId).get(),
      loadingMessage: 'جاري تحميل البيانات...',
      successMessage: 'تم تحميل البيانات بنجاح',
      errorMessage: 'فشل في تحميل البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // Generic method to get a collection with error handling
  Future<QuerySnapshot?> getCollection({
    required BuildContext context,
    required String collection,
    Query Function(CollectionReference)? queryBuilder,
    bool showLoading = true,
    bool showSuccess = false,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () {
        CollectionReference collectionRef = _firestore.collection(collection);
        Query query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;
        return query.get();
      },
      loadingMessage: 'جاري تحميل البيانات...',
      successMessage: 'تم تحميل البيانات بنجاح',
      errorMessage: 'فشل في تحميل البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // Generic method to add a document with error handling
  Future<DocumentReference?> addDocument({
    required BuildContext context,
    required String collection,
    required Map<String, dynamic> data,
    bool showLoading = true,
    bool showSuccess = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _firestore.collection(collection).add(data),
      loadingMessage: 'جاري إضافة البيانات...',
      successMessage: 'تمت إضافة البيانات بنجاح',
      errorMessage: 'فشل في إضافة البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // Generic method to set a document with error handling
  Future<void> setDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
    bool showLoading = true,
    bool showSuccess = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: merge)),
      loadingMessage: 'جاري حفظ البيانات...',
      successMessage: 'تم حفظ البيانات بنجاح',
      errorMessage: 'فشل في حفظ البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // Generic method to update a document with error handling
  Future<void> updateDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool showLoading = true,
    bool showSuccess = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _firestore.collection(collection).doc(documentId).update(data),
      loadingMessage: 'جاري تحديث البيانات...',
      successMessage: 'تم تحديث البيانات بنجاح',
      errorMessage: 'فشل في تحديث البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // Generic method to delete a document with error handling
  Future<void> deleteDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    bool showLoading = true,
    bool showSuccess = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () => _firestore.collection(collection).doc(documentId).delete(),
      loadingMessage: 'جاري حذف البيانات...',
      successMessage: 'تم حذف البيانات بنجاح',
      errorMessage: 'فشل في حذف البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // Get user data with error handling
  Future<DocumentSnapshot?> getUserData({
    required BuildContext context,
    String? userId,
    bool showLoading = true,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    return await getDocument(
      context: context,
      collection: 'users',
      documentId: uid,
      showLoading: showLoading,
    );
  }
  
  // Get wallet data with error handling
  Future<DocumentSnapshot?> getWalletData({
    required BuildContext context,
    String? userId,
    bool showLoading = true,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    return await getDocument(
      context: context,
      collection: 'wallets',
      documentId: uid,
      showLoading: showLoading,
    );
  }
  
  // Get user transactions with error handling
  Future<QuerySnapshot?> getUserTransactions({
    required BuildContext context,
    String? userId,
    bool showLoading = true,
    int limit = 20,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    return await getCollection(
      context: context,
      collection: 'transactions',
      queryBuilder: (CollectionReference ref) => ref
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit),
      showLoading: showLoading,
    );
  }
  
  // Create a transaction with error handling
  Future<DocumentReference?> createTransaction({
    required BuildContext context,
    required Map<String, dynamic> transactionData,
    bool showLoading = true,
  }) async {
    return await addDocument(
      context: context,
      collection: 'transactions',
      data: {
        ...transactionData,
        'timestamp': FieldValue.serverTimestamp(),
      },
      showLoading: showLoading,
    );
  }
  
  // Update wallet balance with error handling
  Future<void> updateWalletBalance({
    required BuildContext context,
    required String userId,
    required String currency,
    required double amount,
    bool showLoading = true,
  }) async {
    return await updateDocument(
      context: context,
      collection: 'wallets',
      documentId: userId,
      data: {
        'balances.$currency': FieldValue.increment(amount),
        'updatedAt': Timestamp.now(),
      },
      showLoading: showLoading,
    );
  }
}
