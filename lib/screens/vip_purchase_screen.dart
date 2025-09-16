import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/in_app_purchase_service.dart';

// Provider sınıfları
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class VipProvider extends ChangeNotifier {
  bool _isVip = false;
  bool get isVip => _isVip;
  void setVip(bool value) {
    _isVip = value;
    notifyListeners();
  }
}

class VipPurchaseScreen extends StatefulWidget {
  const VipPurchaseScreen({super.key});

  @override
  State<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends State<VipPurchaseScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupPurchaseCallbacks();
  }

  void _setupPurchaseCallbacks() {
    InAppPurchaseService.onPurchaseSuccess = () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // VIP durumunu güncelle
        Provider.of<VipProvider>(context, listen: false).setVip(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 VIP üyeliğiniz başarıyla aktifleştirildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop();
      }
    };

    InAppPurchaseService.onPurchaseError = (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Satın alma hatası: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  void _buyMonthlyVip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await InAppPurchaseService.buyMonthlyVip();
  }

  void _buyYearlyVip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await InAppPurchaseService.buyYearlyVip();
  }

  void _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await InAppPurchaseService.restorePurchases();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final products = InAppPurchaseService.products;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF070C15)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('VIP Üyelik'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF19B4FF),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('İşleminiz gerçekleştiriliyor...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Crown Icon
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Title
                  Text(
                    'VIP ÜYELİK',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      background: Paint()
                        ..shader =
                            const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ).createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                            ),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Özel Özelliklerle Oyun Deneyimini Geliştir',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Premium Features
                  _PremiumFeatureCard(
                    title: '🚫 Reklamsız Deneyim',
                    subtitle: 'Hiç reklam görmeden oyunun tadını çıkar',
                    icon: Icons.block,
                  ),

                  const SizedBox(height: 16),

                  _PremiumFeatureCard(
                    title: '🎭 Özel Ünlüler',
                    subtitle: 'Sadece VIP üyeler için özel ünlü koleksiyonu',
                    icon: Icons.star,
                  ),

                  const SizedBox(height: 16),

                  _PremiumFeatureCard(
                    title: '⚡ Sınırsız Oyun',
                    subtitle: 'Oyun süresinde hiçbir kısıtlama yok',
                    icon: Icons.all_inclusive,
                  ),

                  const SizedBox(height: 16),

                  _PremiumFeatureCard(
                    title: '🎨 Özel Temalar',
                    subtitle: 'Sadece VIP\'lere özel renkli temalar',
                    icon: Icons.palette,
                  ),

                  const SizedBox(height: 40),

                  // Subscription Plans
                  if (products.isNotEmpty) ...[
                    Text(
                      'Abonelik Planları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Monthly Plan
                    _buildSubscriptionCard(
                      title: 'Aylık VIP',
                      price:
                          products
                              .where((p) => p.id.contains('monthly'))
                              .isNotEmpty
                          ? products
                                .where((p) => p.id.contains('monthly'))
                                .first
                                .price
                          : '₺19,99/ay',
                      description: 'Aylık yenilenen abonelik',
                      isPopular: false,
                      onTap: _buyMonthlyVip,
                    ),

                    const SizedBox(height: 16),

                    // Yearly Plan (Popular)
                    _buildSubscriptionCard(
                      title: 'Yıllık VIP',
                      price:
                          products
                              .where((p) => p.id.contains('yearly'))
                              .isNotEmpty
                          ? products
                                .where((p) => p.id.contains('yearly'))
                                .first
                                .price
                          : '₺199,99/yıl',
                      description: '12 ayda 2 ay ücretsiz!',
                      isPopular: true,
                      onTap: _buyYearlyVip,
                    ),
                  ] else ...[
                    // Fallback if products not loaded
                    Text(
                      'Abonelik Planları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    _buildSubscriptionCard(
                      title: 'Aylık VIP',
                      price: '₺19,99/ay',
                      description: 'Aylık yenilenen abonelik',
                      isPopular: false,
                      onTap: _buyMonthlyVip,
                    ),

                    const SizedBox(height: 16),

                    _buildSubscriptionCard(
                      title: 'Yıllık VIP',
                      price: '₺199,99/yıl',
                      description: '12 ayda 2 ay ücretsiz!',
                      isPopular: true,
                      onTap: _buyYearlyVip,
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Restore Purchases Button
                  TextButton(
                    onPressed: _restorePurchases,
                    child: Text(
                      'Satın Almaları Geri Yükle',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textButtonTheme.style!.foregroundColor?.resolve({}),
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms and Privacy
                  Text(
                    'Abonelik otomatik olarak yenilenir. İptal etmek için ayarlarınızdan aboneliği iptal edebilirsiniz.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required String price,
    required String description,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? const Color(0xFFFFD700)
              : Colors.grey.withOpacity(0.3),
          width: isPopular ? 2 : 1,
        ),
        gradient: isPopular
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.1),
                  const Color(0xFFFFA500).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'EN POPÜLER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular) const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isPopular
                                        ? const Color(0xFFFFD700)
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                        Text(
                          price,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPopular
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF19B4FF),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PremiumFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF19B4FF), Color(0xFF63D6FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
