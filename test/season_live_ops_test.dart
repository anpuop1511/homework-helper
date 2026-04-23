import 'package:flutter_test/flutter_test.dart';
import 'package:homework_helper/config/season_live_ops.dart';

void main() {
  group('season scheduling', () {
    test('keeps season 1 active before May 1, 2026 UTC', () {
      final season = activeSeasonAt(DateTime.utc(2026, 4, 30, 23, 59, 59));
      expect(season.id, kSeason1.id);
    });

    test('auto-starts season 2 at May 1, 2026 UTC', () {
      final season = activeSeasonAt(DateTime.utc(2026, 5, 1));
      expect(season.id, kSeason2.id);
    });
  });

  group('shop rollover and drops', () {
    test('season 1 pass rewards roll over after 60 days', () {
      final eligibleAt =
          shopEligibleAtForPastPassReward(seasonId: kSeason1.id);
      expect(eligibleAt, DateTime.utc(2026, 6, 30));
      expect(
        isShopEligibleForPastPassReward(
          seasonId: kSeason1.id,
          utcNow: DateTime.utc(2026, 6, 29, 23, 59, 59),
        ),
        isFalse,
      );
      expect(
        isShopEligibleForPastPassReward(
          seasonId: kSeason1.id,
          utcNow: DateTime.utc(2026, 6, 30),
        ),
        isTrue,
      );
    });

    test('drop cadence is deterministic and in 5-7 day intervals', () {
      final first = deterministicDropOffsets(
        seasonId: kSeason2.id,
        itemCount: 6,
      );
      final second = deterministicDropOffsets(
        seasonId: kSeason2.id,
        itemCount: 6,
      );
      expect(first, second);
      for (var i = 1; i < first.length; i++) {
        final gap = first[i] - first[i - 1];
        expect(gap >= 5 && gap <= 7, isTrue);
      }
      expect(first.first >= 5 && first.first <= 7, isTrue);
    });
  });
}

