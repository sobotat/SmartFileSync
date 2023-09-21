import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:smart_file_sync/main.dart';
import 'package:smart_file_sync/src/config/AppData.dart';
import 'package:smart_file_sync/src/security/AppSecurity.dart';
import 'package:smart_file_sync/src/services/NetworkChecker.dart';
import 'package:smart_file_sync/ui/fileSend/SendFileScreen.dart';
import 'package:smart_file_sync/ui/main/SelectScreen.dart';
import 'package:smart_file_sync/ui/network/NoInternetScreen.dart';
import 'package:smart_file_sync/ui/pair/PairScreen.dart';

class AppRouter {

  static final instance = AppRouter();

  late final GoRouter router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        name: '/',
        redirect: (context, state) {
          if (!AppData.instance.isPair()) return '/pair';
          return null;
        },
        builder: (context, state) {
          return const SelectScreen();
        },
        routes: [
          GoRoute(
            path: 'sync_file',
            name: 'sync-file',
            builder: (context, state) {
              return const Placeholder();
            },
          ),
          GoRoute(
            path: 'send_file',
            name: 'send-file',
            builder: (context, state) {
              return const SendFileScreen();
            },
          ),
          GoRoute(
            path: 'chat',
            name: 'chat',
            builder: (context, state) {
              return const Placeholder();
            },
          ),
        ]
      ),
      GoRoute(
        path: '/pair',
        name: 'pair',
        builder: (context, state) {
          return const PairScreen();
        },
      ),
      GoRoute(
        path: '/no-internet',
        name: 'no-internet',
        builder: (context, state) {
          return NoInternetScreen(path: state.uri.queryParameters['path'] ?? '/');
        },
      ),
    ],

    observers: [ _RouterObserver() ],
  );

  GoRouterRedirect authCheckRedirect = (context, state) {
    // Check if Active redirect
    if (state.uri.toString() != state.matchedLocation) return null;

    // Check user if is Init
    if(AppSecurity.instance.isInit) {
      if (!AppSecurity.instance.isLoggedIn()) {
        debugPrint('Redirecting to Sign-In Page (User Not LoggedIn)');
        return '/sign-in?path=${state.uri}';
      }
      return null;
    }

    // If not Init will wait for Init
    Future.delayed(Duration.zero, () {
      Function() listener = () { };
      listener = () {
        if(context.mounted){
          if (!AppSecurity.instance.isLoggedIn()) {
            debugPrint('Redirecting to Sign-In Page (User Not LoggedIn) [Listener]');
            AppRouter.instance.router.go('/sign-in?path=${state.uri}');
          }
        }
        AppSecurity.instance.removeListener(listener);
      };
      AppSecurity.instance.addListener(listener);
    });

    return null;
  };

  void setNetworkListener() {
    listener() {
      var networkChecker = NetworkChecker.instance;
      if (networkChecker.isInit && !networkChecker.haveInternet) {
        debugPrint('Redirecting to No Internet Page');
        router.goNamed('no-internet');
      }
    }
    NetworkChecker.instance.addListener(listener);
    NetworkChecker.instance.checkConnection();
  }
}

class _RouterObserver extends NavigatorObserver {

  // Check on Pop (On going back)
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppRouter.instance.router.refresh();
    });
  }
}