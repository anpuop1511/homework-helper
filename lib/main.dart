import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:app_links/app_links.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'providers/assignments_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/classes_provider.dart';
import 'providers/nav_bar_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/security_provider.dart';
import 'providers/social_provider.dart';
import 'providers/subjects_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/feature_drop_screen.dart';
import 'screens/group_projects_screen.dart';
import 'screens/join_invite_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();

  // Initialise Firebase via the single-source-of-truth bootstrap helper.
  // FirebaseBootstrap.ensureInitialized() is idempotent: it handles the
  // [core/duplicate-app] error that occurs when the native Android SDK
  // (google-services.json) initializes Firebase before Flutter's Dart layer,
  // and is also safe across Flutter hot restarts in development.
  await FirebaseBootstrap.ensureInitialized();
  final bool firebaseReady = FirebaseBootstrap.isReady;
  final String? firebaseInitError = FirebaseBootstrap.error;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => NavBarProvider()),
        ChangeNotifierProvider(create: (_) => SubjectsProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            firebaseReady: firebaseReady,
            firebaseInitError: firebaseInitError,
          ),
        ),
        // C-2: UserProvider is wired to AuthProvider so setUid() is called
        // whenever the user signs in or out, enabling cloud XP/level/streak sync.
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, prev) {
            final provider = prev ?? UserProvider();
            provider.setUid(auth.uid);
            return provider;
          },
        ),
        // SocialProvider is wired to both AuthProvider and UserProvider so it
        // receives the UID on auth changes and real user stats for friend-accept.
        ChangeNotifierProxyProvider2<AuthProvider, UserProvider, SocialProvider>(
          create: (_) => SocialProvider(),
          update: (_, auth, userProvider, prev) {
            final provider = prev ?? SocialProvider();
            provider.setUid(
              auth.uid,
              email: auth.email,
              name: auth.currentUser?.displayName,
              username: auth.username,
            );
            provider.updateUserProvider(userProvider);
            return provider;
          },
        ),
        // ClassesProvider is wired to AuthProvider for Firestore sync.
        ChangeNotifierProxyProvider<AuthProvider, ClassesProvider>(
          create: (_) => ClassesProvider(),
          update: (_, auth, prev) {
            final provider = prev ?? ClassesProvider();
            provider.setUid(auth.uid);
            return provider;
          },
        ),
        // ProjectsProvider is wired to AuthProvider for Firestore sync.
        ChangeNotifierProxyProvider<AuthProvider, ProjectsProvider>(
          create: (_) => ProjectsProvider(),
          update: (_, auth, prev) {
            final provider = prev ?? ProjectsProvider();
            provider.setUid(auth.uid);
            return provider;
          },
        ),
        // C-1: AssignmentsProvider is wired to both AuthProvider (for UID /
        // Firestore sync) and UserProvider (for awarding XP on completion).
        ChangeNotifierProxyProvider2<AuthProvider, UserProvider,
            AssignmentsProvider>(
          create: (_) => AssignmentsProvider(),
          update: (_, auth, userProvider, prev) {
            final provider = prev ?? AssignmentsProvider();
            provider.setUid(auth.uid);
            provider.updateUserProvider(userProvider);
            return provider;
          },
        ),
      ],
      child: const HomeworkHelperApp(),
    ),
  );
}

/// Routes to [LoginScreen] or [MainScaffold] based on [AuthProvider] state.
/// Also saves the user's email to Firestore so friends can search by email.
class _AuthGate extends StatefulWidget {
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _prevUid;
  Timer? _loadTimer;
  bool _showRetry = false;

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final uid = auth.uid;

    // Whenever the UID changes (sign-in / sign-out), sync the email to
    // Firestore so friends can look the user up by email.
    // Doing this in didChangeDependencies() (rather than build()) keeps
    // the build method free of Firestore side-effects (M-1).
    if (uid != _prevUid) {
      _prevUid = uid;
      // Reset retry state whenever the account changes.
      _loadTimer?.cancel();
      _loadTimer = null;
      _showRetry = false;
      if (uid != null && auth.email != null) {
        DatabaseService.instance
            .saveUserEmail(uid, auth.email!)
            .ignore();
      }
    }
  }

  /// Starts a one-shot timer that surfaces a Retry button if Firestore
  /// hasn't finished loading the username within 8 seconds.
  void _scheduleRetryIfNeeded() {
    if (_loadTimer != null) return; // already running
    _loadTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showRetry = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isSignedIn && !auth.isGuest) {
      // H-2: Wait for the initial auth state (including the persisted guest-mode
      // flag) to be loaded from SharedPreferences before routing.  Without this
      // guard a brief flash of LoginScreen appears on cold start for users who
      // were in guest mode, before _isGuest is restored asynchronously.
      if (!auth.initialStateReady) {
        return const SplashScreen();
      }
      return const LoginScreen();
    }

    // Guests get routed directly to the app without any Firestore username
    // loading (they have no UID), so skip the loading splash for them.
    if (auth.isGuest && !auth.isSignedIn) {
      return const _FeatureDropGate(child: MainScaffold());
    }

    // Show a minimal splash while the username is still being fetched from
    // Firestore so we don't flash the wrong screen.
    if (!auth.usernameLoaded) {
      _scheduleRetryIfNeeded();
      if (_showRetry) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Taking a while to connect…'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showRetry = false;
                      _loadTimer?.cancel();
                      _loadTimer = null;
                    });
                    auth.refreshUsername();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return const SplashScreen();
    }

    // Loading finished – cancel any pending retry timer.
    _loadTimer?.cancel();
    _loadTimer = null;

    return const _FeatureDropGate(child: MainScaffold());
  }
}

/// Wraps [MainScaffold] and triggers the Feature Drop splash once per update.
class _FeatureDropGate extends StatefulWidget {
  final Widget child;
  const _FeatureDropGate({required this.child});

  @override
  State<_FeatureDropGate> createState() => _FeatureDropGateState();
}

class _FeatureDropGateState extends State<_FeatureDropGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showFeatureDropIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Root widget for the Homework Helper application.
/// Configures Material 3 theming with light and dark mode support.
/// Uses [DynamicColorBuilder] to adopt the device's system accent color
/// when available (Android 12+ / Material You).
class HomeworkHelperApp extends StatelessWidget {
  const HomeworkHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vibe = context.watch<ThemeProvider>().vibe;
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Only use Material You dynamic colours when the user has selected
        // the "Device Colors" vibe; otherwise let the custom palette shine.
        final useDynamic = vibe == AppVibe.systemDynamic;
        return MaterialApp(
          title: 'Homework Helper',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(vibe, useDynamic ? lightDynamic : null),
          darkTheme: AppTheme.darkTheme(vibe, useDynamic ? darkDynamic : null),
          themeMode: ThemeMode.system,
          home: _DeepLinkHandler(child: _AppShieldGate(child: _AuthGate())),
        );
      },
    );
  }
}

/// Listens for incoming `homeworkhelper://` deep links and routes to the
/// appropriate screen (JoinInviteScreen or JoinProjectScreen).
///
/// Handles both the **initial link** (app cold-started via a link) and
/// **subsequent links** (app already running when a link is opened).
class _DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const _DeepLinkHandler({required this.child});

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  StreamSubscription<Uri>? _sub;

  /// Cold-start link that arrived before [AuthProvider] was fully initialised.
  /// Flushed in [build] once auth is ready so navigation is never orphaned (L-5).
  Uri? _pendingColdStartLink;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initLinks();
    }
  }

  Future<void> _initLinks() async {
    try {
      final appLinks = AppLinks();
      // Handle the link that launched the app (cold start).
      // Store it as pending and let build() flush it once auth is ready (L-5).
      final initial = await appLinks.getInitialLink();
      if (initial != null && mounted) {
        setState(() => _pendingColdStartLink = initial);
      }
      // Handle links while the app is already running (auth already ready).
      _sub = appLinks.uriLinkStream.listen(_handleLink, onError: (_) {});
    } catch (_) {
      // Deep link handling is best-effort.
    }
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'homeworkhelper') return;
    final ctx = context;
    if (!mounted) return;

    final host = uri.host;
    final pathSegments = uri.pathSegments;
    final id = pathSegments.isNotEmpty ? pathSegments.first : '';

    switch (host) {
      case 'profile':
      case 'u':
        // Profile links are handled by QrScanScreen; nothing to do here
        // unless we want to open PublicProfileScreen directly.
        break;
      case 'invite':
        if (id.isNotEmpty) {
          Navigator.of(ctx, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => JoinInviteScreen(inviteId: id),
            ),
          );
        }
        break;
      case 'project':
        if (id.isNotEmpty) {
          Navigator.of(ctx, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => JoinProjectScreen(projectId: id),
            ),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // L-5: Flush any queued cold-start deep link once the auth state is
    // fully initialised (username loaded or confirmed guest) so that
    // navigation is never pushed onto an uninitialised stack.
    if (_pendingColdStartLink != null) {
      final auth = context.watch<AuthProvider>();
      final ready = auth.initialStateReady &&
          (auth.isGuest || auth.usernameLoaded);
      if (ready) {
        // Schedule the actual navigation for after this build frame.
        // Use setState to clear _pendingColdStartLink so this doesn't
        // re-trigger on the next build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final link = _pendingColdStartLink;
          if (link == null) return;
          setState(() => _pendingColdStartLink = null);
          _handleLink(link);
        });
      }
    }
    return widget.child;
  }
}

/// Wraps the entire app and shows a biometric lock screen once per cold start
/// when [SecurityProvider.isAppLockEnabled] is on.
///
/// The lock is enforced exactly once per app process lifetime. After a
/// successful unlock, the app stays unlocked for the rest of the session
/// (even if the user backgrounds and foregrounds the app). Only killing and
/// relaunching the process will trigger the prompt again.
class _AppShieldGate extends StatefulWidget {
  final Widget child;
  const _AppShieldGate({required this.child});

  @override
  State<_AppShieldGate> createState() => _AppShieldGateState();
}

class _AppShieldGateState extends State<_AppShieldGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;

  /// True once the user has successfully unlocked during this app process.
  /// Not persisted to disk — resets only on cold start (process kill + relaunch).
  bool _unlockedThisSession = false;

  /// Guards against enqueuing redundant post-frame callbacks on every rebuild
  /// (L-4). Set to true once a callback has been scheduled and cleared after
  /// it fires.
  bool _coldStartCallbackScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Schedule the cold-start lock check after the first frame so all
    // providers (including SecurityProvider) are fully initialised.
    _scheduleCheckIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Enqueues [_checkColdStartLock] for the next frame, but only if a
  /// callback has not already been scheduled (L-4 performance fix).
  void _scheduleCheckIfNeeded() {
    if (_coldStartCallbackScheduled) return;
    _coldStartCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coldStartCallbackScheduled = false;
      _checkColdStartLock();
    });
  }

  /// Locks the app on cold start if App Lock is enabled. Calling this more
  /// than once is safe — the guards prevent double-locking.
  void _checkColdStartLock() {
    if (!mounted || kIsWeb || _locked || _authenticating || _unlockedThisSession) {
      return;
    }
    final security = context.read<SecurityProvider>();
    if (security.isAppLockEnabled) {
      setState(() => _locked = true);
      _unlock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App Lock is enforced only once per cold start (process launch).
    // Ignoring pause/resume transitions prevents the biometric prompt's own
    // lifecycle events from re-triggering the lock and creating prompt loops.
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final security = context.read<SecurityProvider>();
    final ok = await security.authenticate(reason: 'Unlock Homework Helper');
    if (!mounted) return;
    if (ok) _unlockedThisSession = true;
    setState(() {
      _authenticating = false;
      _locked = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch SecurityProvider so that if its initial async load completes after
    // the first frame, we still catch App Lock being enabled and trigger the
    // cold-start check. Only one post-frame callback is enqueued at a time
    // to avoid redundant calls on every rebuild (L-4).
    final security = context.watch<SecurityProvider>();
    if (!kIsWeb &&
        security.isAppLockEnabled &&
        !_unlockedThisSession &&
        !_locked &&
        !_authenticating) {
      _scheduleCheckIfNeeded();
    }

    if (_locked) {
      return _AppShieldOverlay(onUnlock: _unlock);
    }
    return widget.child;
  }
}

/// Full-screen overlay shown when the app is locked.
class _AppShieldOverlay extends StatelessWidget {
  final VoidCallback onUnlock;
  const _AppShieldOverlay({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeIn(
        duration: const Duration(milliseconds: 400),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(60),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'App Locked',
                style: GoogleFonts.lexend(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use biometrics or your PIN to continue.',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text(
                  'Unlock',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
