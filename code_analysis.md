# Azkari App — Code Analysis & Improvement Suggestions

A comprehensive analysis of the **Azkari** Flutter application covering UI, Performance, Readability, and Reusability issues across the entire codebase.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [🔴 Critical Issues](#-critical-issues)
3. [🟠 Performance Issues](#-performance-issues)
4. [🟡 UI Issues](#-ui-issues)
5. [🔵 Readability Issues](#-readability-issues)
6. [🟣 Reusability Issues](#-reusability-issues)
7. [🟢 Testing & Quality](#-testing--quality)
8. [Summary Table](#summary-table)

---

## Architecture Overview

The app follows a **Clean Architecture** pattern with Feature-based modules:

```
lib/
├── core/          → Shared constants, enums, errors, providers, services, theme, utils
├── di/            → GetIt dependency injection
├── features/      → Feature modules (azkar, quran, surah, names_of_allah, tasbeh, qibla, widget_guide)
│   └── each has:  data/ (datasources, models, repositories), domain/ (entities, repositories, usecases), presentation/ (screens, providers, widgets)
├── screens/       → Top-level screens (home, splash, settings, contact, adhan, prayer_times_settings)
├── widgets/       → Shared widgets (component, prayer_times_card, welcoming_widget, etc.)
└── main.dart      → Entry point & provider setup
```

> [!NOTE]
> The architecture is well-structured overall. The issues below are refinements, not fundamental flaws.

---

## 🔴 Critical Issues

### 1. `AzkarProvider` is a God-class (SRP Violation)

**File:** [azkar_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/providers/azkar_provider.dart)

`AzkarProvider` manages **five completely separate concerns**: azkar loading, custom azkar CRUD, prayer times, favorites, and prayer time overrides. At 250 lines, it is the largest provider and handles responsibilities that belong to different domains.

**Impact:** Any change to prayer times triggers rebuilds in all azkar consumers and vice versa.

**Suggestion:** Split into focused providers:
- `AzkarProvider` → only azkar loading + custom azkar CRUD
- `PrayerTimesProvider` → prayer times loading, overrides, widget updates
- `FavoritesProvider` → favorites management (shared across features)

---

### 2. `count` field is a `String` instead of `int`

**Files:** [zekr_entity.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/domain/entities/zekr_entity.dart#L6), [azkar_model.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/data/models/azkar_model.dart#L14), [display_azkar.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/widgets/display_azkar.dart#L40)

The `count` field is stored as `String` in the entity, converted to `String` in the model's `fromJson`, and then parsed back to `int` with `int.tryParse()` in every widget that uses it.

```dart
// Entity — stores count as String
final String count;

// Model — converts int to String unnecessarily
count: json['count'].toString(),

// Widget — parses it back to int every time
_total = int.tryParse(widget.zikrEntity.count) ?? 1;
```

**Suggestion:** Make `count` an `int` in `ZekrEntity`. Parse it once in `AzkarModel.fromJson` and keep it as `int` throughout.

---

### 3. Quran repository throws raw strings instead of typed errors

**File:** [quran_repository_impl.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/quran/data/repositories/quran_repository_impl.dart#L47-L59)

```dart
} on DioException catch (e) {
  throw errorMessage;    // ← throws a raw String
} catch (e) {
  throw 'فشل التحميل، تأكد من وجود مساحة كافية';  // ← raw String
}
```

The provider catches this with `e.toString()`:

```dart
} catch (e) {
  _errorMessage = e.toString();  // ← "Instance of 'String'" risk
}
```

**Suggestion:** Use `Either<Failure, String>` as the return type (consistent with the rest of the architecture), or throw custom `Failure` subclasses instead of raw strings.

---

### 4. Duplicate data loading on startup

**Files:** [main.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/main.dart#L85-L91), [splash_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/splash_screen.dart#L57-L71), [azkar_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/providers/azkar_provider.dart#L33-L43)

`AzkarProvider` calls `loadAzkar()` in its constructor (`_initData`), and then `SplashPage._initializeAndNavigate()` calls `azkarProvider.loadAzkar()` **again**. This means azkar JSON is parsed from assets twice on every cold start.

**Suggestion:** Remove the constructor-based `_initData()` call and let `SplashPage` be the single orchestrator for initialization. Or add a guard: only load if status is `initial`.

---

### 5. `_checkedInitialPayload` is set without `setState`

**File:** [main.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/main.dart#L151-L160)

```dart
Future<void> _checkInitialNotification() async {
    final payload = await NotificationService.instance.getInitialNotificationPayload();
    if (payload != null && mounted) {
      setState(() {
        _initialPayload = payload;
      });
    }
    _checkedInitialPayload = true;  // ← No setState, no rebuild triggered
  }
```

`_checkedInitialPayload` is used in `_buildHome()` to decide which widget to return, but it's set outside `setState`, so the build method won't reflect the change until the next unrelated rebuild.

**Suggestion:** Wrap `_checkedInitialPayload = true` inside `setState`.

---

## 🟠 Performance Issues

### 6. JSON re-parsing on every `loadAzkar()` call

**File:** [azkar_local_data_source_impl.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/data/datasources/azkar_local_data_source_impl.dart#L17-L28)

```dart
Future<Either<Failure, List<AzkarModel>>> getAzkar() async {
    final jsonString = await rootBundle.loadString('assets/db/azkar.json');
    List<dynamic> jsonData = json.decode(jsonString);
    List<AzkarModel> azkarList = jsonData.map((json) => AzkarModel.fromJson(json)).toList();
    return Right(azkarList);
}
```

Every call to `loadAzkar()` re-reads and re-parses the entire JSON file from assets. This is an immutable asset — the result should be cached.

**Suggestion:** Cache the parsed list in memory after the first successful load. Use a nullable `List<AzkarModel>? _cachedAzkar` field in the data source.

---

### 7. `AllAzkarPage.build()` does heavy computation every rebuild

**File:** [all_azkar_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/screens/all_azkar_screen.dart#L152-L204)

Inside `build()`:
- Calls `.map().toSet().toList()` to extract unique categories from the full azkar list
- Iterates the full custom list to get custom categories
- Builds a union set
- Filters it
- Sorts with a multi-criteria comparator

All of this runs on **every frame** that `AzkarProvider` emits `notifyListeners()`.

**Suggestion:** Move category computation into `AzkarProvider` as cached getters. Only recompute when the underlying lists change, not on every build.

---

### 8. `getArabicNumber()` creates a new regex + map on every call

**File:** [app_helpers.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/utils/app_helpers.dart#L12-L31)

```dart
static String getArabicNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)'),  // ← new RegExp every time
      (match) {
        const map = { '0': '٠', ... };
        return map[match.group(0)!]!;
      },
    );
  }
```

This is called dozens of times per frame (ayah numbers, page numbers, counter displays). The `RegExp` object is reconstructed every call.

**Suggestion:** Make the `RegExp` a `static final` constant:
```dart
static final _digitRegex = RegExp(r'(\d)');
```

---

### 9. `QuranDetailPage._generateVirtualPages()` runs in `initState` synchronously

**File:** [quran_details_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/quran/presentation/screens/quran_details_screen.dart#L60-L82)

This iterates through all 604 Quran pages, calling `quran.getPageData()` for each, splitting segments, and building ~700+ virtual page objects. This blocks the UI thread during initialization.

**Suggestion:** Pre-compute and cache the virtual pages list as a static/singleton resource (it's deterministic and never changes). Alternatively, use `compute()` for off-main-thread generation.

---

### 10. `PrayerTimesCard` timer causes unnecessary rebuilds

**File:** [prayer_times_card.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/widgets/prayer_times_card.dart#L28-L31)

```dart
_timer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (mounted) setState(() {});
});
```

This forces a full widget rebuild every 60 seconds even when nothing has changed. The timer doesn't check whether the next prayer has actually changed.

**Suggestion:** Only call `setState` when the "next prayer" value actually changes. Compare `nextPrayer()` before and after the timer fires.

---

### 11. `_ensureTimezone()` is called redundantly in every notification method

**File:** [notifications_service.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/services/notifications_service.dart)

`_ensureTimezone()` is called independently in `schedulePrayerNotifications()`, `scheduleDayNightNotifications()`, `periodicallyShowNotification()`, `schedulePreAdhanReminders()`, `scheduleQuranReminderAfterSalah()`, and `scheduleProphetBlessings()`. When `_rescheduleNotifications()` in the provider calls all of them sequentially, `_ensureTimezone()` runs **6 times**, each awaiting a platform channel call.

**Suggestion:** Call `_ensureTimezone()` once at the beginning of a public entry method, or cache the result in `_initNotification()`.

---

## 🟡 UI Issues

### 12. Potential index-out-of-bounds crash on `NamesOfAllahCard`

**File:** [home_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/home_screen.dart#L198-L203)

```dart
NamesOfAllahCard(
  item: context.read<NamesOfAllahProvider>().namesOfAllahList[
      context.read<NamesOfAllahProvider>().namesOfAllahList.isEmpty
          ? 0     // ← If empty, this still accesses index 0
          : _randomNameIndex],
),
```

The ternary returns `0` when the list is empty, but then tries to access `list[0]` on an empty list → `RangeError`.

**Suggestion:** Guard against empty list before rendering `NamesOfAllahCard`, or show a placeholder widget when empty.

### 13. Hardcoded colors instead of using theme

**Files:** Multiple pages including [home_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/home_screen.dart#L79-L81), [splash_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/splash_screen.dart#L115-L117), [all_azkar_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/screens/all_azkar_screen.dart#L90), [settings_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/settings_screen.dart#L204)

`Theme.of(context).brightness == Brightness.dark` is evaluated directly inside `build()` across multiple pages instead of using the `ThemeProvider.isDark` getter or consistent theme extension.

### 14. Double divider in settings page

**File:** [settings_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/settings_screen.dart#L78-L79)

`_buildSettingsCard` adds a `_divider()` between list tiles, BUT `settings_page.dart` also manually adds `_divider()` in its children array before calling `_buildSettingsCard`, resulting in double horizontal lines.

### 15. Non-dismissible loading state on home page

**File:** [home_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/home_screen.dart#L57-L65)

When azkar status is `loading`, the entire home page shows a full-screen `CircularProgressIndicator` with no way to dismiss or retry. If loading hangs, the user is stuck.

**Suggestion:** Add a timeout + retry mechanism, or show a skeleton/shimmer loading state that still allows interaction with other sections (prayer times, etc.).

---

### 16. `ThemeProvider` constructor has unnecessary extra braces

**File:** [theme_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/providers/theme_provider.dart#L8-L13)

```dart
ThemeProvider({required this.prefs}) {
    {   // ← Unnecessary nested block
      _isLight = prefs.getBool(_isLightKey) ?? true;
      _textScaleFactor = prefs.getDouble(_textScaleFactorKey) ?? 1.0;
    }
  }
```

**Suggestion:** Remove the extra nested braces.

---

## 🔵 Readability Issues

### 17. Inconsistent use case naming conventions

**Files:** Various files under `domain/usecases/`

| File | Class Name |
|---|---|
| [save_quran_page_number_usecase.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/quran/domain/usecases/save_quran_page_number_usecase.dart) | `SaveQuranPageNumber`**Usecase** (lowercase 'c') |
| [get_saved_quran_page_number_usecase.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart) | `GetSavedQuranPageNumber`**Usecase** (lowercase 'c') |
| [get_azkar_usecase.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/domain/usecases/get_azkar_usecase.dart) | `GetAzkar`**UseCase** (camelCase) |
| [clear_all_saved_quran_values_usecase.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart) | `ClearAllSavedQuranValues`**UseCase** (camelCase) |

Some use `UseCase` (camelCase), others use `Usecase` (lowercase 'c').

**Suggestion:** Pick one convention (`UseCase`) and apply it consistently across all use case classes.

---

### 18. Leftover commented-out code throughout the codebase

**Files:**
- [quran_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/quran/presentation/providers/quran_provider.dart#L55-L71) — 15+ lines of commented-out methods
- [azkar_details_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/screens/azkar_details_screen.dart#L48) — commented-out alternative provider access
- [theme_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/providers/theme_provider.dart#L26) — commented-out `notifyListeners()`
- [display_azkar.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/widgets/display_azkar.dart#L173) — commented-out conditional

**Suggestion:** Remove all dead commented-out code. Use version control (git) to track old implementations.

---

### 19. No base `UseCase` interface

Each use case class is standalone with no common contract. Some use `call()`, some accept parameters differently (positional vs named). There's no `UseCase<Type, Params>` abstract class.

**Suggestion:** Define a base `UseCase` contract:
```dart
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}
```

---

### 20. `qibla_provider.dart` accesses `Geolocator` directly

**File:** [qibla_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/qibla/presentation/providers/qibla_provider.dart#L38-L69)

The comment on line 71 says "Clean Arch: Provider doesn't know about Geolocator, only the Repo," yet `QiblaProvider.init()` calls `Geolocator.isLocationServiceEnabled()`, `Geolocator.checkPermission()`, and `Geolocator.requestPermission()` directly. This violates the stated architectural boundary.

**Suggestion:** Move location permission logic into the repository or a dedicated `LocationService`. The provider should only call high-level methods like `repository.getQiblaDirection()` which handles permissions internally.

---

### 21. Mix of Arabic and English comments

Throughout the codebase, comments switch between Arabic (`// سحب لليسار -> تأكيد الحذف`) and English (`// Prevent multiple concurrent calls if already loading`). Some files use emoji-laden markers (`// 📍 NEW:`, `// 👈`).

**Suggestion:** Pick one language for code comments (English is conventional) and be consistent. Use meaningful, clean comments without emojis.

---

### 22. `settings_screen.dart` has helper functions outside the class scope

**File:** [settings_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/settings_screen.dart#L209-L361)

Functions like `_buildSectionHeader()`, `_buildSettingsCard()`, `_buildListTile()`, `_buildFontSlider()`, and `_showAboutAppDialog()` are defined as **top-level functions** after the class ends, even though they're prefixed with `_` suggesting they should be private to the class. Top-level `_` functions are file-private, not class-private — this is misleading.

**Suggestion:** Move these into the `_SettingsScreenState` class as methods, or extract them into dedicated widget classes.

---

## 🟣 Reusability Issues

### 23. Duplicated prayer name maps across multiple files

**Files:**
- [app_helpers.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/utils/app_helpers.dart#L94-L100) — `AppHelpers.prayerNames`
- [adhan_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/adhan_screen.dart#L26-L31) — `_prayerNamesAr`
- [prayer_times_service.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/services/prayer_times_service.dart#L14) — `prayerKeys`

Prayer name mappings and key lists are defined independently in three places. If a prayer is added or renamed, all three must be updated manually.

**Suggestion:** Centralize all prayer-related constants (keys + Arabic names) in `AppConstants` or a dedicated `PrayerConstants` class and reference it everywhere.

---

### 24. Duplicated location-fetching logic

**Files:**
- [azkar_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/providers/azkar_provider.dart#L67-L95) — `loadPrayerTimes()`
- [notification_provider.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/core/providers/notification_provider.dart#L110-L122) — `_rescheduleNotifications()`

Both providers independently fetch lat/lng from SharedPreferences, fall back to `prayerTimeService.getCurrentLocation()`, and store the result. This is the same ~15-line block copy-pasted.

**Suggestion:** Extract location resolution into a single method on `PrayerTimeService` (e.g., `ensureLocation(SharedPreferences prefs) → (double lat, double lng)?`) and call it from both places.

---

### 25. No shared `ErrorWidget` / `EmptyState` / `LoadingState` widgets

**Files:** Multiple screens define their own `_buildEmptyState()` inline:
- [all_azkar_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/screens/all_azkar_screen.dart#L485-L495)
- [azkar_details_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/features/azkar/presentation/screens/azkar_details_screen.dart#L216-L234)
- [home_screen.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/screens/home_screen.dart#L59-L71)

Each has a slightly different implementation and style.

**Suggestion:** Create shared `AppLoadingWidget`, `AppEmptyState`, and `AppErrorWidget` in `lib/widgets/` with consistent styling and reuse across all pages.

---

### 26. `Component` widget name is too generic

**File:** [component.dart](file:///Users/yomna/Downloads/Projects/azkari/lib/widgets/component.dart)

`Component` is a navigation grid tile used on the home page. The name gives no hint of its purpose, making it difficult for new developers to discover.

**Suggestion:** Rename to `HomeGridTile` or `FeatureCard`.

---

### 27. `tasbeh` feature has no data/domain layers

**File structure:** [tasbeh/](file:///Users/yomna/Downloads/Projects/azkari/lib/features/tasbeh)

```
features/tasbeh/
└── presentation/
    ├── screens/
    ├── providers/
    └── widgets/
```

Unlike all other features, `tasbeh` has no `data/` or `domain/` layer. `TasbehProvider` accesses `SharedPreferences` directly. While simple, this inconsistency makes the architecture harder to navigate.

**Suggestion:** For consistency, add a thin `TasbehRepository` abstraction. This also makes it testable.

---

### 28. `widget_guide` feature doesn't follow clean architecture

**File structure:** [widget_guide/](file:///Users/yomna/Downloads/Projects/azkari/lib/features/widget_guide)

```
features/widget_guide/
├── data/
├── models/
├── presentation/
├── widget_guide_helper.dart
└── widgets/
```

Uses `data/`, `models/`, and `widgets/` at the same level instead of the standard `data/models/`, `domain/entities/`, `presentation/widgets/` pattern.

**Suggestion:** Restructure to match the project's established convention.

---

### 29. `Either<Failure, T>` used inconsistently

The `azkar`, `names_of_allah`, and `surah` features use `Either<Failure, T>` from `dartz` for error handling. But `quran` feature throws raw strings/exceptions. `tasbeh` uses neither. `qibla` throws generic `Exception` objects.

**Suggestion:** Standardize on `Either<Failure, T>` across all features for consistency.

---

## 🟢 Testing & Quality

### 30. Virtually no tests

**Test directory:** [test/](file:///Users/yomna/Downloads/Projects/azkari/test)

The `test/` directory contains only an empty `features/` subdirectory. There are **zero test files** despite having `flutter_test`, `mockito`, and `build_runner` in dev dependencies.

**Suggestion:** Add tests incrementally:
1. **Unit tests** for all use cases (they're simple and pure — ideal candidates)
2. **Unit tests** for providers (inject mock repositories)
3. **Widget tests** for key UI components like `DisplayAzkar`, `PrayerTimesCard`
4. **Integration tests** for critical flows (splash → home, azkar details counting)

---

### 31. `analysis_options.yaml` present but lints may not be fully enforced

**File:** [analysis_options.yaml](file:///Users/yomna/Downloads/Projects/azkari/analysis_options.yaml)

The project uses `flutter_lints` (v6), but several patterns in the codebase suggest stricter lints could catch issues:
- Unused imports
- `print` statements (use `debugPrint` or `log`)
- Non-`const` constructors where possible

**Suggestion:** Consider upgrading to `very_good_analysis` or at least enabling stricter rules like `avoid_print`, `prefer_const_constructors`, and `sort_constructors_first`.

---

## Summary Table

| # | Category | Severity | Issue | File(s) |
|---|----------|----------|-------|---------|
| 1 | Readability | 🔴 Critical | `AzkarProvider` is a God-class | `azkar_provider.dart` |
| 2 | Readability | 🔴 Critical | `count` is `String` instead of `int` | `zekr_entity.dart`, `azkar_model.dart` |
| 3 | Readability | 🔴 Critical | Raw string throws instead of typed errors | `quran_repository_impl.dart` |
| 4 | Performance | 🔴 Critical | Duplicate data loading on startup | `main.dart`, `splash_page.dart` |
| 5 | UI | 🔴 Critical | `_checkedInitialPayload` set without `setState` | `main.dart` |
| 6 | Performance | 🟠 Medium | JSON re-parsed on every call | `azkar_local_data_source_impl.dart` |
| 7 | Performance | 🟠 Medium | Heavy computation in `build()` | `all_azkar_page.dart` |
| 8 | Performance | 🟠 Medium | RegExp recreated on every call | `app_helpers.dart` |
| 9 | Performance | 🟠 Medium | 700+ virtual pages generated synchronously | `quran_details_page.dart` |
| 10 | Performance | 🟡 Low | Timer causes unconditional rebuilds | `prayer_times_card.dart` |
| 11 | Performance | 🟡 Low | `_ensureTimezone()` called 6× redundantly | `notifications_service.dart` |
| 12 | UI | 🔴 Critical | Potential `RangeError` on empty names list | `home_page.dart` |
| 13 | UI | 🟡 Low | Hardcoded colors instead of theme | Multiple files |
| 14 | UI | 🟡 Low | Double divider in settings | `settings_page.dart` |
| 15 | UI | 🟡 Low | No retry on loading failure | `home_page.dart` |
| 16 | Readability | 🟡 Low | Extra braces in constructor | `theme_provider.dart` |
| 17 | Readability | 🟡 Low | Inconsistent `UseCase` naming | Multiple use case files |
| 18 | Readability | 🟡 Low | Commented-out dead code | Multiple files |
| 19 | Readability | 🟡 Low | No base `UseCase` interface | All use cases |
| 20 | Readability | 🟠 Medium | Provider violates its own stated architecture | `qibla_provider.dart` |
| 21 | Readability | 🟡 Low | Mixed Arabic/English comments | Multiple files |
| 22 | Readability | 🟡 Low | Helper functions outside class scope | `settings_page.dart` |
| 23 | Reusability | 🟠 Medium | Duplicated prayer name maps | 3 files |
| 24 | Reusability | 🟠 Medium | Duplicated location-fetching logic | 2 providers |
| 25 | Reusability | 🟡 Low | No shared empty/loading/error widgets | Multiple pages |
| 26 | Reusability | 🟡 Low | `Component` name is too generic | `component.dart` |
| 27 | Reusability | 🟡 Low | `tasbeh` feature has no data/domain layers | `tasbeh/` |
| 28 | Reusability | 🟡 Low | `widget_guide` doesn't follow clean arch | `widget_guide/` |
| 29 | Reusability | 🟠 Medium | `Either<Failure, T>` used inconsistently | Multiple features |
| 30 | Testing | 🔴 Critical | Zero tests in the entire project | `test/` |
| 31 | Testing | 🟡 Low | Lint rules could be stricter | `analysis_options.yaml` |

---

> [!TIP]
> **Prioritized action items** — If tackling these incrementally:
> 1. Fix the `RangeError` crash risk (#12) and `setState` bug (#5) — immediate crash/bug risk
> 2. Split `AzkarProvider` (#1) and remove duplicate loading (#4) — biggest architectural win
> 3. Cache JSON parsing (#6) and move category computation out of `build()` (#7) — biggest performance win
> 4. Add unit tests for use cases and providers (#30) — highest quality ROI
> 5. Standardize error handling across features (#3, #29) — consistency
