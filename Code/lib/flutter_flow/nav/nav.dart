import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:nwu_hms/pages/privacy_policy/privacy_policy.dart';
import 'package:provider/provider.dart';


import '/backend/schema/structs/index.dart';

import '/auth/custom_auth/custom_auth_user_provider.dart';

import '/index.dart';
import '/flutter_flow/flutter_flow_util.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  NwuHmsAuthUser? initialUser;
  NwuHmsAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading {
    final result = user == null || showSplashImage;
    developer.log(
        '⏳ Loading state check - user: ${user != null ? "exists" : "null"}, showSplashImage: $showSplashImage, result: $result',
        name: 'Navigation');
    return result;
  }

  bool get loggedIn {
    final result = user?.loggedIn ?? false;
    developer.log(
        '👤 LoggedIn state check - user: ${user != null ? "exists" : "null"}, loggedIn: $result',
        name: 'Navigation');
    return result;
  }

  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() {
    developer.log('📍 Getting redirect location: $_redirectLocation',
        name: 'Navigation');
    return _redirectLocation!;
  }

  bool hasRedirect() {
    final result = _redirectLocation != null;
    developer.log('📍 Has redirect check: $result ($_redirectLocation)',
        name: 'Navigation');
    return result;
  }

  void setRedirectLocationIfUnset(String loc) {
    developer.log(
        '📍 Setting redirect location if unset: $loc (current: $_redirectLocation)',
        name: 'Navigation');
    _redirectLocation ??= loc;
  }

  void clearRedirectLocation() {
    developer.log('🧹 Clearing redirect location (was: $_redirectLocation)',
        name: 'Navigation');
    _redirectLocation = null;
  }

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) {
    developer.log(
        '🔔 Updating notifyOnAuthChange: $notify (was: $notifyOnAuthChange)',
        name: 'Navigation');
    notifyOnAuthChange = notify;
  }

  void update(NwuHmsAuthUser newUser) {
    developer.log('🔄 AppStateNotifier.update called', name: 'Navigation');
    developer.log('📝 Current user: ${user?.uid ?? "null"}',
        name: 'Navigation');
    developer.log('📝 New user: ${newUser.uid ?? "null"}', name: 'Navigation');
    developer.log('📝 New user logged in: ${newUser.loggedIn}',
        name: 'Navigation');

    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;

    developer.log('📝 Should update: $shouldUpdate', name: 'Navigation');
    developer.log('📝 Notify on auth change: $notifyOnAuthChange',
        name: 'Navigation');

    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      developer.log('🔔 Notifying listeners of auth change',
          name: 'Navigation');
      notifyListeners();
    } else {
      developer.log(
          '🔕 Skipping notification - notifyOnAuthChange: $notifyOnAuthChange, shouldUpdate: $shouldUpdate',
          name: 'Navigation');
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    developer.log('🎬 Stopping splash image display', name: 'Navigation');
    showSplashImage = false;
    developer.log(
        '⏳ Loading state after splash stop - user: ${user != null ? "exists" : "null"}, showSplashImage: $showSplashImage, loading: $loading',
        name: 'Navigation');
    notifyListeners();
    developer.log('🔔 Notified listeners after stopping splash',
        name: 'Navigation');
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) {
  developer.log('🏗️ Creating GoRouter', name: 'Navigation');
  developer.log('📍 Initial location: /', name: 'Navigation');

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: appStateNotifier,
    errorBuilder: (context, state) {
      developer.log('❌ Error in router - building error page',
          name: 'Navigation');
      developer.log('📍 Error state location: ${state.uri}',
          name: 'Navigation');
      developer.log('📝 User logged in: ${appStateNotifier.loggedIn}',
          name: 'Navigation');
      return appStateNotifier.loggedIn
          ? const HomeWidget()
          : const LoginWidget();
    },
    routes: [
      FFRoute(
        name: '_initialize',
        path: '/',
        builder: (context, _) {
          developer.log('🚀 Building _initialize route', name: 'Navigation');
          developer.log('📝 User logged in: ${appStateNotifier.loggedIn}',
              name: 'Navigation');
          developer.log(
              '⏳ Loading state in builder: ${appStateNotifier.loading}',
              name: 'Navigation');

          // Check loading state inside the builder
          if (appStateNotifier.loading) {
            developer.log('⏳ Still loading - showing splash from builder',
                name: 'Navigation');
            return Container(
              color: const Color(0xFF57045E),
              child: Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Image.asset(
                    'assets/images/splash.png',
                  ),
                ),
              ),
            );
          }

          developer.log('✅ Not loading - showing actual page',
              name: 'Navigation');
          return appStateNotifier.loggedIn
              ? const HomeWidget()
              : const LoginWidget();
        },
      ),
      FFRoute(
        name: 'login',
        path: '/login',
        builder: (context, params) => const LoginWidget(),
      ),
      FFRoute(
        name: 'assignment',
        path: '/assignment',
        requireAuth: true,
        builder: (context, params) => const AssignmentWidget(),
      ),
      FFRoute(
        name: 'addUser',
        path: '/addUser',
        requireAuth: true,
        builder: (context, params) => const AddUserWidget(),
      ),
      FFRoute(
        name: 'forgotPassword',
        path: '/forgotPassword',
        builder: (context, params) => const ForgotPasswordWidget(),
      ),
      FFRoute(
        name: 'home',
        path: '/home',
        requireAuth: true,
        builder: (context, params) => const HomeWidget(),
      ),
      FFRoute(
        name: 'gradebook',
        path: '/gradebook',
        requireAuth: true,
        builder: (context, params) => const GradebookWidget(),
      ),
      FFRoute(
        name: 'gradebookLecturer',
        path: '/gradebookLecturer',
        requireAuth: true,
        builder: (context, params) => const GradebookLecturerWidget(),
      ),
      FFRoute(
        name: 'assignmentGradebookDetail',
        path: '/assignmentGradebookDetail',
        requireAuth: true,
        builder: (context, params) => AssignmentGradebookDetailWidget(
          assignmentID: params.getParam<int>(
            'assignmentID',
            ParamType.int,
          ),
          assignmentName: params.getParam<String>(
            'assignmentName',
            ParamType.String,
          ),
        ),
      ),
      FFRoute(
        name: 'updateUser',
        path: '/updateUser',
        requireAuth: true,
        builder: (context, params) => const UpdateUserWidget(),
      ),
      FFRoute(
        name: 'bulkUploadUsers',
        path: '/bulkUploadUsers',
        requireAuth: true,
        builder: (context, params) => const BulkUploadUsersWidget(),
      ),
      FFRoute(
        name: 'privacyPolicy',
        path: '/privacy-policy',
        requireAuth: false,
        builder: (context, params) => const PrivacyPolicyPage(),
      )
    ].map((r) => r.toRoute(appStateNotifier)).toList(),
    observers: [routeObserver],
  );
}

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) {
    developer.log('🧭 goNamedAuth called: $name', name: 'Navigation');
    developer.log('📱 Mounted: $mounted', name: 'Navigation');
    developer.log('🔀 Ignore redirect: $ignoreRedirect', name: 'Navigation');
    developer.log('📍 Path parameters: $pathParameters', name: 'Navigation');
    developer.log('❓ Query parameters: $queryParameters', name: 'Navigation');

    if (!mounted) {
      developer.log('❌ Widget not mounted - cancelling navigation',
          name: 'Navigation');
      return;
    }

    if (GoRouter.of(this).shouldRedirect(ignoreRedirect)) {
      developer.log('🔄 Should redirect - cancelling navigation',
          name: 'Navigation');
      return;
    }

    developer.log('✅ Proceeding with goNamed navigation', name: 'Navigation');
    goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) {
    developer.log('📤 pushNamedAuth called: $name', name: 'Navigation');
    developer.log('📱 Mounted: $mounted', name: 'Navigation');
    developer.log('🔀 Ignore redirect: $ignoreRedirect', name: 'Navigation');
    developer.log('📍 Path parameters: $pathParameters', name: 'Navigation');
    developer.log('❓ Query parameters: $queryParameters', name: 'Navigation');

    if (!mounted) {
      developer.log('❌ Widget not mounted - cancelling push navigation',
          name: 'Navigation');
      return;
    }

    if (GoRouter.of(this).shouldRedirect(ignoreRedirect)) {
      developer.log('🔄 Should redirect - cancelling push navigation',
          name: 'Navigation');
      return;
    }

    developer.log('✅ Proceeding with pushNamed navigation', name: 'Navigation');
    pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void safePop() {
    developer.log('⬅️ safePop called', name: 'Navigation');
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      developer.log('✅ Can pop - proceeding with pop()', name: 'Navigation');
      pop();
    } else {
      developer.log('🏠 Cannot pop - navigating to home (/)',
          name: 'Navigation');
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) {
    developer.log(
        '🔐 prepareAuthEvent called - ignoreRedirect: $ignoreRedirect',
        name: 'Navigation');
    developer.log('📍 Has redirect: ${appState.hasRedirect()}',
        name: 'Navigation');
    return appState.hasRedirect() && !ignoreRedirect
        ? null
        : appState.updateNotifyOnAuthChange(false);
  }

  bool shouldRedirect(bool ignoreRedirect) {
    final result = !ignoreRedirect && appState.hasRedirect();
    developer.log(
        '🔄 shouldRedirect check - ignoreRedirect: $ignoreRedirect, hasRedirect: ${appState.hasRedirect()}, result: $result',
        name: 'Navigation');
    return result;
  }

  void clearRedirectLocation() {
    developer.log('🧹 Clearing redirect location', name: 'Navigation');
    appState.clearRedirectLocation();
  }

  void setRedirectLocationIfUnset(String location) {
    developer.log('📍 Setting redirect location if unset: $location',
        name: 'Navigation');
    appState.updateNotifyOnAuthChange(false);
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) {
    developer.log('🏗️ Creating GoRoute for: $name ($path)',
        name: 'Navigation');
    return GoRoute(
      name: name,
      path: path,
      redirect: (context, state) {
        developer.log('🔀 Route redirect check for: $name ($path)',
            name: 'Navigation');
        developer.log('📍 Current location: ${state.uri}', name: 'Navigation');
        developer.log('🔐 Require auth: $requireAuth', name: 'Navigation');
        developer.log('👤 User logged in: ${appStateNotifier.loggedIn}',
            name: 'Navigation');
        developer.log('📍 Should redirect: ${appStateNotifier.shouldRedirect}',
            name: 'Navigation');

        // For routes that don't require auth, allow access regardless of auth state
        if (!requireAuth) {
          developer.log('✅ Route does not require auth - allowing access',
              name: 'Navigation');
          return null;
        }

        if (appStateNotifier.shouldRedirect) {
          final redirectLocation = appStateNotifier.getRedirectLocation();
          developer.log('🔄 Redirecting to stored location: $redirectLocation',
              name: 'Navigation');
          appStateNotifier.clearRedirectLocation();
          return redirectLocation;
        }

        if (requireAuth && !appStateNotifier.loggedIn) {
          developer.log(
              '🔒 Auth required but user not logged in - redirecting to login',
              name: 'Navigation');
          appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
          return '/login';
        }

        developer.log('✅ No redirect needed for route: $name',
            name: 'Navigation');
        return null;
      },
      pageBuilder: (context, state) {
        developer.log('📄 Building page for route: $name', name: 'Navigation');
        developer.log('📍 Page location: ${state.uri}', name: 'Navigation');
        developer.log('🔄 App loading: ${appStateNotifier.loading}',
            name: 'Navigation');

        fixStatusBarOniOS16AndBelow(context);
        final ffParams = FFParameters(state, asyncParams);

        developer.log('🔮 Has future params: ${ffParams.hasFutures}',
            name: 'Navigation');

        final page = ffParams.hasFutures
            ? FutureBuilder(
                future: ffParams.completeFutures(),
                builder: (context, snapshot) {
                  developer.log(
                      '🔮 FutureBuilder state: ${snapshot.connectionState}',
                      name: 'Navigation');
                  if (snapshot.hasError) {
                    developer.log('❌ FutureBuilder error: ${snapshot.error}',
                        name: 'Navigation');
                  }
                  return builder(context, ffParams);
                },
              )
            : builder(context, ffParams);

        final child = (appStateNotifier.loading && name == '_initialize')
            ? Container(
                color: const Color(0xFF57045E),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Image.asset(
                    'assets/images/splash.png',
                  ),
                ),
              )
            : page;

        if (appStateNotifier.loading && name == '_initialize') {
          developer.log('⏳ Showing loading screen for _initialize route',
              name: 'Navigation');
        } else {
          developer.log('✅ Showing page content for: $name',
              name: 'Navigation');
        }

        final transitionInfo = state.transitionInfo;
        return transitionInfo.hasTransition
            ? CustomTransitionPage(
                key: state.pageKey,
                child: child,
                transitionDuration: transitionInfo.duration,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  developer.log('🎭 Using custom transition for: $name',
                      name: 'Navigation');
                  return PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  );
                },
              )
            : MaterialPage(key: state.pageKey, child: child);
      },
      routes: routes,
    );
  }
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
