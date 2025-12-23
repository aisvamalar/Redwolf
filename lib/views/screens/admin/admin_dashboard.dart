import 'package:flutter/material.dart';
import '../../../widgets/admin/sidebar.dart';
import '../../../widgets/admin/footer.dart';
import '../../../models/admin_product.dart';
import '../../../services/admin_supabase_service.dart';
import '../../../services/analytics_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AnalyticsService _analyticsService = AnalyticsService();
  int _productPageViews = 0;
  int _arViews = 0;
  bool _isLoadingAnalytics = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final pageViews = await _analyticsService.getProductPageViews(days: 30);
      final arViews = await _analyticsService.getARViews(days: 30);

      if (mounted) {
        setState(() {
          _productPageViews = pageViews;
          _arViews = arViews;
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  // Realtime stream of products from Supabase
  static final _productsStream = AdminSupabaseService().client
      .from('products')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            drawer: Drawer(
              child: AdminSidebar(currentRoute: '/admin/dashboard'),
            ),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF111827)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: _buildLogo(),
            ),
            body: _buildContent(context),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Row(
            children: [
              const AdminSidebar(currentRoute: '/admin/dashboard'),
              Expanded(child: _buildContent(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _productsStream,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            final products = snapshot.data != null
                ? snapshot.data!
                      .map((row) => AdminProduct.fromJson(row))
                      .toList()
                : <AdminProduct>[];

            // Sort by most recent activity
            products.sort((a, b) {
              final aTime =
                  a.updatedAt ??
                  a.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.updatedAt ??
                  b.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            final productCount = products.length;
            final recentProducts = products.take(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Metric Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      final isTablet = constraints.maxWidth < 1024;

                      final cards = _buildMetricCards(
                        productCount,
                        _productPageViews,
                        _arViews,
                        _isLoadingAnalytics,
                      );

                      if (isMobile) {
                        return Column(children: cards);
                      } else if (isTablet) {
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                          children: cards,
                        );
                      } else {
                        return Row(
                          children: cards.asMap().entries.map((entry) {
                            final index = entry.key;
                            final card = entry.value;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index < cards.length - 1 ? 16 : 0,
                                ),
                                child: card,
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  // Recent Activity
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.refresh,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (recentProducts.isEmpty)
                          const Text(
                            'No recent activity yet.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          )
                        else
                          ...recentProducts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final product = entry.value;
                            return Column(
                              children: [
                                if (index > 0) const Divider(height: 32),
                                _buildActivityItem(product),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
        const Positioned(bottom: 0, left: 0, right: 0, child: AdminFooter()),
      ],
    );
  }

  List<Widget> _buildMetricCards(
    int productCount,
    int productPageViews,
    int arViews,
    bool isLoadingAnalytics,
  ) {
    return [
      _buildMetricCard(
        icon: Icons.inventory_2,
        title: 'Product Count',
        value: productCount.toString(),
        trend: '+15%',
        trendColor: Colors.green,
        trendIcon: Icons.trending_up,
      ),
      _buildMetricCard(
        icon: Icons.remove_red_eye,
        title: 'Product page views',
        value: isLoadingAnalytics
            ? 'Loading...'
            : _formatNumber(productPageViews),
        trend: 'past 30 days',
        trendColor: const Color(0xFFDC2626),
        trendIcon: Icons.trending_down,
      ),
      _buildMetricCard(
        icon: Icons.view_in_ar,
        title: 'AR Views',
        value: isLoadingAnalytics ? 'Loading...' : _formatNumber(arViews),
        trend: 'past 30 days',
        trendColor: const Color(0xFFDC2626),
        trendIcon: Icons.trending_down,
      ),
    ];
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required IconData trendIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFDC2626), size: 24),
              ),
              const Icon(
                Icons.info_outline,
                color: Color(0xFF9CA3AF),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, color: trendColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AdminProduct product) {
    final status = product.status;
    final isDraft = status.toLowerCase() == 'draft';
    final statusColor = isDraft
        ? const Color(0xFF6B7280)
        : const Color(0xFF16A34A);
    final statusBgColor = isDraft
        ? const Color(0xFFF3F4F6)
        : const Color(0xECFDF3);

    final activityTime = product.updatedAt ?? product.createdAt;
    final timeText = _formatTimeAgo(activityTime);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.category,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeText,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatTimeAgo(DateTime? dateTime) {
  if (dateTime == null) return '';

  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours hr${hours > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 7) {
    final days = diff.inDays;
    return '$days day${days > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? 's' : ''} ago';
  }
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  }
  final years = (diff.inDays / 365).floor();
  return '$years year${years > 1 ? 's' : ''} ago';
}

Widget _buildLogo() {
  return Align(
    alignment: Alignment.centerLeft,
    child: Image.asset(
      'img/logo.png',
      height: 60,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 60,
          child: Icon(Icons.image, color: Color(0xFFDC2626)),
        );
      },
    ),
  );
}
