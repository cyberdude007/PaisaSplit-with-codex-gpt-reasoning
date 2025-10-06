import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:paisasplit/app/app_router.dart';
import 'package:paisasplit/features/dashboard/data/dashboard_repository.dart';
import 'package:paisasplit/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  const snapshot = DashboardSnapshot(
    youOwePaise: 0,
    youGetPaise: 260000,
    netBalancePaise: 260000,
  );
  final counterparties = [
    const DashboardCounterparty(
      memberId: 'm_rahul',
      memberName: 'Rahul',
      groupId: 'g_trip',
      groupName: 'Goa Trip',
      amountPaise: 190000,
      direction: CounterpartyDirection.youGet,
    ),
    const DashboardCounterparty(
      memberId: 'm_anu',
      memberName: 'Anu',
      groupId: 'g_trip',
      groupName: 'Goa Trip',
      amountPaise: 70000,
      direction: CounterpartyDirection.youGet,
    ),
  ];
  final activities = [
    DashboardActivity(
      id: 'expense:e1',
      type: DashboardActivityType.expense,
      title: 'Hotel',
      groupId: 'g_trip',
      groupName: 'Goa Trip',
      actorName: 'Me',
      date: DateTime(2025, 8, 11),
      amountPaise: 300000,
    ),
    DashboardActivity(
      id: 'settlement:s1',
      type: DashboardActivityType.settlement,
      title: 'Settlement',
      groupId: 'g_trip',
      groupName: 'Goa Trip',
      actorName: 'Rahul',
      date: DateTime(2025, 8, 12),
      amountPaise: -150000,
    ),
  ];

  DashboardData buildData() => DashboardData(
        snapshot: snapshot,
        counterparties: counterparties,
        recentActivity: activities,
      );

  testWidgets('renders snapshot cards and recent activity', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardDataProvider.overrideWith(
            (ref) => Stream.value(buildData()),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('You Owe'), findsOneWidget);
    expect(find.text('You Get'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('₹2,600.00'), findsNWidgets(2));
    expect(find.text('₹0.00'), findsOneWidget);

    expect(find.text('Rahul owes you'), findsOneWidget);
    expect(find.text('Goa Trip'), findsWidgets);

    expect(find.text('Hotel'), findsOneWidget);
    expect(find.textContaining('11 Aug 2025'), findsOneWidget);
    expect(find.text('Settlement'), findsOneWidget);
  });

  testWidgets('tapping counterparty navigates to settle up', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.dashboard.path,
      routes: [
        GoRoute(
          path: AppRoute.dashboard.path,
          name: AppRoute.dashboard.name,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoute.settleUp.path,
          name: AppRoute.settleUp.name,
          builder: (context, state) {
            final groupId = state.pathParameters['groupId'] ?? '';
            return Scaffold(
              body: Center(child: Text('Settle Up Screen: $groupId')),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardDataProvider.overrideWith(
            (ref) => Stream.value(
              DashboardData(
                snapshot: snapshot,
                counterparties: counterparties.take(1).toList(),
                recentActivity: activities,
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();

    final chipFinder = find.byType(ActionChip).first;
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(find.text('Settle Up Screen: g_trip'), findsOneWidget);
  });
}
