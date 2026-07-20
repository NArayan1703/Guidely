part of '../main.dart';

Future<void> main() async {
  await initializeSupabase();
  runApp(const GuidelyApp());
}

Future<void> initializeSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xzyvhcjncytrewuwyjbj.supabase.co',
    publishableKey: 'sb_publishable_f-WiZdjbdFy0B09GEuukng_8aUuOcVe',
  );
  _supabaseReady = true;
}

class GuidelyApp extends StatelessWidget {
  const GuidelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      surface: _surface,
    );
    return MaterialApp(
      title: 'Guidely',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _surface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E5E3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E5E3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          indicatorColor: const Color(0xFFD9F1EC),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _ink,
          displayColor: _ink,
        ),
      ),
      home: const _SessionGate(),
      routes: {'/admin': (_) => const _LoginScreen(role: _UserRole.admin)},
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  StreamSubscription<AuthState>? _authSubscription;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    if (!_supabaseReady) return;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) setState(() => _home = const _UpdatePasswordScreen());
        return;
      }
      _resolveHome(state.session?.user);
    });
    _resolveHome(Supabase.instance.client.auth.currentUser);
  }

  Future<void> _resolveHome(User? user) async {
    Widget home = const _WelcomeScreen();
    if (user != null) {
      if (user.appMetadata['role'] == 'admin') {
        home = const _AdminHome();
      } else {
        try {
          final guide = await Supabase.instance.client
              .from('guides')
              .select('user_id')
              .eq('user_id', user.id)
              .maybeSingle();
          home = guide == null ? const ExploreScreen() : const _GuideHome();
        } on PostgrestException {
          home = const ExploreScreen();
        }
      }
    }
    if (mounted && Supabase.instance.client.auth.currentUser?.id == user?.id) {
      setState(() => _home = home);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supabaseReady) return const _WelcomeScreen();
    return _home ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
