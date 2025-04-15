import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  // Singleton instance
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();
  
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Local cache storage
  final Map<String, dynamic> _documentCache = {};
  final Map<String, List<dynamic>> _collectionCache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  
  // Initialize cache manager
  Future<void> initialize() async {
    await _optimizer.initialize();
    await _loadCacheFromDisk();
  }
  
  // Load cache from disk
  Future<void> _loadCacheFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load document cache
      final documentCacheJson = prefs.getString('document_cache');
      if (documentCacheJson != null) {
        final Map<String, dynamic> documentCache = Map<String, dynamic>.from(
          await _optimizer.computeInBackground(
            (json) => jsonDecode(json) as Map<String, dynamic>,
            documentCacheJson,
          ),
        );
        _documentCache.addAll(documentCache);
      }
      
      // Load collection cache
      final collectionCacheJson = prefs.getString('collection_cache');
      if (collectionCacheJson != null) {
        final Map<String, dynamic> collectionCache = Map<String, dynamic>.from(
          await _optimizer.computeInBackground(
            (json) => jsonDecode(json) as Map<String, dynamic>,
            collectionCacheJson,
          ),
        );
        
        collectionCache.forEach((key, value) {
          _collectionCache[key] = List<dynamic>.from(value);
        });
      }
      
      // Load cache expiry
      final cacheExpiryJson = prefs.getString('cache_expiry');
      if (cacheExpiryJson != null) {
        final Map<String, dynamic> cacheExpiry = Map<String, dynamic>.from(
          await _optimizer.computeInBackground(
            (json) => jsonDecode(json) as Map<String, dynamic>,
            cacheExpiryJson,
          ),
        );
        
        cacheExpiry.forEach((key, value) {
          _cacheExpiry[key] = DateTime.parse(value.toString());
        });
      }
    } catch (e) {
      print('Error loading cache from disk: $e');
    }
  }
  
  // Save cache to disk
  Future<void> _saveCacheToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert cache expiry to JSON-serializable format
      final Map<String, String> cacheExpiryJson = {};
      _cacheExpiry.forEach((key, value) {
        cacheExpiryJson[key] = value.toIso8601String();
      });
      
      // Convert collection cache to JSON-serializable format
      final Map<String, List<dynamic>> collectionCacheJson = {};
      _collectionCache.forEach((key, value) {
        collectionCacheJson[key] = value;
      });
      
      // Save to SharedPreferences
      await prefs.setString(
        'document_cache',
        await _optimizer.computeInBackground(
          (cache) => jsonEncode(cache),
          _documentCache,
        ),
      );
      
      await prefs.setString(
        'collection_cache',
        await _optimizer.computeInBackground(
          (cache) => jsonEncode(cache),
          collectionCacheJson,
        ),
      );
      
      await prefs.setString(
        'cache_expiry',
        await _optimizer.computeInBackground(
          (cache) => jsonEncode(cache),
          cacheExpiryJson,
        ),
      );
    } catch (e) {
      print('Error saving cache to disk: $e');
    }
  }
  
  // Get document with caching
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$collection/$documentId';
    
    // Check if data is in cache and not expired
    if (!forceRefresh && _optimizer.enableDataCaching) {
      final cachedData = _getCachedDocument(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Check if we're offline and have no cached data
    final isOffline = await _optimizer.isOfflineModeAvailable();
    if (isOffline) {
      return null;
    }
    
    try {
      // Fetch from Firestore
      final docSnapshot = await _firestore.collection(collection).doc(documentId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        
        // Cache the data
        if (_optimizer.enableDataCaching) {
          _cacheDocument(cacheKey, data);
        }
        
        return data;
      }
      
      return null;
    } catch (e) {
      print('Error fetching document: $e');
      return null;
    }
  }
  
  // Get collection with caching
  Future<List<Map<String, dynamic>>?> getCollection({
    required String collection,
    Map<String, dynamic>? query,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    final cacheKey = '$collection/${query?.toString() ?? 'all'}/page$page';
    
    // Check if data is in cache and not expired
    if (!forceRefresh && _optimizer.enableDataCaching) {
      final cachedData = _getCachedCollection(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Check if we're offline and have no cached data
    final isOffline = await _optimizer.isOfflineModeAvailable();
    if (isOffline) {
      return null;
    }
    
    try {
      // Start with collection reference
      Query queryRef = _firestore.collection(collection);
      
      // Apply query parameters if provided
      if (query != null) {
        query.forEach((field, value) {
          if (value is Map<String, dynamic> && value.containsKey('operator')) {
            final operator = value['operator'];
            final operand = value['value'];
            
            if (operator == '==') {
              queryRef = queryRef.where(field, isEqualTo: operand);
            } else if (operator == '>') {
              queryRef = queryRef.where(field, isGreaterThan: operand);
            } else if (operator == '>=') {
              queryRef = queryRef.where(field, isGreaterThanOrEqualTo: operand);
            } else if (operator == '<') {
              queryRef = queryRef.where(field, isLessThan: operand);
            } else if (operator == '<=') {
              queryRef = queryRef.where(field, isLessThanOrEqualTo: operand);
            } else if (operator == 'array-contains') {
              queryRef = queryRef.where(field, arrayContains: operand);
            }
          } else {
            queryRef = queryRef.where(field, isEqualTo: value);
          }
        });
      }
      
      // Apply pagination if enabled
      if (_optimizer.enablePagination) {
        final paginationParams = _optimizer.getPaginationParams(page: page);
        queryRef = queryRef.limit(paginationParams['limit']);
        
        if (page > 1) {
          // For proper pagination, we need a cursor, but this is simplified
          queryRef = queryRef.limit(paginationParams['limit']).offset(paginationParams['offset']);
        }
      }
      
      // Execute query
      final querySnapshot = await queryRef.get();
      
      // Convert to list of maps
      final List<Map<String, dynamic>> result = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
      
      // Cache the data
      if (_optimizer.enableDataCaching) {
        _cacheCollection(cacheKey, result);
      }
      
      return result;
    } catch (e) {
      print('Error fetching collection: $e');
      return null;
    }
  }
  
  // Get user data with caching
  Future<Map<String, dynamic>?> getUserData({
    bool forceRefresh = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    return await getDocument(
      collection: 'users',
      documentId: user.uid,
      forceRefresh: forceRefresh,
    );
  }
  
  // Get wallet data with caching
  Future<Map<String, dynamic>?> getWalletData({
    bool forceRefresh = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    return await getDocument(
      collection: 'wallets',
      documentId: user.uid,
      forceRefresh: forceRefresh,
    );
  }
  
  // Get user transactions with caching
  Future<List<Map<String, dynamic>>?> getUserTransactions({
    bool forceRefresh = false,
    int page = 1,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    return await getCollection(
      collection: 'transactions',
      query: {
        'userId': user.uid,
        'timestamp': {
          'operator': '<=',
          'value': Timestamp.now(),
        },
      },
      forceRefresh: forceRefresh,
      page: page,
    );
  }
  
  // Cache a document
  void _cacheDocument(String key, Map<String, dynamic> data) {
    _documentCache[key] = data;
    _cacheExpiry[key] = DateTime.now().add(Duration(hours: _optimizer.cacheDuration));
    _saveCacheToDisk();
  }
  
  // Cache a collection
  void _cacheCollection(String key, List<Map<String, dynamic>> data) {
    _collectionCache[key] = data;
    _cacheExpiry[key] = DateTime.now().add(Duration(hours: _optimizer.cacheDuration));
    _saveCacheToDisk();
  }
  
  // Get cached document
  Map<String, dynamic>? _getCachedDocument(String key) {
    if (_documentCache.containsKey(key) && _cacheExpiry.containsKey(key)) {
      if (DateTime.now().isBefore(_cacheExpiry[key]!)) {
        return Map<String, dynamic>.from(_documentCache[key]);
      } else {
        // Data expired, remove it
        _documentCache.remove(key);
        _cacheExpiry.remove(key);
        _saveCacheToDisk();
      }
    }
    
    return null;
  }
  
  // Get cached collection
  List<Map<String, dynamic>>? _getCachedCollection(String key) {
    if (_collectionCache.containsKey(key) && _cacheExpiry.containsKey(key)) {
      if (DateTime.now().isBefore(_cacheExpiry[key]!)) {
        return (_collectionCache[key] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        // Data expired, remove it
        _collectionCache.remove(key);
        _cacheExpiry.remove(key);
        _saveCacheToDisk();
      }
    }
    
    return null;
  }
  
  // Clear all cache
  Future<void> clearCache() async {
    _documentCache.clear();
    _collectionCache.clear();
    _cacheExpiry.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('document_cache');
    await prefs.remove('collection_cache');
    await prefs.remove('cache_expiry');
  }
  
  // Clear specific cache
  Future<void> clearSpecificCache(String collection, String? documentId) async {
    if (documentId != null) {
      // Clear specific document
      final key = '$collection/$documentId';
      _documentCache.remove(key);
      _cacheExpiry.remove(key);
    } else {
      // Clear all documents in collection
      final keysToRemove = _documentCache.keys
          .where((key) => key.startsWith('$collection/'))
          .toList();
          
      for (final key in keysToRemove) {
        _documentCache.remove(key);
        _cacheExpiry.remove(key);
      }
      
      // Clear all collection queries
      final collectionKeysToRemove = _collectionCache.keys
          .where((key) => key.startsWith('$collection/'))
          .toList();
          
      for (final key in collectionKeysToRemove) {
        _collectionCache.remove(key);
        _cacheExpiry.remove(key);
      }
    }
    
    await _saveCacheToDisk();
  }
}
