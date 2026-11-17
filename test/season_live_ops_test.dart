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

  group('season 4 scheduling', () {
    test('keeps season 3 active through Nov 17, 2026 UTC', () {
      final season = activeSeasonAt(DateTime.utc(2026, 11, 17, 23, 59, 59));
      expect(season.id, kSeason3.id);
    });

    test('auto-starts season 4 at Nov 18, 2026 UTC', () {
      final season = activeSeasonAt(DateTime.utc(2026, 11, 18));
      expect(season.id, kSeason4.id);
      expect(season.name, 'Holiday Hustle');
    });

    test('keeps season 4 active through its Jan 1, 2027 UTC end', () {
      final season = activeSeasonAt(DateTime.utc(2026, 12, 31, 23, 59, 59));
      expect(season.id, kSeason4.id);
    });

    test('season 4 is the latest season with no season 5 defined', () {
      expect(seasonById(kSeason4.id), kSeason4);
      expect(activeSeasonAt(DateTime.utc(2027, 2, 1)).id, kSeason4.id);
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

    test('season 3 pass rewards roll over 60 days after Nov 1, 2026', () {
      final eligibleAt =
          shopEligibleAtForPastPassReward(seasonId: kSeason3.id);
      expect(eligibleAt, DateTime.utc(2026, 12, 31));
      expect(
        isShopEligibleForPastPassReward(
          seasonId: kSeason3.id,
          utcNow: DateTime.utc(2026, 12, 30, 23, 59, 59),
        ),
        isFalse,
      );
      expect(
        isShopEligibleForPastPassReward(
          seasonId: kSeason3.id,
          utcNow: DateTime.utc(2026, 12, 31),
        ),
        isTrue,
      );
    });

    test('season 4 pass rewards roll over 60 days after Jan 1, 2027', () {
      final eligibleAt =
          shopEligibleAtForPastPassReward(seasonId: kSeason4.id);
      expect(eligibleAt, DateTime.utc(2027, 3, 2));
      expect(
        isShopEligibleForPastPassReward(
          seasonId: kSeason4.id,
          utcNow: DateTime.utc(2027, 3, 1, 23, 59, 59),
        ),
        isFalse,
      );
      expect(
        isShopEligibleForPastPassReward(
          seasonId: kSeason4.id,
          utcNow: DateTime.utc(2027, 3, 2),
        ),
        isTrue,
      );
    });

    test('season 4 timed drops are deterministic and in 5-7 day intervals', () {
      final first = deterministicDropOffsets(
        seasonId: kSeason4.id,
        itemCount: 4,
      );
      final second = deterministicDropOffsets(
        seasonId: kSeason4.id,
        itemCount: 4,
      );
      expect(first, second);
      expect(first.length, 4);
      for (var i = 1; i < first.length; i++) {
        final gap = first[i] - first[i - 1];
        expect(gap >= 5 && gap <= 7, isTrue);
      }
      expect(first.first >= 5 && first.first <= 7, isTrue);
    });
  });
}
