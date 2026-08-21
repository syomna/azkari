# Azkari — Fix Plan

> Prioritized fixes from the `APP_QUALITY_AUDIT.md`. Organized into 5 phases by dependency order.

---

## Phase 1: Crash & Safety Fixes (Day 1)

### 1.1 — Fix `_loadPages` crash and hang (Critical)

**File:** `lib/features/quran/presentation/screens/quran_details_screen.dart:48-63`

**Problem:** No `mounted` check before `setState` after `await compute()`. No try-catch — if `compute` throws, the loading spinner hangs forever.

**Fix:**
```dart
Future<void> _loadPages() async {
  try {
    final pages = await compute(_generateVirtualPages, null);
    if (!mounted) return;
    _virtualPages.addAll(pages);

    final provider = Provider.of<QuranProvider>(context, listen: false);
    int savedPage = provider.savedLatestQuranPageNumber ?? 1;
    int savedSurah = provider.savedLatestQuranSurahNumber ?? 1;

    _currentIndex = _virtualPages.indexWhere((page) =>
        page.globalPageNumber == savedPage &&
        page.surahSegments.any((seg) => seg['surah'] == savedSurah));

    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
    setState(() => _isLoading = false);
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = e.toString();
    });
  }
}
```

Add `_errorMessage` field and error state UI:
```dart
if (_errorMessage != null) {
  return AppErrorWidget(
    message: AppStrings.unexpectedError,
    onRetry: () {
      setState(() { _errorMessage = null; _isLoading = true; });
      _loadPages();
    },
  );
}
```

### 1.2 — Fix `randomNameIndex` out-of-bounds (Critical)

**File:** `lib/features/home/presentation/screens/home_screen.dart:41-48, 219-227`

**Problem:** `_randomNameIndex` is computed once in `initState` from list length. If the list changes (e.g., reloaded), the index may be out of bounds. The guard at line 219 checks `.isNotEmpty` but not `index < length`.

**Fix:** Move random index computation to `build`, or guard the access:
```dart
// Replace lines 219-227:
final namesList = context.read<NamesOfAllahProvider>().namesOfAllahList;
if (namesList.isNotEmpty && _randomNameIndex < namesList.length) {
  NamesOfAllahCard(item: namesList[_randomNameIndex]);
}
```

Also, make `initState` more defensive:
```dart
@override
void initState() {
  super.initState();
  final namesList = context.read<NamesOfAllahProvider>().namesOfAllahList;
  if (namesList.isNotEmpty) {
    _randomNameIndex = Random().nextInt(namesList.length);
  }
  // ...
}
```

### 1.3 — Add `mounted` check to `audio_controllers.dart` (High)

**File:** `lib/features/quran/presentation/widgets/audio_controllers.dart:31-38`

**Fix:**
```dart
Future<bool> _checkDownloaded() async {
  if (!mounted) return false;
  final provider = Provider.of<QuranProvider>(context, listen: false);
  final result = await provider.checkSurahDownloadedUseCase(widget.surahNumber);
  if (!mounted) return false;
  return result.fold((_) => false, (downloaded) => downloaded);
}
```

### 1.4 — Add `mounted` checks to `_rescheduleNotifications` (Medium)

**File:** `lib/core/providers/notification_provider.dart`

**Problem:** Multiple `setState` calls after async gaps without `mounted` checks.

**Fix:** Add `if (!mounted) return;` before each `setState` in the method.

---

## Phase 2: Architecture Cleanup (Day 1-2)

### 2.1 — Fix Quran repository error handling pattern (High)

**Problem:** `QuranRepository` interface returns `void` (throws on error). All 8 use cases wrap in `try/catch` to return `Either`. Error handling is in the domain layer instead of data layer.

**Contrast with Azkar pattern:**
- Azkar: Repository interface returns `Either` → Repository impl catches → Use case forwards
- Quran: Repository throws → Use case catches (wrong!)

**Fix steps:**

1. **Change `QuranRepository` interface** (`lib/features/quran/domain/repositories/quran_repository.dart`):
```dart
abstract class QuranRepository {
  Future<Either<Failure, void>> saveLatestQuranSurahNumber(int surahNumber);
  Either<Failure, int?> getLatestQuranSurahNumber();
  Future<Either<Failure, void>> saveQuranPageNumber(int pageNumber);
  Either<Failure, int?> getSavedQuranPageNumber();
  Future<Either<Failure, void>> clearSavedPosition();
  Future<Either<Failure, void>> clearAllSavedQuranValues();
  Future<Either<Failure, void>> downloadSurah(String url, String savePath);
  Future<Either<Failure, String>> getSurahPath(int surahNumber);
  Future<Either<Failure, bool>> isSurahDownloaded(int surahNumber);
}
```

2. **Change `QuranRepositoryImpl`** to catch exceptions and return `Either`:
```dart
@override
Future<Either<Failure, void>> saveLatestQuranSurahNumber(int surahNumber) async {
  try {
    await quranLocalDataSource.saveLatestQuranSurahNumber(surahNumber);
    return const Right(null);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
// ... same pattern for all methods
```

3. **Simplify all 8 use cases** to just forward:
```dart
@override
Future<Either<Failure, void>> call(int params) async {
  return quranRepository.saveQuranPageNumber(params);
}
```

4. **Update providers** that consume these use cases — they already use `.fold()`, so the API is compatible.

### 2.2 — Remove `try/catch` from Quran use cases (High)

After 2.1, all 8 files in `lib/features/quran/domain/usecases/` become one-liners. Remove the `import 'package:azkar_app/core/error/failures.dart'` and `import 'package:dartz/dartz.dart'` from each since they're no longer needed.

### 2.3 — Extract magic numbers into constants (Medium)

**File:** `lib/core/constants/app_constants.dart`

Add:
```dart
static const int totalQuranPages = 604;
static const int debounceDurationMs = 300;
static const double pulseScaleEnd = 0.97;
static const double doneOpacity = 0.45;
```

Replace occurrences:
- `quran_details_screen.dart:129,164` — `604` → `AppConstants.totalQuranPages`
- `all_azkar_screen.dart:88` — `300` → `AppConstants.debounceDurationMs`
- `display_azkar.dart:47` — `0.97` → `AppConstants.pulseScaleEnd`
- `azkar_details_screen.dart:181` — `0.45` → `AppConstants.doneOpacity`

---

## Phase 3: Error Handling & UX (Day 2)

### 3.1 — Add error state to Quran reader (High)

Already covered in 1.1. The `AppErrorWidget` already exists at `lib/widgets/app_error_widget.dart`.

### 3.2 — Fix prayer times silent disappearance (High)

**File:** `lib/features/prayer_times/presentation/providers/prayer_times_provider.dart:41-46`

**Problem:** If `loadPrayerTimes()` fails, `_prayerTimes` stays null → `PrayerTimesCard` returns `SizedBox.shrink()` → entire prayer section vanishes.

**Fix:** Add an `_error` field to `PrayerTimesProvider`:
```dart
String? _errorMessage;
String? get errorMessage => _errorMessage;
```

Set it in the catch block:
```dart
} catch (e) {
  assert(() { debugPrint('[PrayerTimesProvider] Load failed: $e'); return true; }());
  _errorMessage = 'Failed to load prayer times';
  notifyListeners();
}
```

In `home_screen.dart`, show error widget when `prayerTimesProvider.errorMessage != null`:
```dart
if (prayerTimesProvider.errorMessage != null)
  AppErrorWidget(message: prayerTimesProvider.errorMessage!)
```

### 3.3 — Add loading state to AzkarDetailsScreen (Medium)

**File:** `lib/features/azkar/presentation/screens/azkar_details_screen.dart`

**Problem:** No loading/error states — assumes data is always available.

**Fix:** Check the provider state at the top of `build()`:
```dart
@override
Widget build(BuildContext context) {
  final azkarProvider = Provider.of<AzkarProvider>(context);
  final categoryAzkar = azkarProvider.getCategoryAzkar(widget.categoryName);
  
  if (categoryAzkar.isEmpty) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const AppLoadingWidget(),
    );
  }
  // ... rest of build
}
```

### 3.4 — Fix text overflow in AppBar title (Medium)

**File:** `lib/features/azkar/presentation/screens/azkar_details_screen.dart:66`

**Fix:**
```dart
title: Text(
  widget.title,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
```

### 3.5 — Fix text overflow in surah name row (Medium)

**File:** `lib/features/quran/presentation/screens/quran_details_screen.dart:397`

**Fix:** Wrap in `Flexible`:
```dart
Flexible(
  child: Text(
    '${AppStrings.surahPrefix} ${quran.getSurahNameArabic(widget.surahNumber)}',
    // ...
  ),
),
```

### 3.6 — Fix text overflow in audio controls (Medium)

**File:** `lib/features/quran/presentation/widgets/audio_controllers.dart:83-87`

Same fix as 3.5 — the `Text` in the `Column` under `Expanded` is fine, but the Row with surah name needs wrapping.

---

## Phase 4: Accessibility (Day 3)

### 4.1 — Add Semantics to home screen buttons (High)

**File:** `lib/features/home/presentation/screens/home_screen.dart`

Wrap each `_buildHeaderAction` in `Semantics`:
```dart
Semantics(
  label: 'Toggle theme',
  button: true,
  child: _buildHeaderAction(context, icon, onTap),
)
```

Labels: "Toggle theme", "Contact us", "Settings".

### 4.2 — Add Semantics to FAB (Medium)

**File:** `lib/features/azkar/presentation/screens/all_azkar_screen.dart`

```dart
FloatingActionButton.extended(
  // ...
  child: Semantics(
    label: AppStrings.addZikr,
    child: Row(children: [Icon(...), Text(...)]),
  ),
)
```

### 4.3 — Add Semantics to Dismissible items (Medium)

**File:** `lib/features/azkar/presentation/screens/all_azkar_screen.dart` (in `_CategoryItem.build`)

```dart
Semantics(
  label: '$category, swipe to edit or delete',
  child: Dismissible(...),
)
```

### 4.4 — Add Semantics to AzkarItem cards (Medium)

**File:** `lib/features/azkar/presentation/widgets/azkar_item.dart`

```dart
Semantics(
  label: '$title, $count items${isFavorite ? ', favorited' : ''}',
  button: true,
  child: InkWell(...),
)
```

### 4.5 — Add Semantics to settings tiles (Low)

**File:** `lib/features/settings/presentation/widgets/settings_list_tile.dart`

Add `Semantics(label: title, button: true, child: ...)`.

### 4.6 — Add Semantics to prayer times card (Low)

**File:** `lib/features/prayer_times/presentation/widgets/prayer_times_card.dart`

Wrap each `PrayerTimeTile` in `Semantics(label: '$prayerName at $time')`.

### 4.7 — Add image alt text (Low)

All image assets (`qibla.png`, `mesbaha.png`, `tasbih.png`) lack semantic labels. Wrap each `Image.asset` in `Semantics(label: 'Qibla compass', child: Image.asset(...))`.

---

## Phase 5: Readability & Polish (Day 3-4)

### 5.1 — Extract build logic from QuranDetailsScreen (Medium)

**File:** `lib/features/quran/presentation/screens/quran_details_screen.dart`

The `build()` method is 126 lines. Extract into widgets:
- `_QuranPageView` — the PageView.builder section
- `_QuranControlBar` — the info row + controls
- `_buildVerseSpan()` — move to a utility function

### 5.2 — Extract shared form validation (Low)

**Files:** `add_azkar_bottom_sheet.dart`, `edit_azkar_bottom_sheet.dart`

Create `lib/features/azkar/presentation/widgets/azkar_form_validator.dart`:
```dart
class AzkarFormValidator {
  static String? validateTitle(String? value, List<String> existingCategories) {
    if (value == null || value.trim().isEmpty) return 'Category title is required';
    if (existingCategories.contains(value.trim())) return 'Category already exists';
    return null;
  }
}
```

### 5.3 — Scope providers to feature screens (Medium)

**File:** `lib/main.dart`

Move provider creation from the global `MultiProvider` to individual screens that need them. Keep only `ThemeProvider`, `FavoritesProvider`, and `NotificationProvider` at app level (they're used across screens). The rest should be scoped.

**Example — HomeScreen:**
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AzkarProvider(...)),
        ChangeNotifierProvider(create: (_) => NamesOfAllahProvider(...)),
        // ...
      ],
      child: _HomeScreenBody(),
    );
  }
}
```

**Impact:** Reduces unnecessary rebuilds when unrelated state changes.

### 5.4 — Add dartdoc to public classes (Low)

At minimum, add one-line dartdoc to:
- `QuranPageItem` — "Represents a virtual Quran page with its surah segments."
- All use case classes — "Fetches [X] from [repository]."
- All entity classes — "Domain model for [feature]."
- `_ListItem` sealed class — "Base type for items in the AllAzkarScreen unified list."

---

## Verification Checklist

After each phase, run:
```bash
flutter analyze        # Should show 0 errors
flutter test           # All existing tests should pass
```

After Phase 2, also run:
```bash
# Regenerate mocks if interface changed
flutter pub run build_runner build --delete-conflicting-outputs
flutter test           # Re-run all tests
```

After Phase 4, manually verify with:
- Android: TalkBack screen reader
- iOS: VoiceOver screen reader
- Flutter: `SemanticsDebugger` widget in debug mode

---

## File Change Summary

| Phase | Files Modified | Files Created |
|-------|----------------|---------------|
| 1 | 3 | 0 |
| 2 | 11 (8 use cases + repo + impl + constants) | 0 |
| 3 | 5 | 0 |
| 4 | 7 | 0 |
| 5 | 6 | 1 (azkar_form_validator.dart) |
| **Total** | **32** | **1** |
