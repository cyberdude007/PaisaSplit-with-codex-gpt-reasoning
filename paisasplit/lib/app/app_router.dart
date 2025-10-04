import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/accounts_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/dashboard/activity_detail_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/expenses/new_expense_screen.dart';
import '../features/groups/add_member_screen.dart';
import '../features/groups/group_detail_screen.dart';
import '../features/groups/group_settings_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/settle/settle_up_screen.dart';
import '../features/settings/settings_screen.dart';
import 'theme/colors.dart';

enum AppRoute {
  dashboard('/dashboard'),
  groups('/groups'),
  groupDetail('/groups/:groupId'),
  analytics('/analytics'),
  accounts('/accounts'),
  settings('/settings'),
  addMember('/groups/:groupId/add-member'),
  newExpense('/expenses/new'),
  settleUp('/settle-up'),
  activityDetail('/activity/:activityId'),
  groupSettings('/groups/:groupId/settings');

  const AppRoute(this.path);
  final String path;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _dashboardNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboardBranch');
final _groupsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'groupsBranch');
final _analyticsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'analyticsBranch');
final _accountsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'accountsBranch');
final _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.dashboard.path,
    routes: [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            _AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.dashboard.path,
                name: AppRoute.dashboard.name,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _groupsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.groups.path,
                name: AppRoute.groups.name,
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _analyticsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.analytics.path,
                name: AppRoute.analytics.name,
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _accountsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.accounts.path,
                name: AppRoute.accounts.name,
                builder: (context, state) => const AccountsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.settings.path,
                name: AppRoute.settings.name,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.newExpense.path,
        name: AppRoute.newExpense.name,
        builder: (context, state) => const NewExpenseScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.settleUp.path,
        name: AppRoute.settleUp.name,
        builder: (context, state) => const SettleUpScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.activityDetail.path,
        name: AppRoute.activityDetail.name,
        builder: (context, state) => ActivityDetailScreen(
          activityId: state.pathParameters['activityId'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.groupDetail.path,
        name: AppRoute.groupDetail.name,
        builder: (context, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.addMember.path,
        name: AppRoute.addMember.name,
        builder: (context, state) => AddMemberScreen(
          groupId: state.pathParameters['groupId'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.groupSettings.path,
        name: AppRoute.groupSettings.name,
        builder: (context, state) => GroupSettingsScreen(
          groupId: state.pathParameters['groupId'] ?? '',
        ),
      ),
    ],
  );
});

class _AppScaffold extends StatelessWidget {
  const _AppScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorTokens = theme.extension<PaisaColorTokens>();
    final accentGold = colorTokens?.accentGold ?? theme.colorScheme.tertiary;
    final inactiveColor =
        colorTokens?.navigationInactive ?? theme.colorScheme.onSurfaceVariant;
    final navBackground =
        colorTokens?.navigationBackground ?? theme.colorScheme.surface;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed(AppRoute.newExpense.name),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onDestinationSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_outlined),
            activeIcon: Icon(Icons.space_dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: accentGold,
        unselectedItemColor: inactiveColor,
        backgroundColor: navBackground,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
