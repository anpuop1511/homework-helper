import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework_helper/providers/nav_bar_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitForCondition(Future<bool> Function() condition) async {
  final timeoutAt = DateTime.now().add(const Duration(seconds: 1));
  while (!await condition()) {
    if (DateTime.now().isAfter(timeoutAt)) {
      throw TimeoutException('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavBarProvider defaults', () {
    test('defaults visible tabs to Home, Social, Focus', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NavBarProvider();
      await _waitForCondition(() async => provider.visibleTabs.isNotEmpty);

      expect(
        provider.visibleTabs,
        equals([NavTab.home, NavTab.social, NavTab.focus]),
      );
    });

    test('persists showLabels setting across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NavBarProvider();
      await _waitForCondition(() async => provider.showLabels);

      expect(provider.showLabels, isTrue);
      provider.setShowLabels(false);
      await _waitForCondition(() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('nav_show_labels') == false;
      });

      final reloaded = NavBarProvider();
      await _waitForCondition(() async => reloaded.showLabels == false);
      expect(reloaded.showLabels, isFalse);
    });
  });
}
