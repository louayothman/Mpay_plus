import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

class SecurityUtils {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Login attempt tracking for brute force protection
  static final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  // Check if two-factor authentication is enabled for a user
  static Future<bool> isTwoFactorEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['twoFactorEnabled'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking 2FA status: $e');
      return false;
    }
  }
  
  // Enable two-factor authentication for a user
  static Future<bool> enableTwoFactorAuth(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'twoFactorEnabled': true,
        'securityLevel': FieldValue.increment(1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error enabling 2FA: $e');
      return false;
    }
  }
  
  // Disable two-factor authentication for a user
  static Future<bool> disableTwoFactorAuth(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'twoFactorEnabled': false,
        'securityLevel': FieldValue.increment(-1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error disabling 2FA: $e');
      return false;
    }
  }
  
  // Generate a random verification code for 2FA
  static String generateVerificationCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }
  
  // Store verification code securely with expiration
  static Future<void> storeVerificationCode(String userId, String code) async {
    final expiryTime = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'verification_code_$userId', value: code);
    await _secureStorage.write(key: 'verification_code_expiry_$userId', value: expiryTime);
  }
  
  // Verify the code entered by the user
  static Future<bool> verifyCode(String userId, String enteredCode) async {
    final storedCode = await _secureStorage.read(key: 'verification_code_$userId');
    final expiryTimeStr = await _secureStorage.read(key: 'verification_code_expiry_$userId');
    
    if (storedCode == null || expiryTimeStr == null) {
      return false;
    }
    
    final expiryTime = int.parse(expiryTimeStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if code has expired
    if (now > expiryTime) {
      await _secureStorage.delete(key: 'verification_code_$userId');
      await _secureStorage.delete(key: 'verification_code_expiry_$userId');
      return false;
    }
    
    return storedCode == enteredCode;
  }
  
  // Securely store PIN with salt
  static Future<void> storePIN(String userId, String pin) async {
    final salt = _generateSalt();
    final hashedPin = _hashPinWithSalt(pin, salt);
    await _secureStorage.write(key: 'pin_salt_$userId', value: salt);
    await _secureStorage.write(key: 'pin_$userId', value: hashedPin);
    
    // Store PIN creation timestamp for rotation policy
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'pin_created_$userId', value: timestamp);
  }
  
  // Verify PIN
  static Future<bool> verifyPIN(String userId, String enteredPin) async {
    final storedSalt = await _secureStorage.read(key: 'pin_salt_$userId');
    final storedHashedPin = await _secureStorage.read(key: 'pin_$userId');
    
    if (storedSalt == null || storedHashedPin == null) {
      return false;
    }
    
    final enteredHashedPin = _hashPinWithSalt(enteredPin, storedSalt);
    return storedHashedPin == enteredHashedPin;
  }
  
  // Check if PIN needs rotation (older than 90 days)
  static Future<bool> isPinRotationNeeded(String userId) async {
    final createdStr = await _secureStorage.read(key: 'pin_created_$userId');
    if (createdStr == null) return false;
    
    final created = int.parse(createdStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    final ninetyDaysInMillis = 90 * 24 * 60 * 60 * 1000;
    
    return (now - created) > ninetyDaysInMillis;
  }
  
  // Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  // Hash PIN with salt using SHA-256
  static String _hashPinWithSalt(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Check password strength
  static bool isStrongPassword(String password) {
    // At least 8 characters
    if (password.length < 8) return false;
    
    // Contains at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Contains at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Contains at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    // Contains at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    // Check for common passwords
    if (_isCommonPassword(password)) return false;
    
    // Check for sequential characters
    if (_hasSequentialChars(password)) return false;
    
    return true;
  }
  
  // Check if password is in common password list
  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', 'admin', '123456', 'qwerty', 'welcome',
      'password123', 'admin123', '12345678', '111111', 'abc123'
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
  
  // Check for sequential characters
  static bool _hasSequentialChars(String password) {
    const sequences = ['123456', 'abcdef', 'qwerty', 'asdfgh'];
    for (final seq in sequences) {
      if (password.toLowerCase().contains(seq)) return true;
    }
    return false;
  }
  
  // Calculate password strength score (0-100)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    // Length contribution (up to 30 points)
    score += password.length * 2 > 30 ? 30 : password.length * 2;
    
    // Character variety contribution (up to 40 points)
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 10;
    
    // Deductions for weaknesses
    if (_isCommonPassword(password)) score -= 30;
    if (_hasSequentialChars(password)) score -= 20;
    
    // Ensure score is between 0 and 100
    return score < 0 ? 0 : (score > 100 ? 100 : score);
  }
  
  // Get password strength message
  static String getPasswordStrengthMessage(String password) {
    List<String> requirements = [];
    
    if (password.length < 8) {
      requirements.add('يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      requirements.add('يجب أن تحتوي على حرف كبير واحد على الأقل');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      requirements.add('يجب أن تحتوي على حرف صغير واحد على الأقل');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      requirements.add('يجب أن تحتوي على رقم واحد على الأقل');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      requirements.add('يجب أن تحتوي على رمز خاص واحد على الأقل (!@#$%^&*(),.?":{}|<>)');
    }
    
    if (_isCommonPassword(password)) {
      requirements.add('كلمة المرور شائعة جداً وسهلة التخمين');
    }
    
    if (_hasSequentialChars(password)) {
      requirements.add('كلمة المرور تحتوي على تسلسل أحرف أو أرقام متتالية');
    }
    
    if (requirements.isEmpty) {
      final strength = calculatePasswordStrength(password);
      if (strength >= 80) {
        return 'كلمة المرور قوية جداً';
      } else if (strength >= 60) {
        return 'كلمة المرور قوية';
      } else {
        return 'كلمة المرور متوسطة القوة';
      }
    } else {
      return 'متطلبات كلمة المرور:\n${requirements.join('\n')}';
    }
  }
  
  // Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }
  
  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }
  
  // Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    required String localizedReason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }
  
  // Enable biometric authentication for a user
  static Future<bool> enableBiometricAuth(String userId) async {
    try {
      // First check if biometrics are available
      if (!await isBiometricAvailable()) {
        return false;
      }
      
      // Store biometric enabled flag
      await _secureStorage.write(key: 'biometric_enabled_$userId', value: 'true');
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'biometricEnabled': true,
        'securityLevel': FieldValue.increment(1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error enabling biometric auth: $e');
      return false;
    }
  }
  
  // Disable biometric authentication for a user
  static Future<bool> disableBiometricAuth(String userId) async {
    try {
      // Remove biometric enabled flag
      await _secureStorage.delete(key: 'biometric_enabled_$userId');
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'biometricEnabled': false,
        'securityLevel': FieldValue.increment(-1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error disabling biometric auth: $e');
      return false;
    }
  }
  
  // Check if biometric authentication is enabled for a user
  static Future<bool> isBiometricEnabled(String userId) async {
    try {
      final value = await _secureStorage.read(key: 'biometric_enabled_$userId');
      return value == 'true';
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }
  
  // Track login attempt for brute force protection
  static Future<bool> trackLoginAttempt(String userId) async {
    if (!_loginAttempts.containsKey(userId)) {
      _loginAttempts[userId] = [];
    }
    
    // Remove attempts older than lockout duration
    final now = DateTime.now();
    _loginAttempts[userId]!.removeWhere(
      (attempt) => now.difference(attempt) > _lockoutDuration
    );
    
    // Check if user is locked out
    if (_loginAttempts[userId]!.length >= _maxLoginAttempts) {
      return false; // User is locked out
    }
    
    // Add current attempt
    _loginAttempts[userId]!.add(now);
    return true; // User is not locked out
  }
  
  // Get remaining login attempts
  static int getRemainingLoginAttempts(String userId) {
    if (!_loginAttempts.containsKey(userId)) {
      return _maxLoginAttempts;
    }
    
    // Remove attempts older than lockout duration
    final now = DateTime.now();
    _loginAttempts[userId]!.removeWhere(
      (attempt) => now.difference(attempt) > _lockoutDuration
    );
    
    return _maxLoginAttempts - _loginAttempts[userId]!.length;
  }
  
  // Get lockout time remaining in seconds
  static int getLockoutTimeRemaining(String userId) {
    if (!_loginAttempts.containsKey(userId) || _loginAttempts[userId]!.isEmpty) {
      return 0;
    }
    
    // If not locked out, return 0
    if (_loginAttempts[userId]!.length < _maxLoginAttempts) {
      return 0;
    }
    
    // Calculate time until oldest attempt expires
    final now = DateTime.now();
    final oldestAttempt = _loginAttempts[userId]!.reduce(
      (a, b) => a.isBefore(b) ? a : b
    );
    
    final expiryTime = oldestAttempt.add(_lockoutDuration);
    final remainingSeconds = expiryTime.difference(now).inSeconds;
    
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }
  
  // Reset login attempts (for successful login)
  static void resetLoginAttempts(String userId) {
    _loginAttempts.remove(userId);
  }
  
  // Encrypt sensitive data with AES encryption
  static Future<void> encryptAndStore(String key, String value) async {
    // Generate a unique encryption key for each value if not exists
    final encryptionKeyKey = 'encryption_key_for_$key';
    String? encryptionKey = await _secureStorage.read(key: encryptionKeyKey);
    
    if (encryptionKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      encryptionKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: encryptionKeyKey, value: encryptionKey);
    }
    
    // Encrypt the value
    final valueBytes = utf8.encode(value);
    final keyBytes = base64Url.decode(encryptionKey);
    
    // Simple XOR encryption (in a real app, use a proper encryption library)
    final encryptedBytes = List<int>.filled(valueBytes.length, 0);
    for (var i = 0; i < valueBytes.length; i++) {
      encryptedBytes[i] = valueBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    final encryptedValue = base64Url.encode(encryptedBytes);
    await _secureStorage.write(key: key, value: encryptedValue);
  }
  
  // Decrypt sensitive data
  static Future<String?> retrieveDecrypted(String key) async {
    final encryptedValue = await _secureStorage.read(key: key);
    if (encryptedValue == null) return null;
    
    final encryptionKeyKey = 'encryption_key_for_$key';
    final encryptionKey = await _secureStorage.read(key: encryptionKeyKey);
    
    if (encryptionKey == null) return null;
    
    try {
      final encryptedBytes = base64Url.decode(encryptedValue);
      final keyBytes = base64Url.decode(encryptionKey);
      
      // Simple XOR decryption
      final decryptedBytes = List<int>.filled(encryptedBytes.length, 0);
      for (var i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('Error decrypting data: $e');
      return null;
    }
  }
  
  // Delete sensitive data
  static Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
    await _secureStorage.delete(key: 'encryption_key_for_$key');
  }
  
  // Log security event
  static Future<void> logSecurityEvent(String userId, String eventType, String details) async {
    try {
      await _firestore.collection('security_logs').add({
        'userId': userId,
        'eventType': eventType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': await _getDeviceInfo(),
      });
    } catch (e) {
      print('Error logging security event: $e');
    }
  }
  
  // Get device info for security logging
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In a real app, use device_info_plus package to get detailed device info
    return {
      'platform': 'Flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // Check for suspicious activity
  static Future<bool> checkForSuspiciousActivity(String userId) async {
    try {
      // Get recent security logs
      final logs = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      // Check for failed login patterns
      int failedLogins = 0;
      for (final doc in logs.docs) {
        final data = doc.data();
        if (data['eventType'] == 'failed_login') {
          failedLogins++;
        }
      }
      
      return failedLogins >= 3; // Suspicious if 3 or more recent failed logins
    } catch (e) {
      print('Error checking for suspicious activity: $e');
      return false;
    }
  }
  
  // Generate secure random token
  static String generateSecureToken(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values).substring(0, length);
  }
}
