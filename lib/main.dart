import 'package:flutter/material.dart';
import 'package:mpay_clean/theme/enhanced_theme.dart';
import 'package:mpay_clean/widgets/enhanced_components.dart';
import 'package:mpay_clean/screens/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedApp(
      enablePerformanceOptimizations: true,
      child: SplashScreen(nextScreen: HomePage()),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedScaffold(
      title: 'Mpay',
      enableBackgroundEffects: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(EnhancedTheme.mediumPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context),
              SizedBox(height: EnhancedTheme.largeSpacing),
              _buildQuickActionsSection(context),
              SizedBox(height: EnhancedTheme.largeSpacing),
              _buildRecentTransactionsSection(context),
              SizedBox(height: EnhancedTheme.largeSpacing),
              _buildPromotionsSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'المحفظة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'التحويلات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الحساب',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {},
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
        tooltip: 'إضافة معاملة جديدة',
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: EnhancedTheme.largeBorderRadius,
      blur: 10,
      opacity: 0.1,
      borderColor: Colors.white.withOpacity(0.5),
      gradient: LinearGradient(
        colors: [
          EnhancedTheme.primaryColor.withOpacity(0.3),
          EnhancedTheme.accentColor.withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: EdgeInsets.all(EnhancedTheme.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مرحباً، أحمد',
                  style: EnhancedTheme.headlineStyle.copyWith(
                    color: EnhancedTheme.textPrimaryColor,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: EnhancedTheme.primaryColor,
                  child: Text('أ', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            SizedBox(height: EnhancedTheme.mediumSpacing),
            Text(
              'رصيدك الحالي',
              style: EnhancedTheme.bodyStyle.copyWith(
                color: EnhancedTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: EnhancedTheme.smallSpacing),
            AnimatedCounter(
              end: 12500,
              prefix: '\$',
              style: EnhancedTheme.headlineStyle.copyWith(
                fontSize: 28,
                color: EnhancedTheme.primaryColor,
              ),
              includeCommas: true,
            ),
            SizedBox(height: EnhancedTheme.mediumSpacing),
            EnhancedProgressIndicator(
              value: 0.7,
              height: 8,
              showPercentage: false,
              backgroundColor: EnhancedTheme.primaryColor.withOpacity(0.2),
              foregroundColor: EnhancedTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات السريعة',
          style: EnhancedTheme.titleStyle,
        ),
        SizedBox(height: EnhancedTheme.mediumSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionItem(
              context,
              icon: Icons.send,
              title: 'إرسال',
              color: EnhancedTheme.primaryColor,
              onTap: () {},
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.account_balance,
              title: 'سحب',
              color: EnhancedTheme.accentColor,
              onTap: () {},
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.payment,
              title: 'دفع',
              color: EnhancedTheme.successColor,
              onTap: () {},
            ),
            _buildQuickActionItem(
              context,
              icon: Icons.history,
              title: 'السجل',
              color: EnhancedTheme.infoColor,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          NeumorphicContainer(
            width: 60,
            height: 60,
            borderRadius: EnhancedTheme.mediumBorderRadius,
            color: Colors.white,
            style: NeumorphicStyle.convex,
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: EnhancedTheme.smallSpacing),
          Text(
            title,
            style: EnhancedTheme.bodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المعاملات الأخيرة',
              style: EnhancedTheme.titleStyle,
            ),
            TextButton(
              onPressed: () {},
              child: Text('عرض الكل'),
            ),
          ],
        ),
        SizedBox(height: EnhancedTheme.mediumSpacing),
        _buildTransactionItem(
          context,
          icon: Icons.arrow_upward,
          title: 'تحويل إلى محمد',
          date: '14 أبريل 2025',
          amount: '-\$250.00',
          isDebit: true,
        ),
        SizedBox(height: EnhancedTheme.smallSpacing),
        _buildTransactionItem(
          context,
          icon: Icons.arrow_downward,
          title: 'استلام من شركة ABC',
          date: '12 أبريل 2025',
          amount: '+\$1,200.00',
          isDebit: false,
        ),
        SizedBox(height: EnhancedTheme.smallSpacing),
        _buildTransactionItem(
          context,
          icon: Icons.shopping_cart,
          title: 'مشتريات من متجر XYZ',
          date: '10 أبريل 2025',
          amount: '-\$85.50',
          isDebit: true,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required bool isDebit,
  }) {
    return InteractiveCard(
      height: 80,
      backgroundColor: Colors.white,
      enableTilt: false,
      enableHoverScale: true,
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.all(EnhancedTheme.mediumPadding),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDebit
                    ? EnhancedTheme.errorColor.withOpacity(0.1)
                    : EnhancedTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(EnhancedTheme.smallBorderRadius),
              ),
              child: Icon(
                icon,
                color: isDebit ? EnhancedTheme.errorColor : EnhancedTheme.successColor,
              ),
            ),
            SizedBox(width: EnhancedTheme.mediumSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: EnhancedTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date,
                    style: EnhancedTheme.captionStyle,
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: EnhancedTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: isDebit ? EnhancedTheme.errorColor : EnhancedTheme.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العروض والترقيات',
          style: EnhancedTheme.titleStyle,
        ),
        SizedBox(height: EnhancedTheme.mediumSpacing),
        Container(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPromotionCard(
                context,
                title: 'احصل على خصم 10%',
                description: 'عند تحويل أكثر من \$500 هذا الشهر',
                color: EnhancedTheme.primaryColor,
              ),
              SizedBox(width: EnhancedTheme.mediumSpacing),
              _buildPromotionCard(
                context,
                title: 'ترقية إلى المستوى الذهبي',
                description: 'أكمل 5 معاملات إضافية للترقية',
                color: EnhancedTheme.accentColor,
              ),
              SizedBox(width: EnhancedTheme.mediumSpacing),
              _buildPromotionCard(
                context,
                title: 'دعوة الأصدقاء',
                description: 'احصل على \$20 لكل صديق تدعوه',
                color: EnhancedTheme.successColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
  }) {
    return GradientBorderContainer(
      width: 250,
      height: 180,
      gradient: LinearGradient(
        colors: [
          color,
          color.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(EnhancedTheme.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerEffect(
              baseColor: color.withOpacity(0.5),
              highlightColor: color,
              child: Icon(
                Icons.card_giftcard,
                size: 40,
                color: color,
              ),
            ),
            SizedBox(height: EnhancedTheme.mediumSpacing),
            Text(
              title,
              style: EnhancedTheme.titleStyle.copyWith(
                color: color,
              ),
            ),
            SizedBox(height: EnhancedTheme.smallSpacing),
            Text(
              description,
              style: EnhancedTheme.bodyStyle,
            ),
            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: EnhancedButton(
                text: 'المزيد',
                onPressed: () {},
                backgroundColor: color,
                width: 100,
                height: 40,
                animationType: AnimationType.scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
