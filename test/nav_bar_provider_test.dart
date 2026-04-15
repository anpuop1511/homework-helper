import 'package:flutter_test/flutter_test.dart';
import 'package:homework_helper/providers/nav_bar_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavBarProvider defaults', () {
    test('defaults visible tabs to Home, Social, Focus', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NavBarProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        provider.visibleTabs,
        equals([NavTab.home, NavTab.social, NavTab.focus]),
      );
    });

    test('persists showLabels setting across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NavBarProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.showLabels, isTrue);
      provider.setShowLabels(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final reloaded = NavBarProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(reloaded.showLabels, isFalse);
    });
  });
}
