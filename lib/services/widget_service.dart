/// Study Streak Widget Service
///
/// Provides the foundation for publishing the user's streak and level to an
/// Android / iOS Home Screen widget.
///
/// ## Native setup required
/// 1. Add `home_widget: ^0.7.0` to `pubspec.yaml` dependencies.
/// 2. **Android** (`android/app/src/main/AndroidManifest.xml`): Register a
///    `AppWidgetProvider` receiver and include the widget metadata XML.
///    See: https://pub.dev/packages/home_widget#android
/// 3. **iOS** (`ios/Runner/Info.plist` + WidgetKit extension): Create a
///    Flutter widget extension.
///    See: https://pub.dev/packages/home_widget#ios
///
/// Once native setup is complete, uncomment the `home_widget` import and
/// the implementation calls below.
library;

// import 'package:home_widget/home_widget.dart';

/// The name used to identify this widget to the `home_widget` package.
const String _kWidgetName = 'StudyStreakWidget';

/// Keys for the data that is pushed to the widget.
const String kWidgetKeyStreak = 'streak';
const String kWidgetKeyLevel = 'level';

/// Publishes the user's current [streak] and [level] to the home screen widget.
///
/// This is a no-op until the native widget setup is completed (see above).
Future<void> updateStudyWidget({
  required int streak,
  required int level,
}) async {
  // Uncomment the following lines after completing native widget setup:
  //
  // await HomeWidget.saveWidgetData<int>(kWidgetKeyStreak, streak);
  // await HomeWidget.saveWidgetData<int>(kWidgetKeyLevel, level);
  // await HomeWidget.updateWidget(name: _kWidgetName);
}
