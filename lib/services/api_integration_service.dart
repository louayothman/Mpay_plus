import 'package:flutter/material.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/device_compatibility_manager.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiIntegrationService {
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final ErrorHandler _errorHandler = ErrorHandler();
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();
  final SecurityUtils _securityUtils = SecurityUtils();
  final DeviceCompatibilityManager _deviceCompatibilityManager = DeviceCompatibilityManager();
  
  // Base URLs for different environments
  static const String _productionBaseUrl = 'https://api.mpay.com/v1';
  static const String _stagingBaseUrl = 'https://staging-api.mpay.com/v1';
  static const String _developmentBaseUrl = 'https://dev-api.mpay.com/v1';
  
  // Current environment
  String _currentEnvironment = 'production';
  
  // API timeout duration
  Duration _timeoutDuration = const Duration(seconds: 30);
  
  // Retry configuration
  int _maxRetries = 3;
  Duration _retryDelay = const Duration(seconds: 2);
  
  // Cache configuration
  final Map<String, CachedResponse> _responseCache = {};
  final Duration _defaultCacheDuration = const Duration(minutes: 5);
  
  // Rate limiting
  final Map<String, DateTime> _lastRequestTimes = {};
  final Duration _minRequestInterval = const Duration(milliseconds: 500);
  
  // Authentication token
  String? _authToken;
  DateTime? _tokenExpiryTime;
  
  // Singleton pattern
  static final ApiIntegrationService _instance = ApiIntegrationService._internal();
  
  factory ApiIntegrationService() {
    return _instance;
  }
  
  ApiIntegrationService._internal();
  
  // Initialize the service
  Future<void> initialize({
    String environment = 'production',
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    Duration? cacheDuration,
    Duration? minRequestInterval,
  }) async {
    _currentEnvironment = environment;
    
    if (timeout != null) {
      _timeoutDuration = timeout;
    }
    
    if (maxRetries != null) {
      _maxRetries = maxRetries;
    }
    
    if (retryDelay != null) {
      _retryDelay = retryDelay;
    }
    
    if (minRequestInterval != null) {
      _minRequestInterval = minRequestInterval;
    }
    
    // Check device compatibility
    await _deviceCompatibilityManager.checkApiCompatibility();
    
    // Initialize security features
    await _securityUtils.initializeApiSecurity();
    
    // Clear cache
    clearCache();
  }
  
  // Get base URL based on current environment
  String get baseUrl {
    switch (_currentEnvironment) {
      case 'production':
        return _productionBaseUrl;
      case 'staging':
        return _stagingBaseUrl;
      case 'development':
        return _developmentBaseUrl;
      default:
        return _productionBaseUrl;
    }
  }
  
  // Set authentication token
  Future<void> setAuthToken(String token, {Duration? expiresIn}) async {
    _authToken = token;
    
    if (expiresIn != null) {
      _tokenExpiryTime = DateTime.now().add(expiresIn);
    } else {
      // Default token expiry time (1 hour)
      _tokenExpiryTime = DateTime.now().add(const Duration(hours: 1));
    }
    
    // Securely store the token
    await _securityUtils.securelyStoreApiToken(token, _tokenExpiryTime);
  }
  
  // Clear authentication token
  Future<void> clearAuthToken() async {
    _authToken = null;
    _tokenExpiryTime = null;
    await _securityUtils.clearSecurelyStoredApiToken();
  }
  
  // Check if token is valid
  bool get isTokenValid {
    if (_authToken == null || _tokenExpiryTime == null) {
      return false;
    }
    
    // Add a buffer of 5 minutes before actual expiry
    final expiryWithBuffer = _tokenExpiryTime!.subtract(const Duration(minutes: 5));
    return DateTime.now().isBefore(expiryWithBuffer);
  }
  
  // Refresh token if needed
  Future<bool> refreshTokenIfNeeded() async {
    if (isTokenValid) {
      return true;
    }
    
    try {
      // Try to get token from secure storage
      final storedToken = await _securityUtils.getSecurelyStoredApiToken();
      final storedExpiryTime = await _securityUtils.getSecurelyStoredApiTokenExpiry();
      
      if (storedToken != null && storedExpiryTime != null) {
        final expiryWithBuffer = storedExpiryTime.subtract(const Duration(minutes: 5));
        if (DateTime.now().isBefore(expiryWithBuffer)) {
          _authToken = storedToken;
          _tokenExpiryTime = storedExpiryTime;
          return true;
        }
      }
      
      // If no valid token in storage, refresh from server
      final refreshResult = await _refreshToken();
      return refreshResult;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh API token',
        ErrorSeverity.high,
      );
      return false;
    }
  }
  
  // Refresh token from server
  Future<bool> _refreshToken() async {
    try {
      // Get refresh token from secure storage
      final refreshToken = await _securityUtils.getSecurelyStoredRefreshToken();
      
      if (refreshToken == null) {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'X-Refresh-Token': refreshToken,
        },
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newToken = responseData['token'];
        final expiresIn = Duration(seconds: responseData['expiresIn'] ?? 3600);
        
        await setAuthToken(newToken, expiresIn: expiresIn);
        
        // Store new refresh token if provided
        if (responseData['refreshToken'] != null) {
          await _securityUtils.securelyStoreRefreshToken(responseData['refreshToken']);
        }
        
        return true;
      } else {
        // Clear tokens on refresh failure
        await clearAuthToken();
        await _securityUtils.clearSecurelyStoredRefreshToken();
        return false;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh token from server',
        ErrorSeverity.high,
      );
      return false;
    }
  }
  
  // Clear cache
  void clearCache() {
    _responseCache.clear();
  }
  
  // Clear specific cache entry
  void clearCacheEntry(String cacheKey) {
    _responseCache.remove(cacheKey);
  }
  
  // Generate cache key
  String _generateCacheKey(String url, Map<String, dynamic>? queryParams, Map<String, dynamic>? body) {
    final buffer = StringBuffer(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('?');
      buffer.write(sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
    }
    
    if (body != null && body.isNotEmpty) {
      buffer.write('#');
      buffer.write(json.encode(body));
    }
    
    return buffer.toString();
  }
  
  // Check rate limiting
  bool _checkRateLimit(String endpoint) {
    final now = DateTime.now();
    
    if (_lastRequestTimes.containsKey(endpoint)) {
      final lastRequestTime = _lastRequestTimes[endpoint]!;
      final timeSinceLastRequest = now.difference(lastRequestTime);
      
      if (timeSinceLastRequest < _minRequestInterval) {
        return false;
      }
    }
    
    _lastRequestTimes[endpoint] = now;
    return true;
  }
  
  // Add authentication headers
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': await _deviceCompatibilityManager.getAppVersion(),
      'X-Device-Info': await _deviceCompatibilityManager.getDeviceInfo(),
    };
    
    if (await refreshTokenIfNeeded() && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    // Add security headers
    final securityHeaders = await _securityUtils.generateApiSecurityHeaders();
    headers.addAll(securityHeaders);
    
    return headers;
  }
  
  // Execute HTTP request with retry logic
  Future<http.Response> _executeRequest(
    Future<http.Response> Function() requestFunction,
    String endpoint,
  ) async {
    if (!_checkRateLimit(endpoint)) {
      throw ApiException(
        'Rate limit exceeded for endpoint: $endpoint',
        429,
      );
    }
    
    int retryCount = 0;
    
    while (true) {
      try {
        return await requestFunction().timeout(_timeoutDuration);
      } catch (e) {
        retryCount++;
        
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        
        // Check if we should retry based on the error
        final shouldRetry = _shouldRetryRequest(e);
        if (!shouldRetry) {
          rethrow;
        }
        
        // Exponential backoff
        final delay = _retryDelay * retryCount;
        await Future.delayed(delay);
      }
    }
  }
  
  // Determine if request should be retried
  bool _shouldRetryRequest(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    
    if (error is http.ClientException) {
      return true;
    }
    
    if (error is ApiException) {
      // Retry on server errors (5xx) but not on client errors (4xx)
      return error.statusCode >= 500 && error.statusCode < 600;
    }
    
    return false;
  }
  
  // Process API response
  Future<dynamic> _processResponse(http.Response response, String endpoint) async {
    final statusCode = response.statusCode;
    
    // Log API call for performance monitoring
    _performanceOptimizer.logApiCall(
      endpoint,
      statusCode,
      response.contentLength ?? 0,
      DateTime.now(),
    );
    
    if (statusCode >= 200 && statusCode < 300) {
      // Success response
      if (response.body.isEmpty) {
        return null;
      }
      
      try {
        return json.decode(response.body);
      } catch (e) {
        _errorHandler.handleError(
          e,
          'Failed to parse API response for endpoint: $endpoint',
          ErrorSeverity.medium,
        );
        return response.body;
      }
    } else if (statusCode == 401) {
      // Unauthorized - clear token and throw exception
      await clearAuthToken();
      throw ApiException(
        'Unauthorized access. Please log in again.',
        statusCode,
      );
    } else {
      // Error response
      String errorMessage = 'API request failed with status code: $statusCode';
      
      try {
        final errorBody = json.decode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        } else if (errorBody['error'] != null) {
          errorMessage = errorBody['error'];
        }
      } catch (e) {
        // Ignore parsing errors for error responses
      }
      
      throw ApiException(errorMessage, statusCode);
    }
  }
  
  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = false,
    Duration? cacheDuration,
    bool requiresAuth = true,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      if (useCache) {
        // Try to get from cache if offline
        final cacheKey = _generateCacheKey('$baseUrl$endpoint', queryParams, null);
        final cachedResponse = _responseCache[cacheKey];
        
        if (cachedResponse != null && !cachedResponse.isExpired()) {
          return cachedResponse.data;
        }
      }
      
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Build URL with query parameters
    var uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value.toString())
      ));
    }
    
    // Check cache first if enabled
    if (useCache) {
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', queryParams, null);
      final cachedResponse = _responseCache[cacheKey];
      
      if (cachedResponse != null && !cachedResponse.isExpired()) {
        return cachedResponse.data;
      }
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => http.get(uri, headers: headers),
        endpoint,
      );
      
      final processedResponse = await _processResponse(response, endpoint);
      
      // Cache response if enabled
      if (useCache) {
        final cacheKey = _generateCacheKey('$baseUrl$endpoint', queryParams, null);
        _responseCache[cacheKey] = CachedResponse(
          processedResponse,
          DateTime.now().add(cacheDuration ?? _defaultCacheDuration),
        );
      }
      
      return processedResponse;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'GET request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'POST request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'PUT request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'DELETE request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'PATCH request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // Upload file
  Future<dynamic> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? fields,
    bool requiresAuth = true,
    Function(int, int)? onProgress,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Accept': 'application/json',
          };
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add file
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);
      
      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Send request with progress tracking
      final response = await _executeMultipartRequest(request, endpoint, onProgress);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'File upload failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // Execute multipart request with progress tracking
  Future<http.Response> _executeMultipartRequest(
    http.MultipartRequest request,
    String endpoint,
    Function(int, int)? onProgress,
  ) async {
    try {
      final streamedResponse = await request.send();
      
      if (onProgress != null) {
        final contentLength = streamedResponse.contentLength ?? 0;
        int bytesReceived = 0;
        
        final stream = streamedResponse.stream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              bytesReceived += data.length;
              onProgress(bytesReceived, contentLength);
              sink.add(data);
            },
          ),
        );
        
        final response = await http.Response.fromStream(streamedResponse);
        return response;
      } else {
        final response = await http.Response.fromStream(streamedResponse);
        return response;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Multipart request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // Download file
  Future<String> downloadFile(
    String endpoint,
    String destinationPath, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    Function(int, int)? onProgress,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    // Build URL with query parameters
    var uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value.toString())
      ));
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Accept': '*/*',
          };
    
    try {
      final request = http.Request('GET', uri);
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final file = File(destinationPath);
        final sink = file.openWrite();
        
        final contentLength = streamedResponse.contentLength ?? 0;
        int bytesReceived = 0;
        
        await streamedResponse.stream.forEach((data) {
          bytesReceived += data.length;
          if (onProgress != null) {
            onProgress(bytesReceived, contentLength);
          }
          sink.add(data);
        });
        
        await sink.close();
        return destinationPath;
      } else {
        final response = await http.Response.fromStream(streamedResponse);
        await _processResponse(response, endpoint);
        throw ApiException(
          'Failed to download file with status code: ${streamedResponse.statusCode}',
          streamedResponse.statusCode,
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'File download failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  // WebSocket connection
  Stream<dynamic>? connectWebSocket(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, dynamic>? queryParams,
  }) async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
      );
    }
    
    try {
      // Build URL with query parameters
      var uri = Uri.parse('$baseUrl$endpoint'.replaceFirst('https://', 'wss://'));
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString())
        ));
      }
      
      // Add authentication token if required
      if (requiresAuth && await refreshTokenIfNeeded() && _authToken != null) {
        final updatedQueryParams = Map<String, String>.from(uri.queryParameters);
        updatedQueryParams['token'] = _authToken!;
        uri = uri.replace(queryParameters: updatedQueryParams);
      }
      
      // Connect to WebSocket
      final webSocket = await WebSocket.connect(uri.toString());
      
      // Transform WebSocket messages to JSON
      final stream = webSocket.map((message) {
        try {
          return json.decode(message);
        } catch (e) {
          return message;
        }
      });
      
      return stream;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'WebSocket connection failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
}

// API Exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

// Cached response class
class CachedResponse {
  final dynamic data;
  final DateTime expiryTime;
  
  CachedResponse(this.data, this.expiryTime);
  
  bool isExpired() {
    return DateTime.now().isAfter(expiryTime);
  }
}

// WebSocket class (simplified for this implementation)
class WebSocket {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  
  static Future<WebSocket> connect(String url) async {
    final socket = WebSocket();
    // In a real implementation, this would connect to the actual WebSocket
    // For this example, we're just returning a mock WebSocket
    return socket;
  }
  
  Stream<dynamic> map(Function(dynamic) transform) {
    return _controller.stream.map(transform);
  }
  
  void send(dynamic data) {
    // In a real implementation, this would send data to the actual WebSocket
  }
  
  void close() {
    _controller.close();
  }
}
