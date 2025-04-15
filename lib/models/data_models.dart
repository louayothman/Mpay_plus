// نماذج البيانات والخدمات الأساسية لتطبيق Mpay

// نموذج المستخدم
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isVerified;
  final String level;
  final double totalTransactions;
  final String referralCode;
  final String referredBy;
  final int referralCount;
  final String fcmToken;
  final bool isAdmin;
  final List<String> adminPermissions;
  final String profilePicture;
  final Map<String, double> dailyLimits;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.lastLogin,
    required this.isVerified,
    required this.level,
    required this.totalTransactions,
    required this.referralCode,
    this.referredBy = '',
    this.referralCount = 0,
    this.fcmToken = '',
    this.isAdmin = false,
    this.adminPermissions = const [],
    this.profilePicture = '',
    required this.dailyLimits,
  });

  // تحويل من Firestore
  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      level: data['level'] ?? 'bronze',
      totalTransactions: data['totalTransactions']?.toDouble() ?? 0.0,
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'] ?? '',
      referralCount: data['referralCount'] ?? 0,
      fcmToken: data['fcmToken'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      adminPermissions: List<String>.from(data['adminPermissions'] ?? []),
      profilePicture: data['profilePicture'] ?? '',
      dailyLimits: Map<String, double>.from(data['dailyLimits'] ?? {}),
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isVerified': isVerified,
      'level': level,
      'totalTransactions': totalTransactions,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'fcmToken': fcmToken,
      'isAdmin': isAdmin,
      'adminPermissions': adminPermissions,
      'profilePicture': profilePicture,
      'dailyLimits': dailyLimits,
    };
  }
}

// نموذج المحفظة
class Wallet {
  final String walletId;
  final Map<String, double> balances;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.walletId,
    required this.balances,
    required this.createdAt,
    required this.updatedAt,
  });

  // تحويل من Firestore
  factory Wallet.fromFirestore(Map<String, dynamic> data, String id) {
    return Wallet(
      walletId: id,
      balances: Map<String, double>.from(data['balances'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'walletId': walletId,
      'balances': balances,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// نموذج المعاملة
class Transaction {
  final String id;
  final String type;
  final String senderId;
  final String receiverId;
  final double amount;
  final String currency;
  final double fee;
  final double discount;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String notes;
  final String referenceId;

  Transaction({
    required this.id,
    required this.type,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.currency,
    required this.fee,
    required this.discount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes = '',
    this.referenceId = '',
  });

  // تحويل من Firestore
  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      type: data['type'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      currency: data['currency'] ?? '',
      fee: data['fee']?.toDouble() ?? 0.0,
      discount: data['discount']?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      notes: data['notes'] ?? '',
      referenceId: data['referenceId'] ?? '',
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'currency': currency,
      'fee': fee,
      'discount': discount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'referenceId': referenceId,
    };
  }
}

// نموذج المبادلة
class Exchange {
  final String id;
  final String userId;
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double exchangeRate;
  final double fee;
  final double discount;
  final DateTime createdAt;
  final String status;

  Exchange({
    required this.id,
    required this.userId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.exchangeRate,
    required this.fee,
    required this.discount,
    required this.createdAt,
    required this.status,
  });

  // تحويل من Firestore
  factory Exchange.fromFirestore(Map<String, dynamic> data, String id) {
    return Exchange(
      id: id,
      userId: data['userId'] ?? '',
      fromCurrency: data['fromCurrency'] ?? '',
      toCurrency: data['toCurrency'] ?? '',
      fromAmount: data['fromAmount']?.toDouble() ?? 0.0,
      toAmount: data['toAmount']?.toDouble() ?? 0.0,
      exchangeRate: data['exchangeRate']?.toDouble() ?? 0.0,
      fee: data['fee']?.toDouble() ?? 0.0,
      discount: data['discount']?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? '',
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'fromAmount': fromAmount,
      'toAmount': toAmount,
      'exchangeRate': exchangeRate,
      'fee': fee,
      'discount': discount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

// نموذج الصفقة
class Deal {
  final String id;
  final String creatorId;
  final String type;
  final String currency;
  final double amount;
  final double exchangeRate;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Offer> offers;

  Deal({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.currency,
    required this.amount,
    required this.exchangeRate,
    this.notes = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.offers = const [],
  });

  // تحويل من Firestore
  factory Deal.fromFirestore(Map<String, dynamic> data, String id) {
    List<Offer> offersList = [];
    if (data['offers'] != null) {
      for (var offer in data['offers']) {
        offersList.add(Offer.fromMap(offer));
      }
    }

    return Deal(
      id: id,
      creatorId: data['creatorId'] ?? '',
      type: data['type'] ?? '',
      currency: data['currency'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      exchangeRate: data['exchangeRate']?.toDouble() ?? 0.0,
      notes: data['notes'] ?? '',
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      offers: offersList,
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    List<Map<String, dynamic>> offersList = [];
    for (var offer in offers) {
      offersList.add(offer.toMap());
    }

    return {
      'creatorId': creatorId,
      'type': type,
      'currency': currency,
      'amount': amount,
      'exchangeRate': exchangeRate,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'offers': offersList,
    };
  }
}

// نموذج العرض
class Offer {
  final String userId;
  final double amount;
  final String status;
  final DateTime createdAt;

  Offer({
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  // تحويل من Map
  factory Offer.fromMap(Map<String, dynamic> data) {
    return Offer(
      userId: data['userId'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// نموذج التقييم
class Rating {
  final String id;
  final String dealId;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.dealId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  // تحويل من Firestore
  factory Rating.fromFirestore(Map<String, dynamic> data, String id) {
    return Rating(
      id: id,
      dealId: data['dealId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'dealId': dealId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// نموذج الإيداع/السحب
class DepositWithdrawal {
  final String id;
  final String userId;
  final String type;
  final String method;
  final double amount;
  final String currency;
  final double fee;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String adminId;
  final String notes;
  final String screenshotUrl;
  final String destinationAddress;

  DepositWithdrawal({
    required this.id,
    required this.userId,
    required this.type,
    required this.method,
    required this.amount,
    required this.currency,
    this.fee = 0.0,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.adminId = '',
    this.notes = '',
    this.screenshotUrl = '',
    this.destinationAddress = '',
  });

  // تحويل من Firestore
  factory DepositWithdrawal.fromFirestore(Map<String, dynamic> data, String id) {
    return DepositWithdrawal(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      method: data['method'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      currency: data['currency'] ?? '',
      fee: data['fee']?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      adminId: data['adminId'] ?? '',
      notes: data['notes'] ?? '',
      screenshotUrl: data['screenshotUrl'] ?? '',
      destinationAddress: data['destinationAddress'] ?? '',
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'method': method,
      'amount': amount,
      'currency': currency,
      'fee': fee,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'adminId': adminId,
      'notes': notes,
      'screenshotUrl': screenshotUrl,
      'destinationAddress': destinationAddress,
    };
  }
}

// نموذج الإشعار
class Notification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.data = const {},
  });

  // تحويل من Firestore
  factory Notification.fromFirestore(Map<String, dynamic> data, String id) {
    return Notification(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      data: data['data'] ?? {},
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }
}

// نموذج تذكرة الدعم
class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  // تحويل من Firestore
  factory SupportTicket.fromFirestore(Map<String, dynamic> data, String id) {
    List<TicketMessage> messagesList = [];
    if (data['messages'] != null) {
      for (var message in data['messages']) {
        messagesList.add(TicketMessage.fromMap(message));
      }
    }

    return SupportTicket(
      id: id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      status: data['status'] ?? '',
      priority: data['priority'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      messages: messagesList,
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    List<Map<String, dynamic>> messagesList = [];
    for (var message in messages) {
      messagesList.add(message.toMap());
    }

    return {
      'userId': userId,
      'subject': subject,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messages': messagesList,
    };
  }
}

// نموذج رسالة التذكرة
class TicketMessage {
  final String senderId;
  final String message;
  final String attachmentUrl;
  final DateTime createdAt;

  TicketMessage({
    required this.senderId,
    required this.message,
    this.attachmentUrl = '',
    required this.createdAt,
  });

  // تحويل من Map
  factory TicketMessage.fromMap(Map<String, dynamic> data) {
    return TicketMessage(
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      attachmentUrl: data['attachmentUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// نموذج إعدادات النظام
class SystemSettings {
  final Map<String, double> exchangeRates;
  final Map<String, double> commissionRates;
  final Map<String, double> levelDiscounts;
  final Map<String, dynamic> levelRequirements;
  final Map<String, dynamic> dailyLimits;
  final Map<String, String> depositAddresses;
  final DateTime updatedAt;

  SystemSettings({
    required this.exchangeRates,
    required this.commissionRates,
    required this.levelDiscounts,
    required this.levelRequirements,
    required this.dailyLimits,
    required this.depositAddresses,
    required this.updatedAt,
  });

  // تحويل من Firestore
  factory SystemSettings.fromFirestore(Map<String, dynamic> data) {
    return SystemSettings(
      exchangeRates: Map<String, double>.from(data['exchangeRates'] ?? {}),
      commissionRates: Map<String, double>.from(data['commissionRates'] ?? {}),
      levelDiscounts: Map<String, double>.from(data['levelDiscounts'] ?? {}),
      levelRequirements: data['levelRequirements'] ?? {},
      dailyLimits: data['dailyLimits'] ?? {},
      depositAddresses: Map<String, String>.from(data['depositAddresses'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'exchangeRates': exchangeRates,
      'commissionRates': commissionRates,
      'levelDiscounts': levelDiscounts,
      'levelRequirements': levelRequirements,
      'dailyLimits': dailyLimits,
      'depositAddresses': depositAddresses,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// الخدمات الأساسية

// خدمة المصادقة
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser != null ? null : null; // سيتم تنفيذه لاحقًا

  // تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e;
    }
  }

  // إنشاء حساب جديد بالبريد الإلكتروني وكلمة المرور
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String referralCode,
  ) async {
    try {
      // إنشاء المستخدم في Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // إنشاء رمز إحالة فريد
      String newReferralCode = _generateReferralCode();

      // التحقق من رمز الإحالة إذا تم تقديمه
      String referredBy = '';
      if (referralCode.isNotEmpty) {
        // البحث عن المستخدم بواسطة رمز الإحالة
        QuerySnapshot referrerQuery = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: referralCode)
            .limit(1)
            .get();

        if (referrerQuery.docs.isNotEmpty) {
          referredBy = referrerQuery.docs.first.id;
          // تحديث عدد المدعوين للمستخدم المُحيل
          await _firestore.collection('users').doc(referredBy).update({
            'referralCount': FieldValue.increment(1),
          });
        }
      }

      // إنشاء المستخدم في Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'isVerified': false,
        'level': 'bronze',
        'totalTransactions': 0.0,
        'referralCode': newReferralCode,
        'referredBy': referredBy,
        'referralCount': 0,
        'fcmToken': '',
        'isAdmin': false,
        'adminPermissions': [],
        'profilePicture': '',
        'dailyLimits': {
          'USD': 50.0,
          'SYP': 500000.0,
          'EUR': 45.0,
          'SAR': 187.5,
          'AED': 183.5,
          'TRY': 1600.0,
        },
      });

      // إنشاء محفظة للمستخدم
      await _firestore.collection('wallets').doc(userCredential.user!.uid).set({
        'walletId': userCredential.user!.uid,
        'balances': {
          'USD': 0.0,
          'SYP': 0.0,
          'EUR': 0.0,
          'SAR': 0.0,
          'AED': 0.0,
          'TRY': 0.0,
        },
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  // تسجيل الدخول عبر Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // سيتم تنفيذه لاحقًا
      throw UnimplementedError('لم يتم تنفيذ تسجيل الدخول عبر Google بعد');
    } catch (e) {
      throw e;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw e;
    }
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }

  // التحقق من رمز PIN
  Future<bool> verifyPIN(String pin) async {
    try {
      // سيتم تنفيذه لاحقًا
      return true;
    } catch (e) {
      throw e;
    }
  }

  // إنشاء رمز PIN
  Future<void> createPIN(String pin) async {
    try {
      // سيتم تنفيذه لاحقًا
    } catch (e) {
      throw e;
    }
  }

  // توليد رمز إحالة فريد
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}

// خدمة المحفظة
class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على محفظة المستخدم
  Future<Wallet> getUserWallet(String userId) async {
    try {
      DocumentSnapshot walletDoc = await _firestore.collection('wallets').doc(userId).get();
      
      if (walletDoc.exists) {
        return Wallet.fromFirestore(walletDoc.data() as Map<String, dynamic>, walletDoc.id);
      } else {
        throw Exception('المحفظة غير موجودة');
      }
    } catch (e) {
      throw e;
    }
  }

  // تحديث رصيد المحفظة
  Future<void> updateWalletBalance(String userId, String currency, double amount) async {
    try {
      await _firestore.collection('wallets').doc(userId).update({
        'balances.$currency': FieldValue.increment(amount),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // التحقق من كفاية الرصيد
  Future<bool> checkSufficientBalance(String userId, String currency, double amount) async {
    try {
      Wallet wallet = await getUserWallet(userId);
      return (wallet.balances[currency] ?? 0) >= amount;
    } catch (e) {
      throw e;
    }
  }

  // التحقق من الحد اليومي
  Future<bool> checkDailyLimit(String userId, String currency, double amount) async {
    try {
      // الحصول على معلومات المستخدم
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('المستخدم غير موجود');
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> dailyLimits = userData['dailyLimits'] ?? {};
      
      // الحصول على إجمالي المعاملات اليومية
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      
      QuerySnapshot transactions = await _firestore
          .collection('transactions')
          .where('senderId', isEqualTo: userId)
          .where('currency', isEqualTo: currency)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      
      double dailyTotal = 0;
      for (var doc in transactions.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        dailyTotal += data['amount']?.toDouble() ?? 0.0;
      }
      
      // التحقق من الحد اليومي
      double limit = dailyLimits[currency]?.toDouble() ?? 0.0;
      return (dailyTotal + amount) <= limit;
    } catch (e) {
      throw e;
    }
  }
}

// خدمة المعاملات
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

  // إنشاء معاملة جديدة
  Future<String> createTransaction({
    required String type,
    required String senderId,
    required String receiverId,
    required double amount,
    required String currency,
    required double fee,
    required double discount,
    String notes = '',
    String referenceId = '',
  }) async {
    try {
      // التحقق من كفاية الرصيد
      bool hasSufficientBalance = await _walletService.checkSufficientBalance(
        senderId,
        currency,
        amount + fee - discount,
      );
      
      if (!hasSufficientBalance) {
        throw Exception('رصيد غير كافٍ');
      }
      
      // التحقق من الحد اليومي
      bool withinDailyLimit = await _walletService.checkDailyLimit(
        senderId,
        currency,
        amount,
      );
      
      if (!withinDailyLimit) {
        throw Exception('تجاوز الحد اليومي');
      }
      
      // إنشاء المعاملة
      DocumentReference transactionRef = await _firestore.collection('transactions').add({
        'type': type,
        'senderId': senderId,
        'receiverId': receiverId,
        'amount': amount,
        'currency': currency,
        'fee': fee,
        'discount': discount,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'completedAt': null,
        'notes': notes,
        'referenceId': referenceId,
      });
      
      // تحديث أرصدة المحافظ
      await _walletService.updateWalletBalance(
        senderId,
        currency,
        -(amount + fee - discount),
      );
      
      await _walletService.updateWalletBalance(
        receiverId,
        currency,
        amount,
      );
      
      // تحديث حالة المعاملة
      await _firestore.collection('transactions').doc(transactionRef.id).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
      
      // تحديث إجمالي قيمة المعاملات للمستخدم
      await _updateUserTransactionTotal(senderId, amount, currency);
      
      return transactionRef.id;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على معاملات المستخدم
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      QuerySnapshot sentTransactions = await _firestore
          .collection('transactions')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      QuerySnapshot receivedTransactions = await _firestore
          .collection('transactions')
          .where('receiverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Transaction> transactions = [];
      
      for (var doc in sentTransactions.docs) {
        transactions.add(Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      for (var doc in receivedTransactions.docs) {
        transactions.add(Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      // ترتيب المعاملات حسب التاريخ
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return transactions;
    } catch (e) {
      throw e;
    }
  }

  // تحديث إجمالي قيمة المعاملات للمستخدم
  Future<void> _updateUserTransactionTotal(String userId, double amount, String currency) async {
    try {
      // الحصول على سعر الصرف إلى الليرة السورية
      DocumentSnapshot settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (!settingsDoc.exists) {
        throw Exception('إعدادات النظام غير موجودة');
      }
      
      Map<String, dynamic> settings = settingsDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> exchangeRates = settings['exchangeRates'] ?? {};
      
      double sypAmount = amount;
      
      // تحويل المبلغ إلى الليرة السورية إذا كانت العملة مختلفة
      if (currency != 'SYP') {
        double rate = exchangeRates['${currency}_SYP']?.toDouble() ?? 0.0;
        sypAmount = amount * rate;
      }
      
      // تحديث إجمالي قيمة المعاملات
      await _firestore.collection('users').doc(userId).update({
        'totalTransactions': FieldValue.increment(sypAmount),
      });
      
      // التحقق من ترقية المستوى
      await _checkLevelUpgrade(userId);
    } catch (e) {
      throw e;
    }
  }

  // التحقق من ترقية المستوى
  Future<void> _checkLevelUpgrade(String userId) async {
    try {
      // الحصول على معلومات المستخدم
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('المستخدم غير موجود');
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      double totalTransactions = userData['totalTransactions']?.toDouble() ?? 0.0;
      bool isVerified = userData['isVerified'] ?? false;
      String currentLevel = userData['level'] ?? 'bronze';
      
      // الحصول على متطلبات المستويات
      DocumentSnapshot settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (!settingsDoc.exists) {
        throw Exception('إعدادات النظام غير موجودة');
      }
      
      Map<String, dynamic> settings = settingsDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> levelRequirements = settings['levelRequirements'] ?? {};
      
      // تحديد المستوى الجديد
      String newLevel = currentLevel;
      
      if (isVerified) {
        if (totalTransactions >= levelRequirements['vip']['transactionVolume']) {
          newLevel = 'vip';
        } else if (totalTransactions >= levelRequirements['diamond']['transactionVolume']) {
          newLevel = 'diamond';
        } else if (totalTransactions >= levelRequirements['gold']['transactionVolume']) {
          newLevel = 'gold';
        } else {
          newLevel = 'silver';
        }
      } else {
        newLevel = 'bronze';
      }
      
      // تحديث المستوى إذا تغير
      if (newLevel != currentLevel) {
        await _firestore.collection('users').doc(userId).update({
          'level': newLevel,
        });
        
        // إنشاء إشعار بترقية المستوى
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'level',
          'title': 'ترقية المستوى',
          'message': 'تمت ترقية مستواك إلى $newLevel',
          'isRead': false,
          'createdAt': Timestamp.now(),
          'data': {
            'level': newLevel,
          },
        });
      }
    } catch (e) {
      throw e;
    }
  }
}

// خدمة المبادلة
class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  // إنشاء عملية مبادلة جديدة
  Future<String> createExchange({
    required String userId,
    required String fromCurrency,
    required String toCurrency,
    required double fromAmount,
  }) async {
    try {
      // الحصول على أسعار الصرف
      DocumentSnapshot settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (!settingsDoc.exists) {
        throw Exception('إعدادات النظام غير موجودة');
      }
      
      Map<String, dynamic> settings = settingsDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> exchangeRates = settings['exchangeRates'] ?? {};
      Map<String, dynamic> commissionRates = settings['commissionRates'] ?? {};
      
      // الحصول على سعر الصرف
      double exchangeRate = exchangeRates['${fromCurrency}_${toCurrency}']?.toDouble() ?? 0.0;
      
      if (exchangeRate == 0.0) {
        throw Exception('سعر الصرف غير متوفر');
      }
      
      // حساب المبلغ بعد التحويل
      double toAmount = fromAmount * exchangeRate;
      
      // حساب العمولة
      double commissionRate = commissionRates['exchange']?.toDouble() ?? 0.05;
      double fee = fromAmount * commissionRate;
      
      // الحصول على معلومات المستخدم للخصم
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('المستخدم غير موجود');
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String level = userData['level'] ?? 'bronze';
      
      // الحصول على نسبة الخصم
      Map<String, dynamic> levelDiscounts = settings['levelDiscounts'] ?? {};
      double discountRate = levelDiscounts[level]?.toDouble() ?? 0.0;
      double discount = fee * discountRate;
      
      // التحقق من كفاية الرصيد
      bool hasSufficientBalance = await _walletService.checkSufficientBalance(
        userId,
        fromCurrency,
        fromAmount + fee - discount,
      );
      
      if (!hasSufficientBalance) {
        throw Exception('رصيد غير كافٍ');
      }
      
      // إنشاء عملية المبادلة
      DocumentReference exchangeRef = await _firestore.collection('exchanges').add({
        'userId': userId,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'fromAmount': fromAmount,
        'toAmount': toAmount,
        'exchangeRate': exchangeRate,
        'fee': fee,
        'discount': discount,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });
      
      // تحديث أرصدة المحفظة
      await _walletService.updateWalletBalance(
        userId,
        fromCurrency,
        -(fromAmount + fee - discount),
      );
      
      await _walletService.updateWalletBalance(
        userId,
        toCurrency,
        toAmount,
      );
      
      // تحديث حالة المبادلة
      await _firestore.collection('exchanges').doc(exchangeRef.id).update({
        'status': 'completed',
      });
      
      // إنشاء معاملة للمبادلة
      await _transactionService.createTransaction(
        type: 'exchange',
        senderId: userId,
        receiverId: userId,
        amount: fromAmount,
        currency: fromCurrency,
        fee: fee,
        discount: discount,
        notes: 'تحويل من $fromCurrency إلى $toCurrency',
        referenceId: exchangeRef.id,
      );
      
      return exchangeRef.id;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على عمليات المبادلة للمستخدم
  Future<List<Exchange>> getUserExchanges(String userId) async {
    try {
      QuerySnapshot exchangeQuery = await _firestore
          .collection('exchanges')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Exchange> exchanges = [];
      
      for (var doc in exchangeQuery.docs) {
        exchanges.add(Exchange.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return exchanges;
    } catch (e) {
      throw e;
    }
  }
}

// خدمة الصفقات
class DealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إنشاء إعلان جديد
  Future<String> createDeal({
    required String creatorId,
    required String type,
    required String currency,
    required double amount,
    required double exchangeRate,
    String notes = '',
  }) async {
    try {
      DocumentReference dealRef = await _firestore.collection('deals').add({
        'creatorId': creatorId,
        'type': type,
        'currency': currency,
        'amount': amount,
        'exchangeRate': exchangeRate,
        'notes': notes,
        'status': 'open',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'offers': [],
      });
      
      return dealRef.id;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على الإعلانات المفتوحة
  Future<List<Deal>> getOpenDeals() async {
    try {
      QuerySnapshot dealQuery = await _firestore
          .collection('deals')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Deal> deals = [];
      
      for (var doc in dealQuery.docs) {
        deals.add(Deal.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return deals;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على إعلانات المستخدم
  Future<List<Deal>> getUserDeals(String userId) async {
    try {
      QuerySnapshot dealQuery = await _firestore
          .collection('deals')
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Deal> deals = [];
      
      for (var doc in dealQuery.docs) {
        deals.add(Deal.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return deals;
    } catch (e) {
      throw e;
    }
  }

  // تقديم عرض على إعلان
  Future<void> makeOffer(String dealId, String userId, double amount) async {
    try {
      DocumentSnapshot dealDoc = await _firestore.collection('deals').doc(dealId).get();
      
      if (!dealDoc.exists) {
        throw Exception('الإعلان غير موجود');
      }
      
      Map<String, dynamic> dealData = dealDoc.data() as Map<String, dynamic>;
      
      if (dealData['status'] != 'open') {
        throw Exception('الإعلان غير مفتوح');
      }
      
      if (dealData['creatorId'] == userId) {
        throw Exception('لا يمكنك تقديم عرض على إعلانك الخاص');
      }
      
      // إضافة العرض
      await _firestore.collection('deals').doc(dealId).update({
        'offers': FieldValue.arrayUnion([
          {
            'userId': userId,
            'amount': amount,
            'status': 'pending',
            'createdAt': Timestamp.now(),
          }
        ]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // قبول عرض
  Future<void> acceptOffer(String dealId, String offerUserId) async {
    try {
      DocumentSnapshot dealDoc = await _firestore.collection('deals').doc(dealId).get();
      
      if (!dealDoc.exists) {
        throw Exception('الإعلان غير موجود');
      }
      
      Map<String, dynamic> dealData = dealDoc.data() as Map<String, dynamic>;
      
      if (dealData['status'] != 'open') {
        throw Exception('الإعلان غير مفتوح');
      }
      
      if (dealData['creatorId'] != FirebaseAuth.instance.currentUser!.uid) {
        throw Exception('ليس لديك صلاحية قبول العروض');
      }
      
      List<dynamic> offers = dealData['offers'] ?? [];
      List<dynamic> updatedOffers = [];
      bool offerFound = false;
      
      for (var offer in offers) {
        if (offer['userId'] == offerUserId) {
          updatedOffers.add({
            'userId': offer['userId'],
            'amount': offer['amount'],
            'status': 'accepted',
            'createdAt': offer['createdAt'],
          });
          offerFound = true;
        } else {
          updatedOffers.add({
            'userId': offer['userId'],
            'amount': offer['amount'],
            'status': 'rejected',
            'createdAt': offer['createdAt'],
          });
        }
      }
      
      if (!offerFound) {
        throw Exception('العرض غير موجود');
      }
      
      // تحديث الإعلان
      await _firestore.collection('deals').doc(dealId).update({
        'status': 'pending',
        'offers': updatedOffers,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // إتمام الصفقة
  Future<void> completeDeal(String dealId) async {
    try {
      // سيتم تنفيذه لاحقًا
    } catch (e) {
      throw e;
    }
  }

  // إلغاء الصفقة
  Future<void> cancelDeal(String dealId) async {
    try {
      // سيتم تنفيذه لاحقًا
    } catch (e) {
      throw e;
    }
  }
}

// خدمة التقييمات
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إنشاء تقييم جديد
  Future<String> createRating({
    required String dealId,
    required String fromUserId,
    required String toUserId,
    required int rating,
    String comment = '',
  }) async {
    try {
      DocumentReference ratingRef = await _firestore.collection('ratings').add({
        'dealId': dealId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });
      
      return ratingRef.id;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على تقييمات المستخدم
  Future<List<Rating>> getUserRatings(String userId) async {
    try {
      QuerySnapshot ratingQuery = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Rating> ratings = [];
      
      for (var doc in ratingQuery.docs) {
        ratings.add(Rating.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return ratings;
    } catch (e) {
      throw e;
    }
  }

  // حساب متوسط تقييم المستخدم
  Future<double> getUserAverageRating(String userId) async {
    try {
      QuerySnapshot ratingQuery = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      if (ratingQuery.docs.isEmpty) {
        return 0.0;
      }
      
      double totalRating = 0.0;
      
      for (var doc in ratingQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalRating += data['rating'] ?? 0;
      }
      
      return totalRating / ratingQuery.docs.length;
    } catch (e) {
      throw e;
    }
  }
}

// خدمة الإيداع والسحب
class DepositWithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

  // إنشاء طلب إيداع
  Future<String> createDepositRequest({
    required String userId,
    required String method,
    required double amount,
    required String currency,
    required String screenshotUrl,
    String notes = '',
  }) async {
    try {
      DocumentReference depositRef = await _firestore.collection('deposits_withdrawals').add({
        'userId': userId,
        'type': 'deposit',
        'method': method,
        'amount': amount,
        'currency': currency,
        'fee': 0.0,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'completedAt': null,
        'adminId': '',
        'notes': notes,
        'screenshotUrl': screenshotUrl,
        'destinationAddress': '',
      });
      
      return depositRef.id;
    } catch (e) {
      throw e;
    }
  }

  // إنشاء طلب سحب
  Future<String> createWithdrawalRequest({
    required String userId,
    required String method,
    required double amount,
    required String currency,
    required String destinationAddress,
    String notes = '',
  }) async {
    try {
      // الحصول على نسبة العمولة
      DocumentSnapshot settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (!settingsDoc.exists) {
        throw Exception('إعدادات النظام غير موجودة');
      }
      
      Map<String, dynamic> settings = settingsDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> commissionRates = settings['commissionRates'] ?? {};
      
      double commissionRate = commissionRates['withdrawal']?.toDouble() ?? 0.1;
      double fee = amount * commissionRate;
      
      // التحقق من كفاية الرصيد
      bool hasSufficientBalance = await _walletService.checkSufficientBalance(
        userId,
        currency,
        amount + fee,
      );
      
      if (!hasSufficientBalance) {
        throw Exception('رصيد غير كافٍ');
      }
      
      // خصم المبلغ من المحفظة
      await _walletService.updateWalletBalance(
        userId,
        currency,
        -(amount + fee),
      );
      
      // إنشاء طلب السحب
      DocumentReference withdrawalRef = await _firestore.collection('deposits_withdrawals').add({
        'userId': userId,
        'type': 'withdrawal',
        'method': method,
        'amount': amount,
        'currency': currency,
        'fee': fee,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'completedAt': null,
        'adminId': '',
        'notes': notes,
        'screenshotUrl': '',
        'destinationAddress': destinationAddress,
      });
      
      return withdrawalRef.id;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على طلبات الإيداع والسحب للمستخدم
  Future<List<DepositWithdrawal>> getUserDepositsWithdrawals(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('deposits_withdrawals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<DepositWithdrawal> depositsWithdrawals = [];
      
      for (var doc in query.docs) {
        depositsWithdrawals.add(DepositWithdrawal.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return depositsWithdrawals;
    } catch (e) {
      throw e;
    }
  }
}

// خدمة الإشعارات
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // إنشاء إشعار جديد
  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      DocumentReference notificationRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': data,
      });
      
      // إرسال إشعار Firebase
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String fcmToken = userData['fcmToken'] ?? '';
        
        if (fcmToken.isNotEmpty) {
          await _sendPushNotification(fcmToken, title, message, data);
        }
      }
      
      return notificationRef.id;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على إشعارات المستخدم
  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      QuerySnapshot notificationQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Notification> notifications = [];
      
      for (var doc in notificationQuery.docs) {
        notifications.add(Notification.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return notifications;
    } catch (e) {
      throw e;
    }
  }

  // تحديث حالة قراءة الإشعار
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw e;
    }
  }

  // تحديث رمز FCM للمستخدم
  Future<void> updateFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      throw e;
    }
  }

  // إرسال إشعار Firebase
  Future<void> _sendPushNotification(
    String token,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // سيتم تنفيذه لاحقًا باستخدام Cloud Functions
    } catch (e) {
      throw e;
    }
  }
}

// خدمة الدعم الفني
class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // إنشاء تذكرة دعم جديدة
  Future<String> createSupportTicket({
    required String userId,
    required String subject,
    required String message,
    String priority = 'medium',
    String attachmentUrl = '',
  }) async {
    try {
      DocumentReference ticketRef = await _firestore.collection('support_tickets').add({
        'userId': userId,
        'subject': subject,
        'status': 'open',
        'priority': priority,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'messages': [
          {
            'senderId': userId,
            'message': message,
            'attachmentUrl': attachmentUrl,
            'createdAt': Timestamp.now(),
          }
        ],
      });
      
      // إنشاء إشعار للمشرفين
      QuerySnapshot adminQuery = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .where('adminPermissions', arrayContains: 'support')
          .get();
      
      for (var adminDoc in adminQuery.docs) {
        await _notificationService.createNotification(
          userId: adminDoc.id,
          type: 'support',
          title: 'تذكرة دعم جديدة',
          message: 'تم إنشاء تذكرة دعم جديدة: $subject',
          data: {
            'ticketId': ticketRef.id,
          },
        );
      }
      
      return ticketRef.id;
    } catch (e) {
      throw e;
    }
  }

  // إضافة رد إلى تذكرة
  Future<void> addReplyToTicket({
    required String ticketId,
    required String senderId,
    required String message,
    String attachmentUrl = '',
  }) async {
    try {
      DocumentSnapshot ticketDoc = await _firestore.collection('support_tickets').doc(ticketId).get();
      
      if (!ticketDoc.exists) {
        throw Exception('التذكرة غير موجودة');
      }
      
      Map<String, dynamic> ticketData = ticketDoc.data() as Map<String, dynamic>;
      
      if (ticketData['status'] == 'closed') {
        throw Exception('التذكرة مغلقة');
      }
      
      // إضافة الرد
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'messages': FieldValue.arrayUnion([
          {
            'senderId': senderId,
            'message': message,
            'attachmentUrl': attachmentUrl,
            'createdAt': Timestamp.now(),
          }
        ]),
        'updatedAt': Timestamp.now(),
      });
      
      // إنشاء إشعار للطرف الآخر
      String userId = ticketData['userId'];
      
      if (senderId == userId) {
        // إنشاء إشعار للمشرفين
        QuerySnapshot adminQuery = await _firestore
            .collection('users')
            .where('isAdmin', isEqualTo: true)
            .where('adminPermissions', arrayContains: 'support')
            .get();
        
        for (var adminDoc in adminQuery.docs) {
          await _notificationService.createNotification(
            userId: adminDoc.id,
            type: 'support',
            title: 'رد جديد على تذكرة',
            message: 'تم إضافة رد جديد على تذكرة: ${ticketData['subject']}',
            data: {
              'ticketId': ticketId,
            },
          );
        }
      } else {
        // إنشاء إشعار للمستخدم
        await _notificationService.createNotification(
          userId: userId,
          type: 'support',
          title: 'رد جديد على تذكرتك',
          message: 'تم إضافة رد جديد على تذكرتك: ${ticketData['subject']}',
          data: {
            'ticketId': ticketId,
          },
        );
      }
    } catch (e) {
      throw e;
    }
  }

  // الحصول على تذاكر المستخدم
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      QuerySnapshot ticketQuery = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      
      List<SupportTicket> tickets = [];
      
      for (var doc in ticketQuery.docs) {
        tickets.add(SupportTicket.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return tickets;
    } catch (e) {
      throw e;
    }
  }

  // تغيير حالة التذكرة
  Future<void> changeTicketStatus(String ticketId, String status) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }
}

// خدمة إعدادات النظام
class SystemSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على إعدادات النظام
  Future<SystemSettings> getSystemSettings() async {
    try {
      DocumentSnapshot settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (!settingsDoc.exists) {
        throw Exception('إعدادات النظام غير موجودة');
      }
      
      return SystemSettings.fromFirestore(settingsDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw e;
    }
  }

  // تحديث أسعار الصرف
  Future<void> updateExchangeRates(Map<String, double> exchangeRates) async {
    try {
      await _firestore.collection('system_settings').doc('general').update({
        'exchangeRates': exchangeRates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // تحديث نسب العمولات
  Future<void> updateCommissionRates(Map<String, double> commissionRates) async {
    try {
      await _firestore.collection('system_settings').doc('general').update({
        'commissionRates': commissionRates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // تحديث خصومات المستويات
  Future<void> updateLevelDiscounts(Map<String, double> levelDiscounts) async {
    try {
      await _firestore.collection('system_settings').doc('general').update({
        'levelDiscounts': levelDiscounts,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // تحديث متطلبات المستويات
  Future<void> updateLevelRequirements(Map<String, dynamic> levelRequirements) async {
    try {
      await _firestore.collection('system_settings').doc('general').update({
        'levelRequirements': levelRequirements,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // تحديث الحدود اليومية
  Future<void> updateDailyLimits(Map<String, dynamic> dailyLimits) async {
    try {
      await _firestore.collection('system_settings').doc('general').update({
        'dailyLimits': dailyLimits,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }

  // تحديث عناوين الإيداع
  Future<void> updateDepositAddresses(Map<String, String> depositAddresses) async {
    try {
      await _firestore.collection('system_settings').doc('general').update({
        'depositAddresses': depositAddresses,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw e;
    }
  }
}

// خدمة المشرف
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();
  final NotificationService _notificationService = NotificationService();

  // الحصول على جميع المستخدمين
  Future<List<User>> getAllUsers() async {
    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<User> users = [];
      
      for (var doc in userQuery.docs) {
        users.add(User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return users;
    } catch (e) {
      throw e;
    }
  }

  // تحديث مستوى المستخدم
  Future<void> updateUserLevel(String userId, String level) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'level': level,
      });
      
      // إنشاء إشعار للمستخدم
      await _notificationService.createNotification(
        userId: userId,
        type: 'level',
        title: 'تحديث المستوى',
        message: 'تم تحديث مستواك إلى $level',
        data: {
          'level': level,
        },
      );
    } catch (e) {
      throw e;
    }
  }

  // تعليق حساب المستخدم
  Future<void> suspendUser(String userId, bool suspend) async {
    try {
      // سيتم تنفيذه لاحقًا
    } catch (e) {
      throw e;
    }
  }

  // الحصول على جميع المعاملات
  Future<List<Transaction>> getAllTransactions() async {
    try {
      QuerySnapshot transactionQuery = await _firestore
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Transaction> transactions = [];
      
      for (var doc in transactionQuery.docs) {
        transactions.add(Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return transactions;
    } catch (e) {
      throw e;
    }
  }

  // الحصول على جميع طلبات الإيداع والسحب
  Future<List<DepositWithdrawal>> getAllDepositsWithdrawals() async {
    try {
      QuerySnapshot query = await _firestore
          .collection('deposits_withdrawals')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<DepositWithdrawal> depositsWithdrawals = [];
      
      for (var doc in query.docs) {
        depositsWithdrawals.add(DepositWithdrawal.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return depositsWithdrawals;
    } catch (e) {
      throw e;
    }
  }

  // تأكيد طلب الإيداع
  Future<void> confirmDeposit(String depositId, String adminId) async {
    try {
      DocumentSnapshot depositDoc = await _firestore.collection('deposits_withdrawals').doc(depositId).get();
      
      if (!depositDoc.exists) {
        throw Exception('طلب الإيداع غير موجود');
      }
      
      Map<String, dynamic> depositData = depositDoc.data() as Map<String, dynamic>;
      
      if (depositData['status'] != 'pending') {
        throw Exception('طلب الإيداع ليس معلقًا');
      }
      
      if (depositData['type'] != 'deposit') {
        throw Exception('هذا ليس طلب إيداع');
      }
      
      String userId = depositData['userId'];
      String currency = depositData['currency'];
      double amount = depositData['amount']?.toDouble() ?? 0.0;
      
      // إضافة المبلغ إلى محفظة المستخدم
      await _walletService.updateWalletBalance(
        userId,
        currency,
        amount,
      );
      
      // تحديث حالة طلب الإيداع
      await _firestore.collection('deposits_withdrawals').doc(depositId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'adminId': adminId,
      });
      
      // إنشاء إشعار للمستخدم
      await _notificationService.createNotification(
        userId: userId,
        type: 'transaction',
        title: 'تأكيد الإيداع',
        message: 'تم تأكيد طلب الإيداع الخاص بك بمبلغ $amount $currency',
        data: {
          'depositId': depositId,
          'amount': amount,
          'currency': currency,
        },
      );
    } catch (e) {
      throw e;
    }
  }

  // تأكيد طلب السحب
  Future<void> confirmWithdrawal(String withdrawalId, String adminId) async {
    try {
      DocumentSnapshot withdrawalDoc = await _firestore.collection('deposits_withdrawals').doc(withdrawalId).get();
      
      if (!withdrawalDoc.exists) {
        throw Exception('طلب السحب غير موجود');
      }
      
      Map<String, dynamic> withdrawalData = withdrawalDoc.data() as Map<String, dynamic>;
      
      if (withdrawalData['status'] != 'pending') {
        throw Exception('طلب السحب ليس معلقًا');
      }
      
      if (withdrawalData['type'] != 'withdrawal') {
        throw Exception('هذا ليس طلب سحب');
      }
      
      String userId = withdrawalData['userId'];
      String currency = withdrawalData['currency'];
      double amount = withdrawalData['amount']?.toDouble() ?? 0.0;
      
      // تحديث حالة طلب السحب
      await _firestore.collection('deposits_withdrawals').doc(withdrawalId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'adminId': adminId,
      });
      
      // إنشاء إشعار للمستخدم
      await _notificationService.createNotification(
        userId: userId,
        type: 'transaction',
        title: 'تأكيد السحب',
        message: 'تم تأكيد طلب السحب الخاص بك بمبلغ $amount $currency',
        data: {
          'withdrawalId': withdrawalId,
          'amount': amount,
          'currency': currency,
        },
      );
    } catch (e) {
      throw e;
    }
  }

  // رفض طلب الإيداع أو السحب
  Future<void> rejectDepositWithdrawal(String operationId, String adminId, String reason) async {
    try {
      DocumentSnapshot operationDoc = await _firestore.collection('deposits_withdrawals').doc(operationId).get();
      
      if (!operationDoc.exists) {
        throw Exception('الطلب غير موجود');
      }
      
      Map<String, dynamic> operationData = operationDoc.data() as Map<String, dynamic>;
      
      if (operationData['status'] != 'pending') {
        throw Exception('الطلب ليس معلقًا');
      }
      
      String userId = operationData['userId'];
      String type = operationData['type'];
      String currency = operationData['currency'];
      double amount = operationData['amount']?.toDouble() ?? 0.0;
      
      // إذا كان طلب سحب، إعادة المبلغ إلى محفظة المستخدم
      if (type == 'withdrawal') {
        double fee = operationData['fee']?.toDouble() ?? 0.0;
        await _walletService.updateWalletBalance(
          userId,
          currency,
          amount + fee,
        );
      }
      
      // تحديث حالة الطلب
      await _firestore.collection('deposits_withdrawals').doc(operationId).update({
        'status': 'rejected',
        'completedAt': Timestamp.now(),
        'adminId': adminId,
        'notes': reason,
      });
      
      // إنشاء إشعار للمستخدم
      String title = type == 'deposit' ? 'رفض الإيداع' : 'رفض السحب';
      String message = type == 'deposit'
          ? 'تم رفض طلب الإيداع الخاص بك بمبلغ $amount $currency'
          : 'تم رفض طلب السحب الخاص بك بمبلغ $amount $currency';
      
      await _notificationService.createNotification(
        userId: userId,
        type: 'transaction',
        title: title,
        message: '$message\nالسبب: $reason',
        data: {
          'operationId': operationId,
          'amount': amount,
          'currency': currency,
          'reason': reason,
        },
      );
    } catch (e) {
      throw e;
    }
  }

  // الحصول على جميع تذاكر الدعم
  Future<List<SupportTicket>> getAllSupportTickets() async {
    try {
      QuerySnapshot ticketQuery = await _firestore
          .collection('support_tickets')
          .orderBy('updatedAt', descending: true)
          .get();
      
      List<SupportTicket> tickets = [];
      
      for (var doc in ticketQuery.docs) {
        tickets.add(SupportTicket.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      
      return tickets;
    } catch (e) {
      throw e;
    }
  }

  // توليد تقرير
  Future<Map<String, dynamic>> generateReport(String reportType, DateTime startDate, DateTime endDate) async {
    try {
      // سيتم تنفيذه لاحقًا
      return {};
    } catch (e) {
      throw e;
    }
  }
}
