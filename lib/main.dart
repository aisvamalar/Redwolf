import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'controllers/product_controller.dart';
import 'views/screens/home_view.dart';
import 'views/screens/product_detail_view.dart';
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

  // Pre-load products for home screen
  ProductService().preloadProducts();

  runApp(const RedWolfApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeView()),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id'];
        if (productId == null || productId.isEmpty) {
          // Redirect to home if no product ID
          return const HomeView();
        }
        
        // Try to get product from controller first (faster)
        final controller = Provider.of<ProductController>(context, listen: false);
        try {
          final product = controller.products.firstWhere(
            (p) => p.id == productId,
          );
          return ProductDetailView(product: product);
        } catch (e) {
          // Product not in controller - fetch from database
          // Use a FutureBuilder to handle async loading
          return FutureBuilder(
            future: ProductService().getProductById(productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Product not found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Go to Home'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ProductDetailView(product: snapshot.data!);
            },
          );
        }
      },
    ),
    // Admin panel routes removed - handled by separate codebase
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
