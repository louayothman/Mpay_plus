import 'package:flutter/material.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class IdentityVerificationScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userEmail;

  const IdentityVerificationScreen({
    Key? key,
    required this.userId,
    this.userName,
    this.userEmail,
  }) : super(key: key);

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final SecurityUtils _securityUtils = SecurityUtils();
  
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _frontIdImage;
  File? _backIdImage;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  
  VerificationStatus _verificationStatus = VerificationStatus.notVerified;
  String? _verificationMessage;
  DateTime? _verificationDate;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  
  bool _hasInternetConnection = true;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    _checkInternetConnection();
    _loadUserVerificationStatus();
    
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      _fullNameController.text = widget.userName!;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _checkInternetConnection() async {
    bool hasConnection = await _connectivityUtils.checkInternetConnection();
    if (mounted) {
      setState(() {
        _hasInternetConnection = hasConnection;
      });
    }
  }
  
  Future<void> _loadUserVerificationStatus() async {
    if (!_hasInternetConnection) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final verificationData = await _firebaseService.getUserVerificationStatus(widget.userId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          if (verificationData != null) {
            _verificationStatus = _getVerificationStatusFromString(verificationData['status']);
            _verificationMessage = verificationData['message'];
            
            if (verificationData['verificationDate'] != null) {
              _verificationDate = DateTime.parse(verificationData['verificationDate']);
            }
            
            if (verificationData['idNumber'] != null) {
              _idNumberController.text = verificationData['idNumber'];
            }
            
            if (verificationData['fullName'] != null && _fullNameController.text.isEmpty) {
              _fullNameController.text = verificationData['fullName'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل حالة التحقق. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }
  
  VerificationStatus _getVerificationStatusFromString(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'pending':
        return VerificationStatus.pending;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.notVerified;
    }
  }
  
  Future<void> _pickImage(ImageSource source, bool isFrontId) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isFrontId) {
            _frontIdImage = File(pickedFile.path);
          } else {
            _backIdImage = File(pickedFile.path);
          }
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'فشل في اختيار الصورة: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      });
    }
  }
  
  void _showImageSourceDialog(bool isFrontId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFrontId ? 'اختر صورة الوجه الأمامي للهوية' : 'اختر صورة الوجه الخلفي للهوية',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      title: 'الكاميرا',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera, isFrontId);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      title: 'المعرض',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery, isFrontId);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedFeedbackButton(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_frontIdImage == null || _backIdImage == null) {
      setState(() {
        _errorMessage = 'يرجى تحميل صور الهوية (الوجه الأمامي والخلفي).';
      });
      return;
    }
    
    if (!_hasInternetConnection) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Encrypt sensitive data before sending
      final encryptedIdNumber = await _securityUtils.encryptSensitiveData(_idNumberController.text);
      
      // Upload images to Firebase Storage
      final frontIdUrl = await _firebaseService.uploadVerificationImage(
        widget.userId,
        _frontIdImage!,
        'front_id',
      );
      
      final backIdUrl = await _firebaseService.uploadVerificationImage(
        widget.userId,
        _backIdImage!,
        'back_id',
      );
      
      // Submit verification request
      await _firebaseService.submitVerificationRequest(
        userId: widget.userId,
        fullName: _fullNameController.text,
        idNumber: encryptedIdNumber,
        frontIdUrl: frontIdUrl,
        backIdUrl: backIdUrl,
        userEmail: widget.userEmail,
      );
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _verificationStatus = VerificationStatus.pending;
          _successMessage = 'تم إرسال طلب التحقق بنجاح. سيتم مراجعته من قبل الإدارة.';
          _verificationMessage = 'طلبك قيد المراجعة. سيتم إعلامك عند اكتمال المراجعة.';
          _verificationDate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'حدث خطأ أثناء إرسال طلب التحقق. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: 'التحقق من الهوية',
        centerTitle: true,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (_verificationStatus != VerificationStatus.verified)
              _buildVerificationForm(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_verificationStatus) {
      case VerificationStatus.verified:
        statusColor = Theme.of(context).colorScheme.primary;
        statusIcon = Icons.verified_user;
        statusText = 'تم التحقق';
        break;
      case VerificationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'قيد المراجعة';
        break;
      case VerificationStatus.rejected:
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'مرفوض';
        break;
      case VerificationStatus.notVerified:
        statusColor = Colors.grey;
        statusIcon = Icons.person_outline;
        statusText = 'غير محقق';
        break;
    }
    
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'حالة التحقق:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                status: statusText,
                size: 16,
                showAnimation: _verificationStatus == VerificationStatus.pending,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_verificationMessage != null) ...[
            Text(
              _verificationMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],
          if (_verificationDate != null) ...[
            Text(
              'تاريخ آخر تحديث: ${_formatDate(_verificationDate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_verificationStatus == VerificationStatus.verified) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'تم التحقق من هويتك بنجاح. يمكنك الآن الاستفادة من جميع ميزات التطبيق.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          if (_verificationStatus == VerificationStatus.rejected) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'يمكنك إعادة تقديم طلب التحقق مع التأكد من صحة المعلومات والصور المقدمة.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildVerificationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات التحقق',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى تقديم المعلومات التالية للتحقق من هويتك. سيتم مراجعة المعلومات من قبل فريق الإدارة.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          AdaptiveTextField(
            controller: _fullNameController,
            labelText: 'الاسم الكامل',
            hintText: 'أدخل الاسم الكامل كما هو في الهوية',
            prefixIcon: const Icon(Icons.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال الاسم الكامل';
              }
              if (value.length < 3) {
                return 'يجب أن يكون الاسم أكثر من 3 أحرف';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _idNumberController,
            labelText: 'رقم الهوية',
            hintText: 'أدخل رقم الهوية الوطنية',
            prefixIcon: const Icon(Icons.credit_card),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال رقم الهوية';
              }
              if (value.length < 5) {
                return 'يجب أن يكون رقم الهوية صحيحاً';
              }
              return null;
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 32),
          Text(
            'صور الهوية',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى تحميل صور واضحة للوجه الأمامي والخلفي من بطاقة الهوية أو جواز السفر.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildImageUploadCard(
                  title: 'الوجه الأمامي',
                  image: _frontIdImage,
                  onTap: () => _showImageSourceDialog(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageUploadCard(
                  title: 'الوجه الخلفي',
                  image: _backIdImage,
                  onTap: () => _showImageSourceDialog(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          AnimatedProgressButton(
            onPressed: () {},
            action: _submitVerification,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            loadingText: 'جاري الإرسال...',
            successText: 'تم الإرسال بنجاح',
            errorText: 'فشل الإرسال',
            width: double.infinity,
            height: 50,
            borderRadius: BorderRadius.circular(12),
            child: const Text(
              'إرسال طلب التحقق',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildImageUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: image != null ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (image == _frontIdImage) {
                              _frontIdImage = null;
                            } else {
                              _backIdImage = null;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onError,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'انقر لتحميل الصورة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

enum VerificationStatus {
  notVerified,
  pending,
  verified,
  rejected,
}
