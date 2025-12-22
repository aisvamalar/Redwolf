import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'controllers/product_controller.dart';
import 'views/screens/home_view.dart';
import 'views/screens/admin/admin_login.dart';
import 'views/screens/admin/admin_dashboard.dart';
import 'views/screens/admin/admin_product_list.dart';
import 'views/screens/admin/admin_add_product.dart';
import 'models/admin_product.dart';
import 'services/admin_product_service.dart';
import 'services/product_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.publishableKey,
  );

  // Store the client instance in config
  SupabaseConfig.supabaseClient = Supabase.instance.client;

  // Pre-load products for admin panel and home screen
  AdminProductService().preloadProducts();
  ProductService().preloadProducts();

  runApp(const RedWolfApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeView()),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLogin(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) {
        // Check if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return const AdminLogin();
        }
        return const AdminDashboard();
      },
    ),
    GoRoute(path: '/admin', redirect: (context, state) => '/admin/login'),
    GoRoute(
      path: '/admin/products',
      builder: (context, state) {
        // Check if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return const AdminLogin();
        }
        return const AdminProductList();
      },
    ),
    GoRoute(
      path: '/admin/products/add',
      builder: (context, state) {
        // Check if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return const AdminLogin();
        }
        final extra = state.extra;
        AdminProduct? product;
        if (extra is Map<String, dynamic>?) {
          product = extra?['product'] as AdminProduct?;
        } else if (extra is AdminProduct) {
          product = extra;
        }
        return AdminAddProduct(product: product);
      },
    ),
  ],
);

class RedWolfApp extends StatelessWidget {
  const RedWolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductController(),
      child: MaterialApp.router(
        title: 'RedWolf Media',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDC2626),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Roboto',
        ),
        routerConfig: _router,
      ),
    );
  }
}
