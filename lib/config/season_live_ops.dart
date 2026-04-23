import 'dart:math';

/// Season boundaries are evaluated in UTC for deterministic cross-device logic.
class SeasonDefinition {
  final String id;
  final int number;
  final String name;
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;

  SeasonDefinition({
    required this.id,
    required this.number,
    required this.name,
    required this.startsAtUtc,
    required this.endsAtUtc,
  });
}

final kSeason1 = SeasonDefinition(
  id: 'season_1',
  number: 1,
  name: 'Spring Bloomin\'',
  startsAtUtc: DateTime.utc(2026, 4, 13),
  endsAtUtc: DateTime.utc(2026, 5, 1),
);

final kSeason2 = SeasonDefinition(
  id: 'season_2',
  number: 2,
  name: 'Finals Frenzy',
  startsAtUtc: DateTime.utc(2026, 5, 1),
  endsAtUtc: DateTime.utc(2026, 8, 1),
);

final kAllSeasons = <SeasonDefinition>[kSeason1, kSeason2];

SeasonDefinition activeSeasonAt(DateTime utcNow) {
  final now = utcNow.toUtc();
  for (final season in kAllSeasons.reversed) {
    if (!now.isBefore(season.startsAtUtc)) return season;
  }
  return kSeason1;
}

SeasonDefinition activeSeasonNowUtc() => activeSeasonAt(DateTime.now().toUtc());

SeasonDefinition? seasonById(String id) {
  for (final season in kAllSeasons) {
    if (season.id == id) return season;
  }
  return null;
}

DateTime shopEligibleAtForPastPassReward({
  required String seasonId,
  int daysAfterSeasonEnd = 60,
}) {
  final season = seasonById(seasonId) ?? kSeason1;
  return season.endsAtUtc.add(Duration(days: daysAfterSeasonEnd));
}

bool isShopEligibleForPastPassReward({
  required String seasonId,
  required DateTime utcNow,
  int daysAfterSeasonEnd = 60,
}) {
  return !utcNow.toUtc().isBefore(
    shopEligibleAtForPastPassReward(
      seasonId: seasonId,
      daysAfterSeasonEnd: daysAfterSeasonEnd,
    ),
  );
}

/// Deterministic per-season timed-drop offsets where every gap is in [5..7] days.
List<int> deterministicDropOffsets({
  required String seasonId,
  required int itemCount,
}) {
  final seed = seasonId.codeUnits.fold<int>(0, (acc, c) => acc + c);
  final random = Random(seed);
  final offsets = <int>[];
  var total = 0;
  for (var i = 0; i < itemCount; i++) {
    total += 5 + random.nextInt(3); // 5, 6, or 7
    offsets.add(total);
  }
  return offsets;
}

bool passMeetsRequirement(String ownedPassType, String requiredPassType) {
  const rank = {'free': 0, 'plus': 1, 'premium': 2};
  return (rank[ownedPassType] ?? 0) >= (rank[requiredPassType] ?? 0);
}
