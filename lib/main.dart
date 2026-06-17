import 'dart:math';

import 'package:advance_expanse_tracker_app/presentation/receipt_scanner/screens/reciept_scanner_screen.dart';
import 'package:advance_expanse_tracker_app/presentation/settings/screens/profile_screen.dart';
import 'package:advance_expanse_tracker_app/state/providers/receipt_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'data/datasources/local/hive_datasources.dart';
import 'data/datasources/remote/auth_datasource.dart';
import 'data/datasources/remote/firestore_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/user_repository.dart';
import 'state/providers/auth_provider.dart';
import 'state/providers/theme_provider.dart';
import 'state/providers/transaction_provider.dart';
import 'state/providers/analytics_provider.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_screen.dart';
import 'presentation/auth/screens/forgot_password_screen.dart';
import 'presentation/home/screens/home_screen.dart';
import 'presentation/add_transaction/screens/add_transaction_screen.dart';
import 'presentation/analytics/screens/analytics_screen.dart';
import 'presentation/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final hiveDataSource = HiveDataSource();
  await hiveDataSource.init();

  runApp(ExpenseTrackerApp(hiveDataSource: hiveDataSource));
}

class ExpenseTrackerApp extends StatelessWidget {
  final HiveDataSource hiveDataSource;

  const ExpenseTrackerApp({
    super.key,
    required this.hiveDataSource,
  });

  @override
  Widget build(BuildContext context) {
    final authDataSource = AuthDataSource();
    final firestoreDataSource = FirestoreDataSource();

    final authRepository = AuthRepository(
      authDataSource: authDataSource,
      firestoreDataSource: firestoreDataSource,
      hiveDataSource: hiveDataSource,
    );

    final transactionRepository = TransactionRepository(
      hiveDataSource: hiveDataSource,
      firestoreDataSource: firestoreDataSource,
    );

    final userRepository = UserRepository(
      hiveDataSource: hiveDataSource,
      firestoreDataSource: firestoreDataSource,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(hiveDataSource: hiveDataSource),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository)
            ..initializeAuth()
            ..listenToAuthChanges(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReceiptProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider?>(
          create: (_) => null,
          update: (_, authProvider, __) {
            if (authProvider.currentUserId != null) {
              return TransactionProvider(
                transactionRepository: transactionRepository,
                userId: authProvider.currentUserId!,
              );
            }
            return null;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AnalyticsProvider?>(
          create: (_) => null,
          update: (_, authProvider, __) {
            if (authProvider.currentUserId != null) {
              return AnalyticsProvider(
                transactionRepository: transactionRepository,
                userId: authProvider.currentUserId!,
              );
            }
            return null;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRoutes.splash:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
                case AppRoutes.login:
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  );
                case AppRoutes.register:
                  return MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  );
                case AppRoutes.forgotPassword:
                  return MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  );
                case AppRoutes.home:
                  return MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  );
                case AppRoutes.addTransaction:
                  return MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  );
                case AppRoutes.editTransaction:
                  return MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      transactionId: settings.arguments as String?,
                    ),
                  );
                case AppRoutes.analytics:
                  return MaterialPageRoute(
                    builder: (_) => const AnalyticsScreen(),
                  );
                case AppRoutes.settings:
                  return MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  );
              case AppRoutes.profile:
                  return MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  );
                case AppRoutes.receiptScanner:
                  return MaterialPageRoute(
                    builder: (_) => const ReceiptScannerScreen(),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

/// Splash screen to determine initial route
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textController.forward();
    });

    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    final route = authProvider.isAuthenticated
        ? AppRoutes.home
        : AppRoutes.login;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: route == AppRoutes.home
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withOpacity(0.95),
                      const Color(0xFF111827),
                      const Color(0xFF030712),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              CustomPaint(
                size: Size.infinite,
                painter: GridBackgroundPainter(
                  progress: _bgController.value,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),

              CustomPaint(
                size: Size.infinite,
                painter: ParticlePainter(
                  progress: _bgController.value,
                  color: Colors.white.withOpacity(0.18),
                ),
              ),

              Positioned(
                top: -90,
                right: -70,
                child: _GlowCircle(
                  size: 220,
                  color: primary.withOpacity(0.25),
                ),
              ),

              Positioned(
                bottom: -100,
                left: -80,
                child: _GlowCircle(
                  size: 260,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _logoController,
                          curve: Curves.elasticOut,
                        ),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _logoController,
                            curve: Curves.easeOut,
                          ),
                          child: Container(
                            height: 132,
                            width: 132,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(38),
                              color: Colors.white.withOpacity(0.10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.45),
                                  blurRadius: 45,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 25,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 92,
                                  width: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                Image.asset(
                                  "assets/images/wallet.png",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      FadeTransition(
                        opacity: _textController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.35),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _textController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'EXPENSE TRACKER',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Take control of every rupee',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.78),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 58),

                      AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              SizedBox(
                                width: 210,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: LinearProgressIndicator(
                                    value: _loadingController.value,
                                    minHeight: 5.5,
                                    backgroundColor:
                                    Colors.white.withOpacity(0.15),
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Track • Save • Grow',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.72),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 35,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      "Powered by Firebase",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 35,
          ),
        ],
      ),
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  final double progress;
  final Color color;

  GridBackgroundPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 42.0;
    final offset = progress * spacing;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x + offset, 0),
        Offset(x + offset, size.height),
        paint,
      );
    }

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y + offset),
        Offset(size.width, y + offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = Random(18);

    for (int i = 0; i < 34; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final dy = sin((progress * 2 * pi) + i) * 18;
      final dx = cos((progress * 2 * pi) + i) * 8;

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        random.nextDouble() * 2.5 + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}