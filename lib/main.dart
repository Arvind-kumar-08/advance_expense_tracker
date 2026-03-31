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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
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
    // Initialize data sources
    final authDataSource = AuthDataSource();
    final firestoreDataSource = FirestoreDataSource();

    // Initialize repositories
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
        // Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(hiveDataSource: hiveDataSource),
        ),

        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository)
            ..initializeAuth()
            ..listenToAuthChanges(),
        ),

        // Transaction Provider (requires auth)
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

        // Analytics Provider (requires auth)
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait a bit for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              Text(
                'Expense Tracker',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Track your finances',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.red.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}