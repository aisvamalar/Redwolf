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
  debugLogDiagnostics: true, // Enable debug logging
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'product-detail',
      builder: (context, state) {
        final productId = state.pathParameters['id'];
        print('🔍 PRODUCT ROUTE MATCHED! Product ID: $productId');
        print('🔍 Full path: ${state.fullPath}');
        print('🔍 URI: ${state.uri}');
        
        if (productId == null || productId.isEmpty) {
          print('❌ No product ID provided, redirecting to home');
          return const HomeView();
        }
        
        // Try to get product from controller first (faster)
        final controller = Provider.of<ProductController>(context, listen: false);
        try {
        final product = controller.products.firstWhere(
          (p) => p.id == productId,
        );
          print('✅ Product found in controller: ${product.name}');
        return ProductDetailView(product: product);
        } catch (e) {
          print('⚠️ Product not in controller, fetching from database...');
          // Product not in controller - fetch from database
          // Use a FutureBuilder to handle async loading
          return FutureBuilder(
            future: ProductService().getProductById(productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('⏳ Loading product from database...');
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading product...'),
                      ],
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                print('❌ Error loading product: ${snapshot.error}');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading product: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
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
              
              if (!snapshot.hasData || snapshot.data == null) {
                print('❌ Product not found in database: $productId');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Product not found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Product ID: $productId',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              
              print('✅ Product loaded from database: ${snapshot.data!.name}');
              return ProductDetailView(product: snapshot.data!);
            },
          );
        }
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
