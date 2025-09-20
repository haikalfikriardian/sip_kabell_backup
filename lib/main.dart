import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Blocs
import 'src/features/auth/bloc/auth_bloc.dart';
import 'src/blocs/cart/cart_bloc.dart';

// ✅ Theme (baru)
import 'src/theme/theme_cubit.dart';
import 'src/theme/app_theme.dart';

// Pages
import 'src/admin/dashboard/admin_dashboard_page.dart';
import 'src/admin/pages/admin_login_page.dart';
import 'src/features/address/pages/edit_address_page.dart';
import 'src/features/auth/pages/forgot_password_page.dart';
import 'src/features/auth/pages/login_page.dart';
import 'src/features/auth/pages/signup_page.dart';
import 'src/features/auth/pages/splash_page.dart';
import 'src/features/auth/pages/home_page.dart';
import 'src/features/catalogs/pages/catalog_download_page.dart';
import 'src/features/checkout/pages/checkout_page.dart';
import 'src/features/notifications/pages/notification_page.dart';
import 'src/features/order/pages/order_detail_page.dart';
import 'src/features/order/pages/order_history_page.dart';
import 'src/features/product/pages/cart_page.dart';
import 'src/features/product/pages/product_detail_page.dart';
import 'src/features/product/pages/product_list_page.dart';
import 'src/features/profile/pages/edit_profile_page.dart';
import 'src/features/profile/pages/my_profile_page.dart';
import 'src/features/shipping/pages/check_shipping_page.dart';
import 'src/features/about/pages/about_page.dart';

// ✅ Wishlist
import 'src/features/wishlist/pages/wishlist_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Bloc.observer = SimpleBlocObserver();

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
        // ✅ ThemeCubit untuk dark/light mode (auto load saat start)
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()..load()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Toko Kabel App',

            // ✅ Pakai theme global
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,

            initialRoute: '/splash',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(builder: (_) => LoginPage());
                case '/splash':
                  return MaterialPageRoute(builder: (_) => const SplashPage());
                case '/login':
                  return MaterialPageRoute(builder: (_) => LoginPage());
                case '/signup':
                  return MaterialPageRoute(builder: (_) => SignupPage());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomePage());
                case '/cart':
                  return MaterialPageRoute(builder: (_) => const CartPage());
                case '/product-list':
                  return MaterialPageRoute(builder: (_) => const ProductListPage());
                case '/product-detail':
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => ProductDetailPage(productData: args),
                  );
                case '/order-history':
                  return MaterialPageRoute(builder: (_) => const OrderHistoryPage());
                case '/order-detail':
                  final args = settings.arguments;
                  if (args is String) {
                    return MaterialPageRoute(
                      builder: (_) => OrderDetailPage(orderData: {'orderId': args}),
                    );
                  } else if (args is Map<String, dynamic>) {
                    return MaterialPageRoute(
                      builder: (_) => OrderDetailPage(orderData: args),
                    );
                  } else {
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Argument tidak valid untuk Order Detail')),
                      ),
                    );
                  }
                case '/admin-login':
                  return MaterialPageRoute(builder: (_) => const AdminLoginPage());
                case '/admin-dashboard':
                  return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
                case '/forgot-password':
                  return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
                case '/my-profile':
                  return MaterialPageRoute(builder: (_) => const MyProfilePage());
                case '/edit-profile':
                  return MaterialPageRoute(builder: (_) => const EditProfilePage());
                case '/notifications':
                  return MaterialPageRoute(builder: (_) => const NotificationPage());
                case '/catalog-download':
                  return MaterialPageRoute(builder: (_) => const CatalogDownloadPage());
                case '/edit-address':
                  return MaterialPageRoute(builder: (_) => const EditAddressPage());
                case '/cek-ongkir':
                  return MaterialPageRoute(builder: (_) => const CheckShippingPage());
                case '/wishlist':
                  return MaterialPageRoute(builder: (_) => const WishlistPage());
                case '/about':
                  return MaterialPageRoute(builder: (_) => const AboutPage());
                default:
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Halaman tidak ditemukan')),
                    ),
                  );
              }
            },
          );
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
