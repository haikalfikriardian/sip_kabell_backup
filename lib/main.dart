import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sip_kabell_app/src/admin/dashboard/admin_dashboard_page.dart';
import 'package:sip_kabell_app/src/admin/pages/admin_login_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'firebase_options.dart';
import 'src/features/auth/bloc/auth_bloc.dart';
import 'src/features/auth/bloc/cart/cart_bloc.dart';

// Pages
import 'src/features/auth/pages/login_page.dart';
import 'src/features/auth/pages/signup_page.dart';
import 'src/features/auth/pages/splash_page.dart';
import 'src/features/auth/pages/home_page.dart';
import 'src/features/product/pages/cart_page.dart';
import 'src/features/product/pages/product_detail_page.dart';
import 'src/features/product/pages/product_list_page.dart';
import 'src/features/order/pages/order_history_page.dart';
import 'src/features/order/pages/order_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ❌ Baris ini tidak perlu:
  // WebViewPlatform.instance = AndroidWebView();

  Bloc.observer = SimpleBlocObserver(); // opsional untuk debug

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<CartBloc>(create: (_) => CartBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Toko Kabel App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashPage(),
          '/': (context) => LoginPage(),
          '/signup': (context) => SignupPage(),
          '/home': (context) => const HomePage(),
          '/cart': (context) => const CartPage(),
          '/product-list': (context) => const ProductListPage(),
          '/product-detail': (context) => const ProductDetailPage(productData: {}),
          '/order-history': (context) => const OrderHistoryPage(),
          '/order-detail': (context) => const OrderDetailPage(orderData: {}),
          '/admin-login': (context) => const AdminLoginPage(),
          '/admin-dashboard': (context) => const AdminDashboardPage(),
        },
      ),
    );
  }
}

class SimpleBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('❌ BLoC Error in ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    debugPrint('🔄 BLoC State Change in ${bloc.runtimeType}: $change');
    super.onChange(bloc, change);
  }
}
