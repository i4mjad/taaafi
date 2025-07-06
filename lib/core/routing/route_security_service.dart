import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/account/application/ban_warning_facade.dart';
import '../../features/account/application/startup_security_service.dart';

part 'route_security_service.g.dart';

/// Service responsible for handling route redirection logic with security checks
/// This service integrates authentication state and security state to determine
/// the appropriate route for the user during navigation
class RouteSecurityService {
  final BanWarningFacade _facade;
  final FirebaseAuth _auth;

  // Store the latest security result for the banned screen
  SecurityCheckResult? _lastSecurityResult;

  RouteSecurityService({
    BanWarningFacade? facade,
    FirebaseAuth? auth,
  })  : _facade = facade ?? BanWarningFacade(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Determines the appropriate redirect path based on authentication and security state
  /// Returns null if no redirect is needed, otherwise returns the redirect path
  Future<String?> getRedirectPath(GoRouterState state) async {
    try {
      // Step 1: Check device bans FIRST (highest priority - affects all users)
      final deviceBanResult = await _checkDeviceBans();

      // Store the device ban result for the banned screen
      if (deviceBanResult.isDeviceBanned) {
        _lastSecurityResult = deviceBanResult;
        return _handleSecurityBlockedRedirect(deviceBanResult);
      }

      // Step 2: Check authentication state
      final firebaseUser = _auth.currentUser;
      final bool isLoggedIn = firebaseUser != null;

      // Step 3: If user is not authenticated, handle unauthenticated routes
      if (!isLoggedIn) {
        return _handleUnauthenticatedRedirect(state);
      }

      // Step 4: User is authenticated, check user-specific security state
      final userSecurityResult = await _checkUserSecurityState();

      // Store the security result for the banned screen
      _lastSecurityResult = userSecurityResult;

      // Step 5: Handle user security-based redirects
      if (userSecurityResult.isBlocked) {
        return _handleSecurityBlockedRedirect(userSecurityResult);
      }

      // Step 6: Handle normal authenticated user redirects
      return _handleAuthenticatedRedirect(state);
    } catch (e) {
      // On error, fall back to basic authentication logic
      return _handleFallbackRedirect(state);
    }
  }

  /// Handle redirects for unauthenticated users
  String? _handleUnauthenticatedRedirect(GoRouterState state) {
    final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
    final isLoadingRoute = state.matchedLocation == '/loading';

    // Allow onboarding and loading routes for unauthenticated users
    if (isOnboardingRoute || isLoadingRoute) {
      return null;
    }

    // Redirect to onboarding for all other routes
    return '/onboarding';
  }

  /// Handle redirects for authenticated users
  String? _handleAuthenticatedRedirect(GoRouterState state) {
    final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
    final isLoadingRoute = state.matchedLocation == '/loading';

    // If authenticated user is on onboarding or loading, redirect to home
    if (isOnboardingRoute || isLoadingRoute) {
      return '/home';
    }

    // Allow access to all other routes
    return null;
  }

  /// Handle redirects for users who are blocked due to security issues
  String? _handleSecurityBlockedRedirect(SecurityCheckResult securityResult) {
    // Redirect to the banned screen for all types of bans
    // The banned screen will handle displaying the appropriate message
    // based on the security result

    if (securityResult.isDeviceBanned || securityResult.isUserBanned) {
      return '/banned';
    }

    return null;
  }

  /// Fallback redirect logic when security checks fail
  String? _handleFallbackRedirect(GoRouterState state) {
    final firebaseUser = _auth.currentUser;
    final bool isLoggedIn = firebaseUser != null;

    if (isLoggedIn) {
      if (state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation == '/loading') {
        return '/home';
      }
      return null;
    } else {
      final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
      if (!isOnboardingRoute && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
    }

    return null;
  }

  /// Check device bans (affects all users regardless of authentication)
  Future<SecurityCheckResult> _checkDeviceBans() async {
    try {
      // Get device ID for ban checking
      final deviceId = await _facade.getCurrentDeviceId();
      final deviceBans = await _facade.getDeviceBans(deviceId);

      if (deviceBans.isNotEmpty) {
        return SecurityCheckResult.deviceBanned(
          message: 'Device is banned from accessing the application',
          deviceId: deviceId,
        );
      }

      return SecurityCheckResult.allowed();
    } catch (e) {
      // On error, we'll allow access but log the error
      return SecurityCheckResult.error(error: e.toString());
    }
  }

  /// Check user-specific security state (only for authenticated users)
  Future<SecurityCheckResult> _checkUserSecurityState() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return SecurityCheckResult.unauthenticated();
      }

      // Check user bans
      final isUserBanned = await _facade.isCurrentUserBannedFromApp();
      if (isUserBanned) {
        return SecurityCheckResult.userBanned(
          message: 'User account is banned from the application',
          userId: user.uid,
        );
      }

      return SecurityCheckResult.allowed();
    } catch (e) {
      // On error, we'll allow access but log the error
      return SecurityCheckResult.error(error: e.toString());
    }
  }

  /// Get the last security result for the banned screen
  /// This is used to pass the security result to the banned screen
  SecurityCheckResult? getLastSecurityResult() {
    return _lastSecurityResult;
  }

  /// Convert SecurityCheckResult to SecurityStartupResult for the banned screen
  SecurityStartupResult convertToStartupResult(
      SecurityCheckResult securityResult) {
    if (securityResult.isDeviceBanned) {
      return SecurityStartupResult.deviceBanned(
        message: securityResult.message ??
            'Device is banned from accessing the application',
        deviceId: securityResult.deviceId ?? '',
      );
    }

    if (securityResult.isUserBanned) {
      return SecurityStartupResult.userBanned(
        message: securityResult.message ??
            'User account is banned from the application',
        userId: securityResult.userId ?? '',
      );
    }

    // Fallback for other cases
    return SecurityStartupResult.warning(
      message: securityResult.message ?? 'Security check failed',
      error: securityResult.error ?? 'Unknown error',
    );
  }
}

/// Result of security check for routing decisions
class SecurityCheckResult {
  final SecurityCheckStatus status;
  final String? message;
  final String? deviceId;
  final String? userId;
  final String? error;

  const SecurityCheckResult._({
    required this.status,
    this.message,
    this.deviceId,
    this.userId,
    this.error,
  });

  factory SecurityCheckResult.allowed() => const SecurityCheckResult._(
        status: SecurityCheckStatus.allowed,
      );

  factory SecurityCheckResult.deviceBanned({
    required String message,
    required String deviceId,
  }) =>
      SecurityCheckResult._(
        status: SecurityCheckStatus.deviceBanned,
        message: message,
        deviceId: deviceId,
      );

  factory SecurityCheckResult.userBanned({
    required String message,
    required String userId,
  }) =>
      SecurityCheckResult._(
        status: SecurityCheckStatus.userBanned,
        message: message,
        userId: userId,
      );

  factory SecurityCheckResult.unauthenticated() => const SecurityCheckResult._(
        status: SecurityCheckStatus.unauthenticated,
      );

  factory SecurityCheckResult.error({required String error}) =>
      SecurityCheckResult._(
        status: SecurityCheckStatus.error,
        error: error,
      );

  bool get isBlocked =>
      status == SecurityCheckStatus.deviceBanned ||
      status == SecurityCheckStatus.userBanned;

  bool get isDeviceBanned => status == SecurityCheckStatus.deviceBanned;
  bool get isUserBanned => status == SecurityCheckStatus.userBanned;
  bool get isAllowed => status == SecurityCheckStatus.allowed;
  bool get hasError => status == SecurityCheckStatus.error;
}

enum SecurityCheckStatus {
  allowed,
  deviceBanned,
  userBanned,
  unauthenticated,
  error,
}

@riverpod
RouteSecurityService routeSecurityService(RouteSecurityServiceRef ref) {
  return RouteSecurityService();
}
