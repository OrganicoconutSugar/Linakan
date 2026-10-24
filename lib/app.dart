import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/models/listing_model.dart';
import 'providers/auth_provider.dart';
import 'ui/admin/admin_dashboard_screen.dart';
import 'ui/admin/admin_listings_screen.dart';
import 'ui/admin/admin_transactions_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/otp_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/auth/video_intro_screen.dart';
import 'ui/farmer/farmer_checkout_screen.dart';
import 'ui/farmer/farmer_dashboard_screen.dart';
import 'ui/farmer/farmer_intro_screen.dart';
import 'ui/farmer/farmer_listing_detail_screen.dart';
import 'ui/farmer/farmer_marketplace_screen.dart';
import 'ui/farmer/farmer_matches_screen.dart';
import 'ui/farmer/farmer_profile_screen.dart';
import 'ui/farmer/farmer_onboarding_screen.dart';
import 'ui/farmer/farmer_transactions_screen.dart';
import 'ui/seller/create_listing_screen.dart';
import 'ui/seller/listing_preview_screen.dart';
import 'ui/seller/seller_about_screen.dart';
import 'ui/seller/seller_dashboard_screen.dart';
import 'ui/seller/seller_intro_screen.dart';
import 'ui/seller/seller_listings_screen.dart';
import 'ui/seller/seller_profile_screen.dart';
import 'ui/seller/seller_transactions_screen.dart';
import 'ui/wallet/wallet_screen.dart';

// ---------------------------------------------------------------------------
// Router dengan redirect otomatis ke login jika belum login
// ---------------------------------------------------------------------------

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/intro-video',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final onAuthPage = state.matchedLocation.startsWith('/auth');
      final onVideoIntro = state.matchedLocation == '/intro-video';

      // Belum login & bukan di halaman auth → paksa ke login
      if (!loggedIn && !onAuthPage && !onVideoIntro) return '/auth/login';

      // Sudah login & masih di halaman login/register → ke dashboard
      if (loggedIn && state.matchedLocation == '/auth/login') {
        return _dashboardRoute(authProvider);
      }
      if (loggedIn && state.matchedLocation == '/auth/register') {
        return _dashboardRoute(authProvider);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/intro-video',
        builder: (context, state) => const VideoIntroScreen(),
      ),
      // -------------------------------------------------------------------
      // Auth
      // -------------------------------------------------------------------
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        redirect: (context, state) =>
            state.extra is OtpArgs ? null : '/auth/login',
        builder: (context, state) {
          final args = state.extra as OtpArgs;
          return OtpScreen(args: args);
        },
      ),
      // Root redirect
      GoRoute(
        path: '/',
        redirect: (_, __) => '/intro-video',
      ),
      // -------------------------------------------------------------------
      // Seller
      // -------------------------------------------------------------------
      GoRoute(
        path: '/seller/intro',
        builder: (context, state) => const SellerIntroScreen(),
      ),
      GoRoute(
        path: '/seller/about',
        builder: (context, state) => const SellerAboutScreen(),
      ),
      GoRoute(
        path: '/seller/dashboard',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/seller/create-listing',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/seller/listing-preview',
        redirect: (context, state) =>
            state.extra is ListingModel ? null : '/seller/listings',
        builder: (context, state) {
          final listing = state.extra as ListingModel;
          return ListingPreviewScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/seller/listings',
        builder: (context, state) => const SellerListingsScreen(),
      ),
      GoRoute(
        path: '/seller/transactions',
        builder: (context, state) => const SellerTransactionsScreen(),
      ),
      GoRoute(
        path: '/seller/profile',
        builder: (context, state) => const SellerProfileScreen(),
      ),
      // -------------------------------------------------------------------
      // Farmer
      // -------------------------------------------------------------------
      GoRoute(
        path: '/farmer/onboarding',
        builder: (context, state) => const FarmerOnboardingScreen(),
      ),
      GoRoute(
        path: '/farmer/intro',
        builder: (context, state) => const FarmerIntroScreen(),
      ),
      GoRoute(
        path: '/farmer/dashboard',
        builder: (context, state) => const FarmerDashboardScreen(),
      ),
      GoRoute(
        path: '/farmer/matches',
        builder: (context, state) => const FarmerMatchesScreen(),
      ),
      GoRoute(
        path: '/farmer/marketplace',
        builder: (context, state) => const FarmerMarketplaceScreen(),
      ),
      GoRoute(
        path: '/farmer/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FarmerListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/farmer/checkout/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FarmerCheckoutScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/farmer/transactions',
        builder: (context, state) => const FarmerTransactionsScreen(),
      ),
      GoRoute(
        path: '/farmer/profile',
        builder: (context, state) => const FarmerProfileScreen(),
      ),
      // -------------------------------------------------------------------
      // Wallet
      // -------------------------------------------------------------------
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      // -------------------------------------------------------------------
      // Admin
      // -------------------------------------------------------------------
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/listings',
        builder: (context, state) => const AdminListingsScreen(),
      ),
      GoRoute(
        path: '/admin/transactions',
        builder: (context, state) => const AdminTransactionsScreen(),
      ),
    ],
  );
}

String _dashboardRoute(AuthProvider auth) {
  return auth.authenticatedHomeRoute;
}

// ---------------------------------------------------------------------------
// Widget root aplikasi LINAKAN
// ---------------------------------------------------------------------------

class LinakanApp extends StatefulWidget {
  final AuthProvider authProvider;
  const LinakanApp({super.key, required this.authProvider});

  @override
  State<LinakanApp> createState() => _LinakanAppState();
}

class _LinakanAppState extends State<LinakanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(widget.authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan authProvider bisa diakses oleh seluruh widget tree via context
    return ChangeNotifierProvider<AuthProvider>.value(
      value: widget.authProvider,
      child: MaterialApp.router(
        title: 'LINAKAN',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: buildAppTheme(),
      ),
    );
  }
}
