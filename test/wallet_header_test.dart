// Verifikasi visual WalletHeader: label Saldo, nominal, dan tombol Top Up muncul.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:linakan_app/ui/common/widgets/wallet_header.dart';
import 'package:linakan_app/providers/notification_provider.dart';

void main() {
  testWidgets('WalletHeader menampilkan Saldo, nominal, dan Top Up',
      (WidgetTester tester) async {
    bool topUpTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NotificationProvider>.value(
            value: NotificationProvider.empty(),
            child: WalletHeader(
              valueLabel: 'Saldo',
              value: 'Rp 500.000',
              greetingName: 'Budi',
              badge: 'UMKM',
              onLogout: () {},
              onTopUp: () => topUpTapped = true,
              actions: const [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('Rp 500.000'), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-wallet-balance')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-wallet-amount')), findsOneWidget);
    expect(find.text('Selamat Datang,'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);

    final balancePosition = tester.getTopLeft(find.text('Rp 500.000'));
    final topUpPosition = tester.getTopLeft(find.text('Top Up'));
    expect(topUpPosition.dy, greaterThan(balancePosition.dy));

    await tester.tap(find.text('Top Up'));
    expect(topUpTapped, isTrue);
  });
}
