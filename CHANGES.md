# Azkari — CHANGES

Log of the low-risk batch that went into this tree. Each item lists **before**,
**after**, and **why**. Verified end-to-end: `flutter analyze` clean and
`flutter test` green (51/51), including the manual regression repro suites in
`test/manual/`.

Note on azkar times: prayer-derived *defaults* (Fajr+30 / Asr+30) are city-local
times and get converted city→device before scheduling. A user-set **custom**
azkar time is a bare wall-clock `"HH:mm"` picked on the device, so it is
scheduled **verbatim on the device clock** — it must not be shifted by the
selected city's UTC offset.

---

## 1. Quran reminder payload -> tap routing

- **Before:** the morning/evening quran reminder was scheduled with a payload
  the tap dispatcher did not map to the quran screen, so tapping the reminder
  notification fell through to the generic fallback.
- **After:** the reminder schedules with payload `'quran_reminder'`
  (`notifications_service.dart:569`) and `main.dart` routes `'quran_reminder'`
  taps to `QuranDetailPage`.
- **Why:** the whole point of the reminder is that tapping it opens the quran
  reader; a dead tap or wrong screen silently defeats the feature.

## 2. Home-screen widget: root id + tap intent

- **Before:** the widget row was scheduled by `updateAppWidget` but taps had no
  click target (`setOnClickPendingIntent` on a view id the layout didn't use).
- **After:** the layout's root is `@+id/widget_root` and the provider calls
  `setOnClickPendingIntent(R.id.widget_root, pendingIntent)` —
  `PrayerTimesWidgetProvider.kt:125`.
- **Why:** an un-tappable widget is a broken widget; the pending intent opens
  the app/screen the user expects when they tap the prayer times card.

## 3. Notification provider: init + serialized reschedule

- **Before:** cold start read the saved "notifications enabled" flag then
  always ran the full `cancelAll`+reschedule; rapid successive edits could run
  overlapping reschedules that interleave and drop just-scheduled
  notifications.
- **After:** `_loadNotificationPreferences` skips the expensive reschedule when
  the schedule plan is unchanged, and reschedules are serialized through a
  single `_rescheduleQueue` (only one cancel+reschedule runs at a time). The
  manual concurrency repro asserts zero overlapping cancel runs.
- **Why:** overlapping cancelAll+reschedule was the source of "edited time"
  notifications getting wiped; serializing removes the race instead of masking
  it, and the unchanged-plan skip removes pointless cold-start work.

## 4. Qibla provider: missing `flutter/widgets.dart` import

- **Before:** `QiblaProvider` extended `WidgetsBindingObserver` without
  importing `package:flutter/widgets.dart`, so `flutter analyze` reported an
  undefined-name error (missing import) and the file could not resolve the
  observer mixin. A now-unused `flutter/foundation.dart` import also remained.
- **After:** the widgets import is present (mixin resolves) and the stale
  foundation import was removed.
- **Why:** the provider must observe app lifecycle to pause/resume the compass
  sensor; an unbuildable import breaks the whole feature.

## 5. Prayer widget: exact alarm + inexact fallback

- **Before:** prayer reminders scheduled with an alarm mode that didn't
  reliably fire exactly at adhan time, and there was no guard for devices that
  deny exact alarms (silently losing reminders).
- **After:** scheduling asks for exact-alarm-permission; when granted it uses
  `exactAllowWhileIdle`, and when denied/unsupported it deliberately falls back
  to an inexact alarm (`notifications_service.dart:347-361`) plus a
  permission-request entry point.
- **Why:** adhan reminders are time-critical; where the OS forbids exact
  alarms the fallback keeps the reminder functional rather than dropping it.

## 6. (Reserved — not applicable.)

## 7. Custom azkar time scheduling verbatim on the device clock

- **Before:** a user-set azkar time (`morningAzkarTime` / `eveningAzkarTime`,
  stored as `"HH:mm"`) was being routed through the same city→device
  conversion as prayer times, so e.g. a custom Cairo-city 02:47 got scheduled
  with an extra +3h UTC offset shift on the device clock.
- **After:** when a custom time exists it is scheduled verbatim in the device
  timezone (`tz.TZDateTime(tz.local, ...)`); only the prayer-derived default
  goes through city→device conversion. Covered by the manual repro that edits
  an azkar time and asserts the reschedule fires at the exact picked wall-clock
  (02:47 → 02:47 device).
- **Why:** the stepper the user interacts with is on the device clock; a custom
  wall-clock time must fire at that same wall clock to match user expectation.
  The +3h (Cairo) shift was a regression the repro locks against.

## 8. Android: boot + package-replaced ready for cold-start reschedule

- **Before:** the manifest declared only the base receivers; the boot
  receiver lacked an `intent-filter` for `BOOT_COMPLETED` /
  `MY_PACKAGE_REPLACED` / quickboot, so a reboot or app update did not reliably
  trigger the "reschedule after boot" path.
- **After:** `AndroidManifest.xml` now wires the boot/locale receivers with the
  explicit intent-filters so the scheduler can re-arm on boot and on
  package-replace. (`RECEIVE_BOOT_COMPLETED`/`SCHEDULE_EXACT_ALARM`/`POST_NOTIFICATIONS`
  are already declared.)
- **Why:** prayer and azkar alarms are the core deliverable; if they never
  re-arm after a reboot the schedules silently stop until the app is opened.

## 9. Notification service: timezone guards on scheduling

- **Before:** scheduling computed dates while the selected timezone might not
  be initialized yet, which could produce a wrong conversion for the selected
  city on cold start.
- **After:** the scheduling helper guards the timezone/float-fix so a schedule
  is only computed once the correct city timezone is in place (never scheduling
  against an unconfig timezone). Cold-start handling is also primed before the
  first reschedule.
- **Why:** computing a Cairo+custom date against an uninitialized/UTC clock
  mis-prepares the exact alarm result.

## 10. Settings pages: code cleanups (`Consumer2` -> fine-grained reads)

- **Before:** stray leftover tokens (e.g. a dangling `),`) and broad
  `Consumer2` subscriptions that rebuilt large subtrees on any provider change.
- **After:** stray syntax tokens removed; azkar/settings pages use
  `context.select`-style narrow reads so only the affected rows rebuild.
- **Why:** analyzer-clean and smaller rebuild surface; the previous
  `Consumer2`-based rebuilds caused unnecessary work on every provider
  notification.

## 11. Notification scheduling: skip/warming guard

- **Before:** cold-start code could run the reschedule path before the
  timezone/prefs/state were warmed, dropping pending notifications (a
  "silently lost after app update/launch" bug).
- **After:** a guard skips the reschedule until the state the scheduling
  depends on is initialized (see 3 and 9); a dedicated `requestExactAlarmsPermission`
  entry point is exposed for Android exact-alarm flows.
- **Why:** an early, half-warmed reschedule is worse than none: it cancels
  then fails to re-add, so nothing fires.

## 23/24. Azkar time stepper keyboard crash

- **Before:** editing an azkar time via the time picker could throw a
  platform/stepper exception ("time picker keyboard crash" repro) and leave the
  picker unusable.
- **After:** the azkar time stepper renders Arabic-Indic digits, increments and
  persists selection, and the picking flow commits the new value via
  `setAzkarTime` which reschedules the day/night azkar notification. Repros:
  "stepper time picker shows Arabic digits and increments", "increments and
  persists selection", "editing an azkar time reschedules morning azkar".
- **Why:** the shared azkar time picker is used by the settings rows; a crash
  on keyboard interaction made the edit path unusable. The '+'/'-' steppers
  commit through the same reschedule path as the rest of the settings.

## 25. Cold-start notification taps navigate immediately (not on Home pop)

- **Before:** `SplashPage` fired `onReady` (which opens AdhanPage/Azkar page
  for a launch-from-notification) in `pushReplacement(...).then(...)`. The
  pushed route's future completes only when HomePage is *popped*, so the
  notification-driven navigation never ran at launch (or only after backing
  out of Home).
- **After:** a post-frame callback fires `onReady` right after the replacement
  route is pushed (`splash_page.dart`).
- **Why:** a notification tap that silently shows Home instead of the Adhan
  page is a broken core flow.

## 26. One-day-lag on prayer notifications fixed (cold-start skip)

- **Before:** `NotificationProvider.refreshNotifications()` decided "unchanged
  plan → skip reschedule" from the *stored* schedule signature while the stored
  prayer-times were still the previous day's (PrayerTimesProvider hadn't
  computed today's times yet). Nothing recomputed after today's times were
  written, so prayer/adhan notifications fired at yesterday's times all day.
- **After:** `SplashPage` awaits `prayerTimesProvider.loadPrayerTimes()` before
  `refreshNotifications()` runs, so the skip decision is made against
  freshly-stored *today's* times (`splash_page.dart`).
- **Why:** an entire day of wrong adhan/pre-adhan/quran reminders is a severe,
  silent regression that appears only on the next calendar day.

## 27. One failing scheduler no longer cancels every notification

- **Before:** `_rescheduleNotificationsInner` used `error ??= await ...` chains
  — after `cancelAll()` had already run, the first non-null error short-
  circuited every remaining category, so (e.g.) missing location + one timezone
  guard wiped location-independent periodic azkar and prophet blessings too.
- **After:** each enabled scheduler is always attempted; only the *first*
  error is coalesced and surfaced (`notification_provider.dart`). Covered by a
  regression test: with no location, periodic azkar (20–23) and blessings
  (400–403) are still scheduled.
- **Why:** GPS-off or one denied exact-alarm silently deleted the reminders
  that did not depend on the failing category.

## 28. Adhan timing: fixed-city anchor + strictly-future rollover

- **Before:** `_deviceDateForPrayer` was anchored to the *device* calendar day
  even for a fixed city, and callers bumped only once. When the device clock
  was behind the city (e.g. LA device, Dubai city), the computed "tomorrow"
  could still be in the past, and `zonedSchedule` with a past trigger fires a
  spurious adhan chime immediately and misses the real occurrence.
- **After:** the date is anchored on the *city's* calendar (`tz.now(cityTz)`),
  converted to the device clock, and rolled forward in a loop until strictly
  in the future (`notifications_service.dart:_deviceDateForPrayer`).
- **Why:** an instant, uninvited adhan sound (and the wrong pre-adhan/quran
  anchor day) is exactly the kind of bug users never forgive in a thikr app.

## 29. Editing a category invalidates its counting state

- **Before:** `updateCustomAzkarCategory` cleared only `_completedIndex`, never
  the per-item remainder rows, so after removing/shortening items a card kept
  an impossible display like "٢٠ / ٥" and the category could never reach
  completion again.
- **After:** a successful update drops counting keys for **both** the old and
  the new category name plus the completed index (`azkar_provider.dart`), so
  edited categories restart cleanly.
- **Why:** editing is the second most common action after counting; a category
  that can never complete silently corrupts the core loop.

## 30. Duplicate zekr texts count independently

- **Before:** the count key was `category\u0000zekr`; two identical rows inside
  one custom category shared a single counter, so they finished together and
  the category could never reach completion.
- **After:** keys are `category\u0000index\u0000zekr`; the details page passes
  the list index (`azkar_details_page.dart`), and the `DisplayAzkar` widget key
  is index-unique so identical texts don't collide. `resetCategoryCounts`
  clears by category prefix.
- **Why:** users legitimately add the same text twice (e.g. with different
  counts); sharing a counter made the category un-completable.

## 31. Favorites survive rename/delete; sheets report real failure

- **Before:** renaming a custom category re-keyed only the category favorite —
  saved item favorites (`category\u0000zekr`) stayed under the dead name and
  vanished from the saved folder. Deleting a category orphaned its favourited
  items. Both add/edit sheets always toasted success and popped even when the
  DB write failed.
- **After:** `FavoritesProvider` gains `renameCategoryItemFavorites` /
  `removeCategoryItemFavorites`; the edit sheet migrates items on rename, the
  delete flow strips them, and `save/update/deleteCustomCategory` now return
  `bool` so the sheets toast/pop only on real success (error toast, stay open,
  and reload the list on failure).
- **Why:** a saved favourite that silently disappears — or a "saved!" toast for
  an in-memory-only write — is data the user believes they can rely on.

## 32. All-azkar list: count/empty-state/watch corrections

- **Before:** a custom category named like an asset category showed the
  *asset* count while its details page opened custom; the surah-folder count
  was read with `context.read` and never updated; searching inside 'أذكاري'
  with no matches wrongly said "لا توجد أذكار مخصصة مضافة".
- **After:** `_categoryCount` prefers the custom list when any custom entry
  exists (matching what the details page displays), the surah row counts via
  `Consumer<SurahProvider>`, and the empty state shows a search result message
  whenever a query is active (`all_azkar_page.dart`).
- **Why:** three small lies in the list UI that erode trust in the numbers
  users look at every day.

---

## 33. Audio toggle between surahs actually switches (no tautological guard)

- **Before:** `QuranProvider.toggleAudio` assigned `_currentPlayingSurah =
  surahNumber` *before* computing
  `isSameSurah = _player.audioSource != null && _currentPlayingSurah == surahNumber`,
  so `isSameSurah` was always just `audioSource != null`. Tapping a *different*
  surah while one was playing hit the `pause()` branch instead of switching the
  source.
- **After:** the already-loaded surah is read into a local before any
  reassignment; pause/resume applies only to the loaded surah, and a different
  surah proceeds to `setAudioSource`. `_currentPlayingSurah` is assigned right
  before playback loads the new file (`quran_provider.dart`).
- **Why:** switching between reciters/surahs in the reader was broken whenever
  audio was already playing.

## 34. Reader stops audio on dispose

- **Before:** leaving `QuranDetailPage` left the surah playing in the
  background (audio kept playing after the reader closed).
- **After:** the provider is captured in `initState` and `resetAudio()` is
  called in `dispose`.
- **Why:** background recitation after the reader is closed is surprising and
  a battery drain.

## 35. No setState after dispose in the audio controller

- **Before:** `AudioControllers._refreshDownloadStatus` and the play-button
  `onTap` called `setState` after an `await` with no `mounted` guard, which can
  throw when the widget is disposed mid-await.
- **After:** guarded with `if (!mounted) return`.
- **Why:** the classic async-dispose crash in teardown.

## 36. Al-Fatiha basmala duplication / hollow first line fixed

- **Before:** `buildVerseSpan` kept a regex-vs-`quran.basmala` strip block.
  `quran.getVerse(1,1)` returns exactly the basmala, so after stripping, Al-
  Fatiha verse 1 rendered as an empty/whitespace-only span while `_buildBasmalaHeader`
  already drew the same basmala; the remaining strip was dead code for every
  other surah (their verse 1 never contains the basmala).
- **After:** skip rendering the span for surah 1 verse 1 entirely; the
  duplicated basmala and the redundant strip block are gone.
- **Why:** the reader showed a doubled basmala plus a phantom first line.

## 37. Reader progress bar tracks virtual split pages

- **Before:** `LinearProgressIndicator.value = globalPageNumber / 604`; on
  split pages (a mushaf page holding two surah segments) the global page
  number is shared, so the bar sat flat at the same global page.
- **After:** value = `_currentIndex / (_virtualPages.length - 1)`.
- **Why:** progress should move on every swipe, including across split pages.

## 38. Dedicated Quran bookmark (independent of auto-resume)

- **Before:** the bookmark button in `SideTools._bookmark` read/wrote the
  auto-resume position (`savedLatestQuranSurahNumber`/`savedLatestQuranPageNumber`),
  which is re-saved on every page turn — flipping pages silently destroyed the
  "saved" mark and un-bookmarking also wiped the resume position.
- **After:** new storage keys `quran_bookmark_surah_key`/`quran_bookmark_page_key`
  with a full stack: 4 datasource methods, 4 repository methods, 4 use cases
  (`Save/GetSurah/GetPage/ClearQuranBookmark`), provider `bookmarkSurah`,
  `bookmarkPage`, `saveBookmark`, `clearBookmark`, wired in
  `injection_container.dart` and `main.dart`. `SideTools._bookmark` now uses
  the bookmark.
- **Why:** bookmark and auto-resume are different concepts; one should not
  clobber the other.

## 39. Surah list page: real loading/error/empty states

- **Before:** `_currentDisplayedSurahs` was snapshotted once via
  `didChangeDependencies`, so the list never reflected provider updates, the
  loading state wasn't rendered, and an empty list was reported as "search not
  found".
- **After:** the page consumes `SurahProvider` (loading spinner / error with
  retry / search-filtered list / no-results message).
- **Why:** load failures and stale lists are invisible bugs.

## 40. Names of Allah page: error branch + retry

- **Before:** the provider already stored an error, but the page rendered a
  blank body on error (and `initial` as an empty list too).
- **After:** handled `initial/loading` with a spinner and `error` with a
  message and a retry button.
- **Why:** silent blank screens on failure.

## 41. Surah picker: long names ellipsize

- **Before:** the surah-name `Text` was a fixed child of the row, so long
  Arabic names could overflow their cell.
- **After:** wrapped in `Flexible` with `maxLines: 1` + ellipsis.
- **Why:** RenderFlex overflow on narrower screens / larger fonts.

---

## 42. intl Arabic locale initialized — prayer times card was crashing

- **Before:** `DateFormat.jm('ar')` inside `PrayerTimesCard._buildPrayerItem`
  threw `LocaleDataException: Locale data has not been initialized` because
  nothing ever called `initializeDateFormatting`, so the Home prayer card could
  not render.
- **After:** `main.dart` awaits `initializeDateFormatting('ar')` at startup;
  widget tests mirror it in `setUpAll`.
- **Why:** a first-frame crash on the main screen that analyze/tests missed
  (caught by the new widget test).

## 43. Prayer times card: no more overflow at six columns

- **Before:** the six prayer columns sat in a `Row` with `spaceAround` and the
  header title/city `Column` was unconstrained, so narrow surfaces (or large
  font scales) overflowed the card's `RenderFlex`.
- **After:** each column is wrapped in `Expanded`, and the header's text block
  in `Flexible` with `maxLines: 1`/ellipsis on the title too.
- **Why:** overflow stripes / clipped times on small screens and large fonts.

## 44. Font-size slider can no longer crash on startup

- **Before:** `Slider(value: theme.textScaleFactor)` rendered a persisted
  out-of-range value (e.g. `3.7`) directly, hitting Slider's
  `value < min || value > max` assertion; the stored value was also read
  un-clamped.
- **After:** the slider clamps the displayed value and
  `ThemeProvider` clamps the scale factor on load (`0.8–1.5`), so invalid
  legacy values self-heal.
- **Why:** settings page crash on launch for users with stale prefs.

## 45. Qibla: devices without a compass no longer lie

- **Before:** `_subscribeToCompass` silently `return`ed when
  `FlutterCompass.events == null`, leaving the UI showing the last heading
  (0°) as if live, with no indication the sensor is missing.
- **After:** a `compassUnavailable` flag is raised (also on stream error) and
  `QiblaScreen` renders "البوصلة غير متوفرة على هذا الجهاز" instead.
- **Why:** presenting a frozen 0° as a live direction is misleading.

## 46. Emoji no longer render as "?" on the iOS Simulator

- **Before:** rendered emoji (`🌿` in the welcome header, `🎉` on the azkar
  completion sheet, plus any future ones) fell back through the platform font
  list, which resolves via the host macOS on the Simulator and can produce the
  �/tofu glyph or "?" there even though a real device renders Apple Color Emoji.
- **After:** `NotoColorEmoji.ttf` (color bitmap font, ~10.7 MB) is bundled and
  set as `fontFamilyFallback` on every `TextTheme` style in both themes, the
  AppBar title style, and the two inline emoji-bearing `TextStyle`s, so Flutter
  resolves missing glyphs deterministically on any renderer/simulator.
- **Why:** deterministic glyph resolution independent of the platform fallback
  table. System-notification emoji (`🌞`/`🌙` in reminder titles) still render
  via the OS and are out of Flutter's control.

---

### Verification
- `flutter analyze`: no issues (mocks regenerated via
  `dart run build_runner build --build-filter ...quran_repository_impl_test.*`;
  orphan `quran_repository_impl_test.mocks.mocks.dart` removed).
- `flutter test`: 51/51 passing — includes all Slice-1/2/3 suites plus new
  Slice-4 coverage: quran bookmark storage roundtrip/clear/independence,
  prayer-times-card renders on a narrow 280px surface and under 2.0 text scale
  without overflow, and ThemeProvider clamps out-of-range stored text scale.

## 47. UI overflow sweep for the non-Quran features

- **Aliqibla compass/city zekr fixes**: the details page 141 px, all-azkar
  492 px, "add/edit" 120 px, and city-picker overflows were largely a test
  artifact — the agent harness mounted a bare `MaterialApp` (Roboto) instead
  of the real app theme, so Arabic fell back to metric-less glyphs with absurd
  line heights (a details hint measured 592 px at 2x). The harnesses now use
  the app's light theme (or a `fontFamily: 'Tajawal'` equivalent) + a
  `FontLoader`, removing those bogus failures without a lib change.
- **City-picker widget**: its `ListTile` now sits inside a transparent
  `Material`, which removes the ink/debug assertion (transparent material
  under a decorated `Container` is the idiomatic fix).
- **City dropdown button**: icon/text/arrow are now `Flexible` (were
  `flex: 0`, which never shrinks), so the home header no longer overflows at
  320 px / 2x text (was 21 px).
- **DisplayAzkar**: the actions row is now `Expanded(Align(FittedBox
  (scaleDown)))` over the copy/favorite buttons with the counter pill kept at
  natural size — details no longer overflows 52 px.
- **Tasbih**: the zekr label is `Flexible` (maxLines 2) so the total row
  compresses; tasbih page no longer overflows 13 px at 320 px / 2x.
- **Settings About dialog**: the developer-credit row is `Flexible`, and the
  whole dialog body is `SingleChildScrollView`, fixing a 293 px right overflow
  and a subsequent 8 px bottom one at 320 px / 2x.
- **Widget guide**: the step text block is now scrollable (was overflowing
  50 px vertically on intro steps), and the next/back button label is wrapped
  in `FittedBox(scaleDown)` (was overflowing 394 px horizontally on the first
  step's long label).
- **Test harness hardening**: `prayer_settings_ui_test.dart` city-search test
  dragged the picker list up before tapping the city (the exact-match
  `find.text('دبي')` was hitting the search field, not the city tile), and
  flushes the toast timer; the tasbih/qibla/surah suite gained a Tajawal
  `FontLoader` + `_testTheme`.

### Verification
- `flutter analyze`: no issues.
- `flutter test`: 116/116 passing, incl. 22 azkar_ui, 13 prayer_settings,
  22 tasbeh/qibla/surah, 8 data integrity, and 51 other suite tests.

## 48. Prayer notifications verified to match prayer times (auto / picked / manual)
- New deterministic suite `test/manual/prayer_notifications_match_test.dart`
  (10 tests) drives the **production** `NotificationService`/`PrayerTimeService`
  against recorded channel calls and proves the scheduled slots equal the
  azkar UI values on the **exact wall clock** (not "eventually today"), for all
  three input modes:
  - **Auto (GPS)**: hour/minute stored for the device timezone == the scheduled
    hour/minute (identity, not just "same epoch"), including a full cold-start
    calculate → store → schedule round trip.
  - **Picked city**: e.g. Cairo scheduled from a UTC device fires at the exact
    Cairo wall-clock minute; Dubai scheduled from a Los Angeles device matches
    Dubai's displayed `Asr`/timezone wall clock (and is never in the past).
  - **Manual user input**: `prayer_override_*` rows fire at the user's typed
    time while untouched rows keep the calculated times; editing re-schedules;
    switching city (provider `setCity`) re-calcs and re-schedules to the new
    city's times and cancels the old schedule's azkar slot.
  - Derived rules: pre-adhan −10 min; Quran-after-salah +30 min; azkar defaults
    Fajr+30 / Asr+30; custom morning/evening azkar times honored.
- Fixes uncovered while testing:
  - `settings_repro_test.dart` used the raw string `'eveningAzkarTime'` instead
    of `PrefsKeys.eveningAzkarTime`, silently never exercising the custom
    evening-azkar path; fixed and asserted on the ISO `18:30` slot.
  - `prayer_settings_ui_test.dart` city-picker test now asserts the fake
    notification service's `cancelCalls` grows after picking Dubai (proves the
    picked-city → reschedule wiring, not just navigation).
- Added `integration_test/prayer_notifications_test.dart` (new
  `integration_test:` dev dependency): drives the real iOS plugin on the booted
  simulator, seeds Cairo state, schedules through the production service, and
  verifies (a) every native `addNotificationRequest` completes without error
  and (b) the OS pending list ends up holding exactly the five adhan slots
  (ids 100–104, title `حان وقت الصلاة`) — confirmed on a run where the
  simulator's notification daemon exposed the list. Notification authorization
  is not required for pending retention; the list may briefly lag scheduling,
  so the test polls it for 10s. On simulator/CI runs where the daemon never
  exposes pending requests even for trivial, fully-valid one-shot schedules
  (isolated with a baseline diagnostic), it gracefully degrades to the
  no-error wiring check instead of flaking red.

### Verification
- `flutter test`: 126/126 passing (10 new notification-matching tests).
- `flutter analyze`: no issues.
- Simulator `flutter test integration_test/... -d <iPhone 17 Pro Max>` passes;
  a run confirmed the real OS pending list held exactly ids 100–104 with
  title `حان وقت الصلاة` (other runs hit the daemon introspection quirk and
  passed via the no-error wiring check).

## 49. Quran audio no longer depends on the `quran` package
- The audio feature previously pulled its mp3 URL from `package:quran`
  (`getAudioURLBySurah`) and its display name from `getSurahNameArabic`; both
  are now served by a self-contained helper
  `QuranAudioSource` (`lib/features/quran/presentation/utils/
  quran_audio_source.dart`):
  - `QuranAudioSource.urlForSurah(n)` reproduces the very same CDN URL
    (`cdn.islamic.network/quran/audio-surah/128/ar.alafasy/<n>.mp3`) with
    optional reciter/bitrate overrides, so existing behavior is unchanged and
    the download/play pipeline (dio + just_audio local-file playback) needs no
    `quran` package anywhere.
  - `QuranAudioSource.surahArabicNames` + `surahName(n)` carry the 114 Arabic
    surah names (identical to what the audio card showed before), with a safe
    fallback for invalid numbers.
- `audio_player_card.dart` and `audio_controllers.dart` no longer import
  `package:quran` at all. The `quran` package remains a dependency only for
  the reader's mushaf text and surah-list metadata (page/verse text, juz,
  revelation place), which is out of scope.
- Verified live: the produced URL returns `200` with `audio/mpeg` (1.4 MB
  for Al-Fatiha).

### Verification
- `flutter test`: 131/131 passing (5 new `quran_audio_source_test` tests).
- `flutter analyze`: no issues.

## 50. Android builds fixed on Codemagic
- Codemagic's `bundleRelease` was failing at the version gate: the project used
  Gradle 8.12, AGP 8.9.1 and Kotlin 2.1.0, all below the minimums required by
  the current Flutter stable toolchain (Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20).
- Bumped the Android wrapper to `gradle-8.14-all.zip`
  (`android/gradle/wrapper/gradle-wrapper.properties`) and the plugin versions
  to AGP `8.11.1` / Kotlin `2.2.20` in `android/settings.gradle.kts`.
- `android/build/` is now gitignored and the single accidentally-committed
  problems report was untracked.

### Verification
- `flutter build apk --debug`: builds.
- `flutter build appbundle --release` (with Codemagic-style `CI=true` +
  `CM_KEYSTORE_*` env): builds, `bundleRelease` success (79.1 MB AAB) — the
  exact task that failed on the CI.
- `flutter analyze`: no issues.

## 51. Quran reader migrated to `qcf_quran_lite` (mushaf rendering + lazy tafseer)
- The reader no longer depends on `package:quran` (removed from `pubspec.yaml`).
  It now renders real Madinah mushaf pages via `qcf_quran_lite: ^0.0.5`
  (`QuranPageView`), which draws each physical page (1–604) exactly as printed,
  including the decorative surah banner and basmalah automatically.
- `quran_details_page.dart` was rewritten around `QuranPageView`:
  - One page entry per physical page (the old "virtual page" splitting of
    overlapping surahs is obsolete — the mushaf page shows everything).
  - Resume-from-saved-page, auto-save on page turn, surah-change audio reset,
    info row (سورة/الجزء/صفحة), surah picker, next/previous surah, page
    nav, floating header, side tools, audio card and tap-to-toggle controls
    all preserved. Surah navigation now jumps straight to the physical page
    where the surah starts (`getPageNumber(surah, 1) - 1`).
  - Font sizing still works: the pack's `textScaleFactor` is fed to
    `ayahStyle` (the package's own Hafs/Uthmani font stays intact).
- `quran_list.dart` (surah index sheet) now uses `qcf_quran_lite` for names,
  juz, verses and Makkah/Madinah metadata (same API signatures as before).
- Tafseer added as a lazy-loading bottom sheet:
  - `TafseerService` (`lib/features/quran/data/services/tafseer_service.dart`)
    fetches a single ayah's tafseer on demand from `api.alquran.cloud`
    (Al-Muyassar edition) with in-memory caching and a 15s timeout, instead of
    bundling a multi-MB tafseer DB.
  - `TafseerSheet` opens on long-press of any ayah: shows the ayah text, a
    loading state, the translated tafseer, and a retry on offline errors.

### Verification
- `flutter test`: 138/138 passing (5 new `tafseer_service_test` cleaning
  tests + 2 `quran_page_view_smoke_test` widget tests that render the mushaf
  and confirm `onPageChanged` reports physical page numbers).
- `flutter analyze`: no issues.

## 52. Quran reader: floating overlays replaced with clean app bar + bottom bar
- Removed the three floating/animated controls from the reader (the padded
  floating header strip, the rounded pill bottom-navigation, and the side
  tools rail) and the associated tap-to-show/hide behavior.
- The reader now uses a standard `AppBar`:
  - Title `القرآن الكريم` with a centered back button.
  - Actions: surah index (`QuranList` sheet), font size (`QuranFontSheet`),
    bookmark toggle (independent of the auto-resume position, amber when set),
    and audio toggle (highlighted while open).
  - `bottom` strip: a thin reading-progress line plus a compact
    `سورة • الجزء • صفحة` status line.
- New slim, always-visible bottom bar with just four icon buttons (previous
  surah, previous page, next page, next surah) and a small centered page pill
  (`صفحة X / 604`).
- Deleted the now-unused `bottom_navigation_controls.dart` and `side_tools.dart`
  widgets; their logic (surah picker, bookmark, page/surah navigation, audio)
  was folded into the page. Audio card still slides in above the bottom bar
  with bottom padding added to the mushaf so the last line stays readable.

### Verification
- `flutter test`: 138/138 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.

## 53. App bar cleanup + compact audio bar in the Quran reader
- App bar title is now the current surah name (`سورة الفاتحة`) instead of the
  generic `القرآن الكريم`; it updates as the reader flips pages. The status
  line below shows the remaining info (`الجزء • صفحة`).
- Removed the font-size action from the app bar and the `QuranFontSheet`
  widget; mushaf text stays at the package's default size.
- The audio UI is no longer a large floating card (155h) that pushed the page
  text up. It's now a slim 62h bar docked above the bottom bar: play/pause,
  surah name, download status, a thin seek slider (live via position stream),
  and a close button. The page only reserves ~96h of padding while audio is
  visible.
- Deleted the now-unused `quran_font_sheet.dart`, `audio_slider.dart`,
  `audio_controllers.dart` and `infinate_download_icon.dart`.
- Fixed the crash thrown when tapping the audio play button:
  `setState() callback argument returned a Future` was caused by an arrow
  closure (`setState(() => _x = _checkDownloaded())`) returning the future
  from the callback; switched to a block body and added `didUpdateWidget` so
  the download status re-checks when the surah changes while the card stays
  alive.

### Verification
- `flutter test`: 140/140 passing (added `audio_player_card_test.dart` — 2
  widget tests: play tap doesn't crash + status icon, and status updates on
  surah change).
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 54. Elapsed / total time in the compact audio bar
- **(Removed again in §60 — the time label caused enough friction that it was
  dropped.)**
- The slim audio bar now shows the playback position and total duration next
  to the seek slider (`0:12 / 3:04`, `h:mm:ss` for surahs over an hour), e.g.
  Al-Baqarah. The time only applies while the loaded surah is on screen;
  otherwise it reads `0:00 / 0:00` like the slider.
- Added a `_formatTime` helper and a `textContaining(' / ')` assertion to the
  audio bar widget test.

### Verification
- `flutter test`: 142/142 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 58. Reader bottom bar: page pill only (swipe-driven navigation)
- Removed the four arrow buttons (prev/next surah + page) from the reader
  bottom bar. Page turns are done by horizontal swipes (the PageView), and
  surah jumps via the surah-list icon in the app bar.
- The bottom bar now holds only the centered page pill (`X / ٦٠٤`) in a slim
  44h strip for at-a-glance orientation.
- Removed the now-unused `_buildBarButton` helper and the `_goTo*Page` /
  `_goTo*Surah` methods.

### Verification
- `flutter test`: 142/142 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 55. Bookmark icon updates on tap + audio bar floats over the page
- Fixed the bookmark not updating when tapped: the reader page read the
  provider with `listen: false` and never rebuilt on `notifyListeners()`, so
  the icon stayed stale until a page flip. The bookmark button now renders
  inside a `Consumer<QuranProvider>` (same wiring as before, but subscribed).
- The audio bar is now a true floating overlay: the reserved `96h` bottom
  padding on the mushaf page was removed, so opening audio no longer pushes the
  page text up. Added a 250ms `AnimatedSwitcher` for show/hide.
- Enlarged the audio bar: height 62→76h, play button 42→46h, surah name
  13→16sp, time 10→12sp, status icon 16→18, close 18→20, play icon 26→28h.
- Tests: extracted shared doubles to `test/helpers/quran_test_doubles.dart`
  and `fake_just_audio_platform.dart`; added `quran_bookmark_test.dart`
  (bookmark icon toggles immediately on tap via the Consumer wiring).

### Verification
- `flutter test`: 142/142 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 59. Quran audio: play while downloading (stream + cache in one transfer)
- **(Reverted in §60 at the user's request — the reader downloads the full surah
  before playing again. Kept here for history.)**
- Surah audio no longer has to finish downloading before it can play. The
  provider now uses just_audio's `LockCachingAudioSource`, which streams the
  surah to the player **while writing it to disk in the same single transfer**,
  so long surahs (Al-Baqarah etc.) start playing within seconds instead of
  after a multi-minute full download. Bandwidth is not doubled.
- Offline caching is preserved: the file is written to a `.part` file and only
  promoted to its final name when the download completes, so the "downloaded"
  check stays truthful. Already-cached surahs still play instantly from the
  local file (`setFilePath`), no network.
- Added `GetSurahAudioPathUseCase` (returns the local path without downloading)
  and registered it in DI. Removed the now-unused `GetSurahAudioUseCase`
  (the dio pre-download that blocked playback).
- Provider: added `downloadProgress` (0..1), an `isBuffering` getter, and
  internal progress tracking tied to the caching source. `resetAudio()` and
  `dispose()` tear down the progress subscription.
- Audio bar: the status icon now shows a determinate progress ring while a
  surah is being cached while playing, and flips to the "available offline"
  check automatically when caching finishes (no re-tap needed). The play button
  spinner now means "buffering/loading", not "downloading".
- `LockCachingAudioSource` is marked `@experimental` in just_audio; it is
  wrapped in a single `CachingAudioSource` typedef with one ignore comment to
  avoid scattered analyzer warnings.

### Verification
- `flutter test`: 142/142 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 56. Crash on popping the Quran reader screen (locked widget tree)
- Popping back from the Quran reader crashed with
  `setState() or markNeedsBuild() called when widget tree was locked` on the
  `_InheritedProviderScope<QuranProvider?>`. The page's `dispose()` calls
  `provider.resetAudio()`, which called `notifyListeners()` synchronously
  while the framework was finalizing the route (`finalizeTree` locks the tree).
- Fix: notifications that can originate from teardown/reset-on-pop
  (`resetAudio()` and the audio playback-event listener) are now deferred via
  `scheduleMicrotask` with a `hasListeners` guard (`_notifyListenersSafely`).
- Added `quran_provider_pop_test.dart` that pops a screen whose `dispose()`
  calls `resetAudio()` while a `Consumer` listens. Confirmed it reproduces the
  exact lock error on the old code and passes after the fix.

### Verification
- `flutter test`: 142/142 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 57. Quran reader nav arrows look like page chevrons, not media controls
- Replaced the Cupertino `forward_end`/`backward_end` double-triangle glyphs
  (which read as "skip to next/previous track" media controls) with chevrons:
  pages use `Icons.chevron_left`/`chevron_right`, surahs use the double
  chevrons `keyboard_double_arrow_left`/`right` for the bigger jump.
- The bottom bar `Row` already lays out right→left under the app's RTL
  locale, so "previous" sits on the right (chevrons point right) and "next"
  on the left (chevrons point left); no ordering change was needed.

### Verification
- `flutter test`: 142/142 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 60. Audio back to full download, no time label, slider assertion fixed
- Undid the §59 stream-while-downloading implementation. `QuranProvider` is back
  to `GetSurahAudioUseCase`: the surah is downloaded completely to its local path
  and only then `setFilePath()` + `play()` run. `GetSurahAudioPathUseCase` and its
  DI registration are gone; `QuranRepository.downloadSurah` and the full-download
  behaviour are unchanged.
- Removed the elapsed/total time text from the audio bar (added in §54, then
  restored in §61 with the fix below).
- Fixed the crash reported when stopping playback:
  `'value >= min && value <= max': Value 12318.0 is not between minimum 0.0 and
  maximum 1.0`. The position stream can still carry the last position while the
  duration is unknown, which collapsed `Slider.max` to 1ms. The value is now
  clamped to `[0, max]` before the `Slider` is built.
- Restored the status icon to the plain download spinner (no progress ring), and
  the play button spinner again means "downloading", not "buffering".
- Tests: `ControllableQuranProvider` in `test/helpers/quran_test_doubles.dart`
  exposes the position stream and the playing surah directly, so
  `audio_player_card_test.dart` can reproduce the stale-position/unknown-duration
  case without depending on just_audio internals. Verified the test throws the
  exact assertion when the clamp is removed.

### Verification
- `flutter test`: 143/143 passing.
- `flutter analyze`: no issues.
- `flutter build ios --simulator --debug` + `simctl install/launch`: app runs.
- Not committed (user asked to pause pushing).

## 61. Play time is back in the audio bar and actually updates
- Restored the `0:12 / 3:04` counter in the audio bar (dropped in §60) and fixed
  why it never showed in the first place: the label was built inside a
  `StreamBuilder` on `positionStream` only, and it read `player.duration`
  synchronously. just_audio learns the duration *after* loading, and no position
  event arrives while the surah is paused, so the text stayed `0:00 / 0:00` and
  was never refreshed even once the duration was known.
- The counter now also listens to `player.durationStream`, so the total appears
  as soon as the surah loads — even before playback starts — and the elapsed part
  follows the position stream. The `Slider` keeps the §60 clamp, so a stale
  position with an unknown duration can no longer trip
  `'value >= min && value <= max'`.
- Tests: `ControllableQuranProvider` exposes `emitDuration()` alongside
  `emitPosition()`, so `audio_player_card_test.dart` covers the "duration
  arrives without any position event" case. Verified the test fails against the
  old `positionStream`-only implementation.

### Verification
- `flutter test`: 144/144 passing.
- `flutter analyze`: no issues.
- Not committed (user asked to pause pushing).

## 62. Opening the Quran reader starts at the bookmarked page
- The reader now prefers the bookmark over the auto-saved "last read" position
  when it opens: `QuranDetailPage.initState()` starts at
  `provider.bookmarkPage` if a bookmark exists, and only falls back to
  `provider.savedLatestQuranPageNumber` when there is none (or the value is
  outside the 1..604 mushaf range, which is treated as corrupt and ignored).
  Previously the bookmark was display-only — the reader always resumed from the
  auto-saved page, so the bookmark icon pointed at a page you had to hunt for.
- Flipping pages still re-saves the auto-resume position, so removing the
  bookmark returns the reader to where you left off.
- Tests: `quran_details_page_bookmark_test.dart` mounts the real reader and
  covers all three cases (bookmark wins, fallback without a bookmark, invalid
  bookmark ignored). Verified they fail against the old resume-only logic.
  `buildTestQuranProvider` gained a `getQuranPageNumberUseCase` seam.

### Verification
- `flutter test`: 147/147 passing.
- `flutter analyze`: no issues.
- Not committed (user asked to pause pushing).
