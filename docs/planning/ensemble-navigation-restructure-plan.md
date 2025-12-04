# Ensemble Navigation Restructure Implementation Plan

**Plan Date:** December 4, 2025
**Branch:** feature/fixed-bottom-nav-fluid-animations
**Planned By:** Claude Code
**Based On:** `/home/home-server/Ensemble/docs/analysis/ensemble-navigation-animation-analysis.md`

---

## Overview

This implementation plan restructures the Ensemble app's navigation architecture to achieve:

1. Fixed bottom navigation bar (no animation during page transitions)
2. Adaptive colors that update based on selected album/artist
3. Mini player that expands OVER the bottom navigation
4. Fluid hero animations for albums, artists, and mini player
5. Fix broken library → artist hero animation
6. Seamless integration without architectural "brute forcing"

**Chosen Approach:** Remove duplicate bottom navigation bars from detail screens (AlbumDetailsScreen, ArtistDetailsScreen) and fix hero animation tags in Library screen.

**Rationale:**
- Simplest solution requiring only code removal and minor additions
- Completely eliminates bottom nav animation during transitions
- Low risk with easy rollback capability
- Standard pattern used by major music apps (Spotify, Apple Music)
- Implementation time: ~2 hours including testing
- No new dependencies required

---

## Prerequisites Checklist

Before starting implementation:

- [x] Analysis document completed and reviewed
- [x] Working branch exists: `feature/fixed-bottom-nav-fluid-animations`
- [ ] All uncommitted changes backed up or committed
- [ ] Development environment running (Flutter SDK, emulator/device)
- [ ] Hot reload working correctly
- [ ] Test device/emulator has adequate performance for hero animations
- [ ] User approval on approach (remove bottom nav from detail screens)

**Critical Files Identified:**
- `/home/home-server/Ensemble/lib/screens/new_library_screen.dart` - Add hero tags
- `/home/home-server/Ensemble/lib/screens/album_details_screen.dart` - Remove bottom nav
- `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart` - Remove bottom nav

---

## Phase 1: Fix Library → Artist Hero Animation

**Goal:** Enable smooth hero animation when navigating from Library artists list to ArtistDetailsScreen

**Problem:** Library screen uses plain ListTiles without Hero widgets, while ArtistDetailsScreen expects hero tags with '_library' suffix. This causes Flutter to fall back to cross-fade instead of morphing animation.

### Implementation Steps

#### Step 1.1: Import Hero Tags Constant
**File:** `/home/home-server/Ensemble/lib/screens/new_library_screen.dart`
**Location:** Top of file (imports section)

**Action:** Verify hero_tags.dart is imported. If not, add:
```dart
import '../constants/hero_tags.dart';
```

**Verification:** Check if `HeroTags` class is available in file scope.

---

#### Step 1.2: Wrap CircleAvatar in Hero Widget
**File:** `/home/home-server/Ensemble/lib/screens/new_library_screen.dart`
**Location:** Lines 206-235 (within `_buildArtistTile` method)

**Current Code:**
```dart
ListTile(
  leading: CircleAvatar(
    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
  ),
  title: Text(artist.name),
  onTap: () { ... },
)
```

**New Code:**
```dart
Widget _buildArtistTile(BuildContext context, Artist artist, MusicAssistantProvider provider) {
  final imageUrl = provider.getImageUrl(artist, size: 128);
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final suffix = '_library';

  return ListTile(
    leading: Hero(
      tag: HeroTags.artistImage + (artist.uri ?? artist.itemId) + suffix,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.surfaceVariant,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? Icon(Icons.person_rounded, color: colorScheme.onSurfaceVariant)
            : null,
      ),
    ),
    title: Hero(
      tag: HeroTags.artistName + (artist.uri ?? artist.itemId) + suffix,
      child: Material(
        color: Colors.transparent,
        child: Text(
          artist.name,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
    onTap: () {
      Navigator.push(
        context,
        FadeSlidePageRoute(
          child: ArtistDetailsScreen(
            artist: artist,
            heroTagSuffix: 'library',
          ),
        ),
      );
    },
  );
}
```

**Key Changes:**
- Wrap `CircleAvatar` in `Hero` widget with tag: `artistImage + uri + '_library'`
- Wrap `Text(artist.name)` in `Hero` widget with tag: `artistName + uri + '_library'`
- Add `Material` wrapper to Text hero (required for text heroes)
- Set `Material.color: Colors.transparent` to avoid background color flash
- Added theme-aware styling for consistency

**Lines to Modify:** Approximately lines 206-235
**Lines Added:** ~15
**Lines Removed:** ~5
**Net Change:** +10 lines

---

### Phase 1 Verification Criteria

**Manual Testing:**
1. Launch app in development mode
2. Navigate to Library tab
3. Tap on Artists section
4. Tap any artist from the list
5. **Expected:** Artist image morphs from small circle to large circle
6. **Expected:** Artist name morphs and transitions smoothly
7. **Expected:** No cross-fade or jarring transition
8. Navigate back (swipe or back button)
9. **Expected:** Reverse hero animation plays smoothly

**Visual Checks:**
- [ ] Artist image scales smoothly from CircleAvatar to large ClipOval
- [ ] Artist name transitions without flickering
- [ ] Background content fades appropriately
- [ ] No visual artifacts or z-ordering issues
- [ ] Animation timing feels natural (~300ms)

**Code Verification:**
```bash
# Search for hero tags in library screen
grep -n "HeroTags.artist" /home/home-server/Ensemble/lib/screens/new_library_screen.dart

# Should show hero tags with '_library' suffix matching ArtistDetailsScreen
```

**Rollback Point:**
If hero animation still doesn't work, check:
1. Hero tags match exactly between screens
2. Material wrapper is present on Text hero
3. No duplicate hero tags elsewhere
4. FadeSlidePageRoute isn't interfering (consider switching to MaterialPageRoute)

---

## Phase 2: Remove AlbumDetailsScreen Bottom Nav

**Goal:** Eliminate duplicate bottom navigation bar from album detail screens to prevent animation during transitions

**Problem:** AlbumDetailsScreen creates its own BottomNavigationBar with non-adaptive colors, causing two navs to be visible during page transitions (one fading out, one sliding in).

### Implementation Steps

#### Step 2.1: Locate Bottom Nav Property
**File:** `/home/home-server/Ensemble/lib/screens/album_details_screen.dart`
**Location:** Lines 341-388 (approximately)

**Action:** Find the `bottomNavigationBar` property in the Scaffold widget.

**Current Structure:**
```dart
return Scaffold(
  backgroundColor: colorScheme.background,
  bottomNavigationBar: Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      // ... shadow, border, etc.
    ),
    child: BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) => Navigator.of(context).popUntil((route) => route.isFirst),
      selectedItemColor: colorScheme.primary,
      // ... 40+ lines of navigation config
    ),
  ),
  body: CustomScrollView(
    // ... existing body
  ),
);
```

---

#### Step 2.2: Remove Bottom Nav Property
**File:** `/home/home-server/Ensemble/lib/screens/album_details_screen.dart`
**Location:** Lines 341-388

**Action:** Delete the entire `bottomNavigationBar` property and its associated Container/BottomNavigationBar widget tree.

**New Structure:**
```dart
return Scaffold(
  backgroundColor: colorScheme.background,
  // bottomNavigationBar: DELETED
  body: CustomScrollView(
    // ... existing body
  ),
);
```

**Lines to Remove:** ~48 lines
**Lines Added:** 0
**Net Change:** -48 lines

---

#### Step 2.3: Adjust Bottom Padding (Optional)
**File:** `/home/home-server/Ensemble/lib/screens/album_details_screen.dart`
**Location:** Line 733 (approximately, within CustomScrollView slivers)

**Current Code:**
```dart
SliverToBoxAdapter(
  child: SizedBox(height: 140), // Space for mini player + bottom nav
),
```

**Recommended Code:**
```dart
SliverToBoxAdapter(
  child: SizedBox(height: 80), // Space for mini player only
),
```

**Rationale:** With bottom nav removed, only need space for the mini player (64px height + 8px margin + 8px buffer = ~80px).

**Note:** This adjustment is OPTIONAL. Test first without changing. If content is cut off by mini player, then reduce padding.

---

### Phase 2 Verification Criteria

**Manual Testing:**
1. Launch app in development mode
2. From Home screen, tap any album
3. **Expected:** Bottom navigation bar does NOT animate during transition
4. **Expected:** Only HomeScreen's bottom nav remains visible
5. **Expected:** Mini player remains visible above bottom nav
6. Scroll through album tracks
7. **Expected:** Content scrolls smoothly without being cut off by mini player
8. Navigate back to Home
9. **Expected:** Smooth transition without nav animation

**Visual Checks:**
- [ ] No bottom navigation bar visible in AlbumDetailsScreen
- [ ] HomeScreen bottom nav remains fixed during transition
- [ ] Mini player positioned correctly above HomeScreen bottom nav
- [ ] Last track in album is not obscured by mini player
- [ ] AppBar back button is clearly visible and functional
- [ ] Album art, title, and metadata display correctly

**Comparison Test:**
- Before: Two bottom navs visible during transition (color/position shift)
- After: One fixed bottom nav, no movement or color change

**Code Verification:**
```bash
# Verify bottomNavigationBar property is removed
grep -n "bottomNavigationBar" /home/home-server/Ensemble/lib/screens/album_details_screen.dart

# Should return NO results (or only results in comments)
```

**Rollback Point:**
If users strongly prefer having bottom nav in detail screens:
1. Revert this change
2. Proceed to Phase 2 Alternative (add adaptive colors to detail nav)
3. Accept that some cross-fade animation will occur

---

## Phase 3: Remove ArtistDetailsScreen Bottom Nav

**Goal:** Eliminate duplicate bottom navigation bar from artist detail screens for consistency with album details

**Problem:** Same as Phase 2 - ArtistDetailsScreen creates its own BottomNavigationBar causing animation during transitions.

### Implementation Steps

#### Step 3.1: Locate Bottom Nav Property
**File:** `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart`
**Location:** Lines 162-209 (approximately)

**Action:** Find the `bottomNavigationBar` property in the Scaffold widget.

**Current Structure:**
```dart
return Scaffold(
  backgroundColor: colorScheme.background,
  bottomNavigationBar: Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      // ... shadow, border, etc.
    ),
    child: BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) => Navigator.of(context).popUntil((route) => route.isFirst),
      selectedItemColor: colorScheme.primary,
      // ... navigation config
    ),
  ),
  body: CustomScrollView(
    // ... existing body
  ),
);
```

---

#### Step 3.2: Remove Bottom Nav Property
**File:** `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart`
**Location:** Lines 162-209

**Action:** Delete the entire `bottomNavigationBar` property and its associated Container/BottomNavigationBar widget tree.

**New Structure:**
```dart
return Scaffold(
  backgroundColor: colorScheme.background,
  // bottomNavigationBar: DELETED
  body: CustomScrollView(
    // ... existing body
  ),
);
```

**Lines to Remove:** ~48 lines
**Lines Added:** 0
**Net Change:** -48 lines

---

#### Step 3.3: Adjust Bottom Padding (Optional)
**File:** `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart`
**Location:** Line 386 (approximately, within CustomScrollView slivers)

**Current Code:**
```dart
SliverToBoxAdapter(
  child: SizedBox(height: 140), // Space for mini player + bottom nav
),
```

**Recommended Code:**
```dart
SliverToBoxAdapter(
  child: SizedBox(height: 80), // Space for mini player only
),
```

**Rationale:** Same as Phase 2 - only need space for mini player without bottom nav.

**Note:** This is OPTIONAL. Test without changing first.

---

### Phase 3 Verification Criteria

**Manual Testing:**
1. Launch app in development mode
2. Test all artist navigation paths:
   - **Path A:** Home → Artist row → Artist details
   - **Path B:** Library → Artists → Artist details (should have hero animation from Phase 1)
   - **Path C:** Album details → Artist name → Artist details
3. For each path:
   - **Expected:** Bottom nav does NOT animate
   - **Expected:** Only HomeScreen bottom nav visible
   - **Expected:** Mini player remains above nav
4. Scroll through artist albums
5. **Expected:** Content scrolls smoothly
6. Navigate back from each path
7. **Expected:** Smooth transitions

**Visual Checks:**
- [ ] No bottom navigation bar in ArtistDetailsScreen
- [ ] HomeScreen bottom nav remains fixed during all transitions
- [ ] Mini player positioned correctly
- [ ] Last album in artist's list is not obscured
- [ ] AppBar back button clearly visible
- [ ] Artist image, name, and bio display correctly
- [ ] Hero animation works from Library (Phase 1 integration check)

**Cross-Screen Consistency Check:**
- [ ] AlbumDetailsScreen and ArtistDetailsScreen have consistent navigation UX
- [ ] Both screens use only back button navigation
- [ ] Both screens have same bottom padding for mini player

**Code Verification:**
```bash
# Verify bottomNavigationBar property is removed
grep -n "bottomNavigationBar" /home/home-server/Ensemble/lib/screens/artist_details_screen.dart

# Should return NO results (or only in comments)
```

**Rollback Point:**
If issues arise:
1. Verify Phase 2 (album details) works correctly first
2. If only artist details is problematic, check for widget-specific issues
3. Can revert this phase independently of Phase 2

---

## Phase 4: Integration Testing & Validation

**Goal:** Comprehensive testing to ensure all goals are achieved and no regressions introduced

**This phase has no code changes** - only thorough testing of the integrated system.

### Testing Matrix

#### Test 4.1: Fixed Bottom Navigation
**Objective:** Verify bottom nav never animates during page transitions

| Navigation Path | Test Action | Expected Result | Status |
|----------------|-------------|-----------------|--------|
| Home → Album | Tap album card | Bottom nav remains fixed, no color/position change | [ ] |
| Home → Artist | Tap artist card | Bottom nav remains fixed | [ ] |
| Library Albums → Album | Tap album | Bottom nav remains fixed | [ ] |
| Library Artists → Artist | Tap artist | Bottom nav remains fixed | [ ] |
| Album → Artist | Tap artist name | Bottom nav remains fixed | [ ] |
| Artist → Album | Tap album card | Bottom nav remains fixed | [ ] |
| Detail → Back | Navigate back | Bottom nav remains fixed | [ ] |
| Search → Album | Tap search result | Bottom nav remains fixed | [ ] |

**Pass Criteria:** ALL paths show zero bottom nav movement during transitions.

---

#### Test 4.2: Hero Animations
**Objective:** Verify all hero animations morph smoothly

| Animation | Test Action | Expected Behavior | Status |
|-----------|-------------|-------------------|--------|
| Album Cover (Home → Album) | Tap album card | Cover morphs from card to detail header | [ ] |
| Album Title (Home → Album) | Tap album card | Title transitions smoothly | [ ] |
| Artist Name (Home → Album) | Tap album card | Artist name transitions | [ ] |
| Artist Image (Home → Artist) | Tap artist card | Image morphs smoothly | [ ] |
| Artist Name (Home → Artist) | Tap artist card | Name transitions | [ ] |
| Album Cover (Library → Album) | Tap library album | Cover morphs with grid suffix | [ ] |
| Artist Image (Library → Artist) | Tap library artist | Circle morphs to large circle (FIXED IN PHASE 1) | [ ] |
| Artist Name (Library → Artist) | Tap library artist | Name transitions (FIXED IN PHASE 1) | [ ] |
| Album in Artist (Artist → Album) | Tap album in artist screen | Cover morphs with artist_albums suffix | [ ] |

**Pass Criteria:** ALL hero animations show smooth morphing without cross-fade artifacts.

**Special Focus:** Library → Artist animation must work (Phase 1 validation).

---

#### Test 4.3: Mini Player Layering
**Objective:** Verify mini player correctly sits above bottom navigation

| Test Scenario | Test Action | Expected Result | Status |
|--------------|-------------|-----------------|--------|
| Mini player visibility | Play a track | Mini player appears above bottom nav | [ ] |
| Mini player expansion | Tap mini player | Expands over bottom nav (not behind) | [ ] |
| Full expansion | Tap and drag up | Fills entire screen | [ ] |
| Background color morph | Expand player | Background morphs from tinted to dark surface | [ ] |
| Collapse | Tap background or drag down | Collapses back to mini player | [ ] |
| Navigation with player | Navigate between screens | Mini player remains above nav throughout | [ ] |
| Settings screen | Navigate to Settings | Mini player slides down (existing behavior) | [ ] |

**Pass Criteria:** Mini player always positioned above bottom nav with correct z-order.

---

#### Test 4.4: Adaptive Colors
**Objective:** Verify adaptive colors update correctly on bottom nav

| Test Scenario | Test Action | Expected Result | Status |
|--------------|-------------|-----------------|--------|
| Color extraction | Play track with colorful album art | Bottom nav selected color updates to extracted color | [ ] |
| Color brightness | Play track with dark album art | Bottom nav color adjusted for sufficient contrast | [ ] |
| Color persistence | Navigate to detail screen | Bottom nav keeps adaptive color (doesn't reset) | [ ] |
| Color during expansion | Expand mini player | Bottom nav background lerps toward player background | [ ] |
| Adaptive theme toggle OFF | Disable adaptive theme in Settings | Bottom nav uses default theme primary color | [ ] |
| Adaptive theme toggle ON | Enable adaptive theme | Bottom nav uses extracted color | [ ] |
| Multiple track changes | Skip through playlist | Colors update smoothly for each track | [ ] |

**Pass Criteria:** Adaptive colors flow correctly to fixed bottom nav without rebuilding nav structure.

---

#### Test 4.5: Edge Cases & Regressions

| Test Case | Test Action | Expected Result | Status |
|-----------|-------------|-----------------|--------|
| Back button from detail | Press back from album/artist details | Returns to previous screen smoothly | [ ] |
| Deep navigation | Home → Artist → Album → Back → Back | Navigation stack works correctly | [ ] |
| System back gesture | Swipe from edge on album/artist details | Returns to previous screen | [ ] |
| Rapid navigation | Quickly tap multiple cards | No crashes, animations queue properly | [ ] |
| No track playing | Browse without playing | Bottom nav visible, mini player hidden | [ ] |
| First track play | Play first track | Mini player appears smoothly | [ ] |
| Orientation change | Rotate device (if supported) | Layout adjusts correctly | [ ] |
| Tab switching | Switch between Home/Library/Search tabs | Bottom nav highlights update, state preserved | [ ] |

**Pass Criteria:** No regressions in existing functionality.

---

### Performance Testing

#### Performance 4.1: Animation Frame Rate
**Test Setup:**
1. Enable performance overlay: `flutter run --profile`
2. Monitor FPS during transitions

**Measurements:**
- Hero animations: Target 60 FPS (no dropped frames)
- Page transitions: Target 60 FPS
- Mini player expansion: Target 60 FPS
- Color extraction + bottom nav update: < 100ms perceived delay

**Pass Criteria:** No visible jank or stuttering during normal use.

---

#### Performance 4.2: Memory & Build Performance
**Metrics to Monitor:**
- Widget rebuild count during navigation (use DevTools)
- Memory usage (should not increase with removed bottom navs)
- Build times for detail screens (should be slightly faster)

**Expected Improvements:**
- Fewer widgets during page transitions (removed duplicate navs)
- Simpler widget tree in detail screens
- Potentially faster transitions due to less rendering work

---

### Visual Polish Checks

**Detail Screen Polish:**
- [ ] Content spacing looks balanced without bottom nav
- [ ] Mini player doesn't obscure important content
- [ ] Last item in scrollable lists has adequate padding
- [ ] Back button in AppBar is clearly visible on all backgrounds
- [ ] Text readability maintained throughout animations

**Navigation Polish:**
- [ ] Tab selection highlights correctly
- [ ] Tab icons are visible and clear
- [ ] Adaptive colors look good across various album art
- [ ] Color transitions are smooth (no sudden flashes)

**Overall Visual Coherence:**
- [ ] App feels cohesive with fixed bottom nav
- [ ] Detail screens feel like "zooming into" content
- [ ] Navigation pattern is intuitive (back button vs bottom nav)

---

### Phase 4 Verification Summary

**Must-Pass Criteria:**
1. Bottom navigation NEVER animates during page transitions
2. ALL hero animations morph smoothly (especially Library → Artist)
3. Mini player correctly positioned above bottom nav in all screens
4. Adaptive colors update on fixed bottom nav
5. No regressions in existing functionality

**Performance Criteria:**
1. Animations maintain 60 FPS
2. No memory leaks or excessive rebuilds
3. Color extraction completes quickly

**Rollback Triggers:**
- If bottom nav still animates → Review Phases 2-3 implementation
- If hero animations break → Review Phase 1 and hero tag consistency
- If mini player z-order issues → Check GlobalPlayerOverlay hasn't been affected
- If adaptive colors stop updating → Verify ThemeProvider integration

---

## Phase 5: Polish & Optional Enhancements

**Goal:** Final polish based on testing feedback and optional improvements

**This phase is OPTIONAL** and should only be pursued if issues are discovered in Phase 4 or if enhancements are desired.

### Optional Enhancement 5.1: Reduce Bottom Padding in Detail Screens

**Trigger:** If testing reveals last items in detail screens are too far from mini player.

**Files to Modify:**
- `/home/home-server/Ensemble/lib/screens/album_details_screen.dart` (line ~733)
- `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart` (line ~386)

**Current Padding:** 140px (accommodated mini player + bottom nav)
**New Padding:** 80px (mini player only)

**Implementation:**
```dart
// In both files, find SliverToBoxAdapter with SizedBox at bottom
SliverToBoxAdapter(
  child: SizedBox(height: 80), // Reduced from 140
),
```

**Verification:**
- [ ] Last track in album not obscured by mini player
- [ ] Last album in artist not obscured by mini player
- [ ] Scrolling to bottom feels natural
- [ ] Mini player doesn't overlap content

---

### Optional Enhancement 5.2: Improve Back Button Visibility

**Trigger:** If AppBar back button is hard to see on certain album art backgrounds.

**File to Modify:**
- `/home/home-server/Ensemble/lib/screens/album_details_screen.dart`
- `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart`

**Options:**

**Option A:** Add background scrim to AppBar
```dart
flexibleSpace: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0.5),
        Colors.transparent,
      ],
    ),
  ),
),
```

**Option B:** Use foreground-colored back button
```dart
leading: IconButton(
  icon: Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () => Navigator.pop(context),
),
```

**Option C:** Add subtle shadow to back button
```dart
leading: Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ],
  ),
  child: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
),
```

**Verification:**
- [ ] Back button visible on light album art
- [ ] Back button visible on dark album art
- [ ] Back button visible on colorful album art
- [ ] Doesn't look out of place

---

### Optional Enhancement 5.3: Standardize Page Transition for Library → Artist

**Trigger:** If FadeSlidePageRoute interferes with hero animation or feels inconsistent.

**File to Modify:**
- `/home/home-server/Ensemble/lib/screens/new_library_screen.dart` (line ~227)

**Current Code:**
```dart
Navigator.push(
  context,
  FadeSlidePageRoute(
    child: ArtistDetailsScreen(
      artist: artist,
      heroTagSuffix: 'library',
    ),
  ),
);
```

**Alternative Code:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ArtistDetailsScreen(
      artist: artist,
      heroTagSuffix: 'library',
    ),
  ),
);
```

**Rationale:**
- MaterialPageRoute is Flutter's standard transition
- Works seamlessly with hero animations
- Consistent with other navigation paths in the app
- FadeSlidePageRoute may add unnecessary fade that conflicts with heroes

**Verification:**
- [ ] Library → Artist transition feels smooth
- [ ] Hero animation plays correctly
- [ ] Transition consistent with Library → Album
- [ ] Doesn't feel jarring compared to other transitions

**Decision Point:** Test both transitions and choose based on feel. FadeSlidePageRoute can be kept if it enhances UX without breaking heroes.

---

### Optional Enhancement 5.4: Add Empty State Back Navigation Hint

**Trigger:** If users are confused about how to navigate back from detail screens.

**Implementation:** Add subtle hint text near top of detail screen on first visit.

**Files to Modify:**
- `/home/home-server/Ensemble/lib/screens/album_details_screen.dart`
- `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart`

**Example:**
```dart
// Add after hero image/header
SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.all(8.0),
    child: Row(
      children: [
        Icon(Icons.arrow_back, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
        SizedBox(width: 4),
        Text(
          'Swipe or tap back to return',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    ),
  ),
),
```

**Consideration:** May not be necessary. Most users understand back navigation. Only add if user testing reveals confusion.

---

### Optional Enhancement 5.5: Smooth Color Transition Animation

**Trigger:** If adaptive color changes feel too abrupt when track changes.

**File to Modify:**
- `/home/home-server/Ensemble/lib/screens/home_screen.dart`

**Current Implementation:** Uses immediate color from ThemeProvider.

**Enhanced Implementation:** Animate color changes over 300ms.

```dart
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  Color? _previousColor;

  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentColor = themeProvider.adaptivePrimaryColor;

    if (_previousColor != currentColor) {
      _previousColor = currentColor;
      _colorAnimationController.forward(from: 0.0);
    }

    final animatedColor = ColorTween(
      begin: _previousColor,
      end: currentColor,
    ).animate(_colorAnimationController);

    // Use animatedColor.value in bottom nav
  }
}
```

**Consideration:** Current implementation may already feel smooth due to ThemeProvider rebuild. Only implement if color changes feel jarring.

---

## Phase Checkpoints & Rollback Strategy

### Checkpoint 1: After Phase 1
**Validation:** Library → Artist hero animation works.

**Go/No-Go Decision:**
- **GO:** Hero animation morphs smoothly → Proceed to Phase 2
- **NO-GO:** Hero animation still broken → Debug Phase 1
  - Check hero tags match exactly
  - Verify Material wrapper on Text hero
  - Test with MaterialPageRoute instead of FadeSlidePageRoute
  - Review ArtistDetailsScreen hero tag construction

**Rollback:** Simple - remove Hero widgets from Library screen, revert to original ListTile.

---

### Checkpoint 2: After Phase 2
**Validation:** Bottom nav doesn't animate when navigating to album details.

**Go/No-Go Decision:**
- **GO:** Bottom nav stays fixed → Proceed to Phase 3
- **NO-GO:** Bottom nav still animates → Debug Phase 2
  - Verify bottomNavigationBar property completely removed
  - Check no other code is creating bottom nav in album details
  - Verify only one Scaffold in widget tree

**Rollback:** Restore bottomNavigationBar property from analysis document code samples.

---

### Checkpoint 3: After Phase 3
**Validation:** Bottom nav doesn't animate when navigating to artist details.

**Go/No-Go Decision:**
- **GO:** Bottom nav stays fixed for artists → Proceed to Phase 4
- **NO-GO:** Bottom nav still animates → Debug Phase 3
  - Same checks as Phase 2 but for artist details
  - Verify consistency with Phase 2 implementation

**Rollback:** Restore bottomNavigationBar property from analysis document.

---

### Checkpoint 4: After Phase 4
**Validation:** All integration tests pass, no regressions.

**Go/No-Go Decision:**
- **GO:** All goals achieved → Merge to main or proceed to Phase 5 for polish
- **NO-GO:** Regressions or failed tests → Debug specific failures
  - Review Phase 4 testing matrix for specific failure points
  - Address issues individually
  - Re-run integration tests

**Rollback:** If fundamental issues, can revert all phases and reconsider approach.

---

### Checkpoint 5: After Phase 5 (Optional)
**Validation:** Polish improvements enhance UX without introducing issues.

**Decision:** Each enhancement can be evaluated independently. Keep what works, discard what doesn't.

---

## Risk Mitigation

### Risk 1: Hero Animation Doesn't Work After Phase 1
**Likelihood:** Low
**Impact:** Medium (goal not achieved)

**Mitigation:**
- Hero tags are well-documented in analysis
- ArtistCard already works as reference implementation
- Can test incrementally (add image hero first, then name hero)

**Contingency:**
- Switch FadeSlidePageRoute to MaterialPageRoute
- Verify no conflicting hero tags elsewhere
- Consult Flutter hero animation documentation
- Worst case: Accept that Library → Artist uses fade transition (not ideal but not critical)

---

### Risk 2: Users Prefer Bottom Nav in Detail Screens
**Likelihood:** Medium
**Impact:** Low (can easily implement alternative)

**Mitigation:**
- Removing bottom nav is standard pattern in music apps
- User testing after implementation can validate
- Easy to explain: "Tap back to return to main navigation"

**Contingency:**
- Implement Phase 2 Alternative (add adaptive colors to detail navs)
- Accept some cross-fade animation during transitions
- Navigation still functional, just less "fixed" feeling

---

### Risk 3: Mini Player Obscures Content
**Likelihood:** Low
**Impact:** Low (easy to fix with padding adjustment)

**Mitigation:**
- Analysis shows adequate padding already exists (140px)
- Reducing to 80px still leaves buffer space
- Can fine-tune in Phase 5

**Contingency:**
- Adjust SizedBox height in detail screens
- Test with various screen sizes
- May need different padding for phones vs tablets

---

### Risk 4: Performance Regression
**Likelihood:** Very Low
**Impact:** Medium

**Mitigation:**
- Changes remove code (fewer widgets = better performance)
- No new animations or complex logic added
- Profile mode testing in Phase 4 catches issues

**Contingency:**
- Profile with Flutter DevTools
- Identify specific bottlenecks
- Optimize or rollback specific changes

---

### Risk 5: Adaptive Colors Stop Updating
**Likelihood:** Very Low
**Impact:** High (breaks key feature)

**Mitigation:**
- Not modifying ThemeProvider or color extraction logic
- Only removing widgets, not changing state management
- HomeScreen bottom nav already works correctly as reference

**Contingency:**
- Verify ThemeProvider still notifies listeners
- Check context.watch still triggers rebuilds
- Review if any removed code was inadvertently handling color updates (unlikely)
- If broken, revert and investigate root cause

---

### Risk 6: Breaking Change to Flutter APIs
**Likelihood:** Very Low
**Impact:** High

**Mitigation:**
- Using stable Flutter APIs (Hero, Navigator, Scaffold)
- No deprecated API usage
- Code follows Flutter best practices

**Contingency:**
- Check Flutter version compatibility
- Review Flutter release notes for breaking changes
- Update dependencies if needed

---

## Questions Requiring User Input

### Question 1: Bottom Nav Requirement ⚠️ CRITICAL
**Question:** Is it important for users to be able to switch tabs directly from album/artist detail screens using the bottom navigation bar?

**Options:**
- **A) No - Back button navigation is fine** (Recommended - enables fixed bottom nav)
- **B) Yes - Bottom nav must be everywhere** (Requires Phase 2 Alternative approach)

**Impact:** Determines if we proceed with Phase 2-3 as planned or pivot to alternative approach.

**Recommendation:** Option A - Standard pattern in music apps, simpler implementation, achieves all goals.

---

### Question 2: Page Transition for Library → Artist
**Question:** Should Library → Artist use the custom FadeSlidePageRoute or standard MaterialPageRoute?

**Options:**
- **A) Keep FadeSlidePageRoute** (Current, slightly custom feel)
- **B) Switch to MaterialPageRoute** (Consistent with rest of app, may improve hero animation)

**Impact:** Minor - affects feel of one transition. Can be changed in Phase 5 if desired.

**Recommendation:** Test both after Phase 1 implementation and choose based on feel.

---

### Question 3: Bottom Padding Adjustment
**Question:** Should we reduce bottom padding in detail screens from 140px to 80px?

**Options:**
- **A) Keep 140px** (More buffer space, very safe)
- **B) Reduce to 80px** (Tighter spacing, more content visible)
- **C) Test both and decide** (Recommended)

**Impact:** Minor - affects how much content is visible before scrolling.

**Recommendation:** Option C - Test with 140px first (no change), then try 80px in Phase 5 if needed.

---

### Question 4: Mini Player Behavior in Detail Screens
**Question:** Should the mini player be visible in album/artist detail screens, or should it slide down like on the Settings screen?

**Options:**
- **A) Keep visible** (Current behavior, recommended)
- **B) Hide in detail screens** (Less clutter, but loses playback controls)

**Impact:** Medium - affects user ability to control playback from detail screens.

**Recommendation:** Option A - Keep visible. Users expect playback controls to be accessible everywhere.

**Note:** If choosing Option B, need to add logic in GlobalPlayerOverlay to detect detail screens and hide player.

---

### Question 5: Performance Targets
**Question:** What are the acceptable performance thresholds for this app?

**Targets to Confirm:**
- 60 FPS during animations on development devices
- < 100ms delay for adaptive color updates
- No memory leaks or excessive rebuilds

**Impact:** Determines pass/fail for Phase 4 performance testing.

**Recommendation:** Use targets above as baseline. Adjust if app needs to run on very low-end devices.

---

## Estimated Complexity Per Phase

| Phase | Description | Complexity | Time Estimate | Risk Level |
|-------|-------------|------------|---------------|------------|
| Phase 1 | Fix Library → Artist hero animation | LOW | 20 minutes | LOW |
| Phase 2 | Remove AlbumDetailsScreen bottom nav | VERY LOW | 10 minutes | LOW |
| Phase 3 | Remove ArtistDetailsScreen bottom nav | VERY LOW | 10 minutes | LOW |
| Phase 4 | Integration testing & validation | MEDIUM | 45 minutes | LOW |
| Phase 5 | Optional polish enhancements | LOW-MEDIUM | 30 minutes | VERY LOW |
| **TOTAL** | **All phases** | **LOW** | **~2 hours** | **LOW** |

### Complexity Factors

**Low Complexity Drivers:**
- Only removing code in Phases 2-3 (minimal risk)
- Hero animation fix follows existing pattern (reference implementation available)
- No new dependencies or architecture changes
- Changes are isolated to 3 files
- Easy rollback at any checkpoint

**Medium Complexity Elements:**
- Hero animation debugging if Phase 1 doesn't work immediately
- Comprehensive testing in Phase 4 (time-consuming but straightforward)
- Coordination of hero tags between screens

**Why This Is Low-Risk Overall:**
- Analysis phase thoroughly identified root causes
- Solution is subtractive (removing problematic code), not additive
- Core systems (ThemeProvider, GlobalPlayerOverlay, hero animations) already work
- Standard Flutter patterns used throughout

---

## Dependencies & Requirements

### Flutter SDK
**Current Version:** (Check with `flutter --version`)
**Required:** Flutter 3.x or higher
**APIs Used:** Navigator, Hero, Scaffold, MaterialPageRoute, Provider

**No version changes required.**

---

### Dart Packages

**Current Dependencies (No Changes Required):**
- `provider: ^6.1.1` - State management (used by ThemeProvider)
- `palette_generator: ^0.3.3+3` - Color extraction (used for adaptive colors)
- `dynamic_color: 1.6.8` - Material You colors (optional feature)

**No new dependencies needed.**

**Dependencies NOT needed:**
- ❌ `go_router` - Not implementing shell route approach
- ❌ Animation packages - Using Flutter's built-in animation APIs

---

### Development Tools

**Required:**
- Flutter DevTools (for Phase 4 performance testing)
- Hot reload capability (for rapid iteration)
- Physical device or emulator (for testing animations)

**Recommended:**
- Android Studio / VS Code with Flutter extensions
- Git for version control
- Performance overlay enabled during testing

---

### Project Files

**Files to Modify:**
1. `/home/home-server/Ensemble/lib/screens/new_library_screen.dart` (Phase 1)
2. `/home/home-server/Ensemble/lib/screens/album_details_screen.dart` (Phase 2)
3. `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart` (Phase 3)

**Files Referenced (No Changes):**
- `/home/home-server/Ensemble/lib/constants/hero_tags.dart` - Hero tag constants
- `/home/home-server/Ensemble/lib/widgets/global_player_overlay.dart` - Player overlay
- `/home/home-server/Ensemble/lib/widgets/expandable_player.dart` - Mini player
- `/home/home-server/Ensemble/lib/theme/theme_provider.dart` - Adaptive colors
- `/home/home-server/Ensemble/lib/screens/home_screen.dart` - Reference implementation

**Files to Create:**
- None

**Files to Delete:**
- None

---

## Implementation Workflow

### Pre-Implementation

1. **Review Analysis:** Ensure all team members understand the root causes and chosen approach
2. **User Decision:** Get answer to Question 1 (bottom nav requirement) before proceeding
3. **Backup Code:** Commit or stash any uncommitted changes
4. **Create Branch:** Ensure working on `feature/fixed-bottom-nav-fluid-animations`
5. **Environment Check:** Verify Flutter hot reload works, no existing errors

---

### Implementation Sequence

**Day 1: Core Implementation (45 minutes)**
1. Phase 1: Fix hero animation (20 min)
   - Modify new_library_screen.dart
   - Test Library → Artist transition
   - Checkpoint 1: Verify hero animation works
2. Phase 2: Remove album bottom nav (10 min)
   - Modify album_details_screen.dart
   - Test Home/Library → Album transition
   - Checkpoint 2: Verify no nav animation
3. Phase 3: Remove artist bottom nav (10 min)
   - Modify artist_details_screen.dart
   - Test Home/Library → Artist transition
   - Checkpoint 3: Verify no nav animation
4. Quick smoke test (5 min)
   - Verify all navigation paths work
   - Verify no crashes

---

**Day 1: Testing (45 minutes)**
5. Phase 4: Integration testing
   - Test 4.1: Fixed bottom nav (15 min)
   - Test 4.2: Hero animations (15 min)
   - Test 4.3: Mini player layering (10 min)
   - Test 4.4: Adaptive colors (5 min)
   - Checkpoint 4: All tests pass

---

**Day 2: Polish (Optional, 30 minutes)**
6. Phase 5: Polish based on Phase 4 findings
   - Apply any needed enhancements
   - Re-test affected areas
   - Checkpoint 5: Polish complete

---

### Post-Implementation

1. **Final Testing:** Complete test matrix from Phase 4
2. **Performance Profile:** Run in profile mode, verify 60 FPS
3. **User Testing:** Get feedback on navigation UX
4. **Documentation:** Update any user-facing docs if needed
5. **Code Review:** Have another developer review changes
6. **Merge:** Merge to main branch after approval

---

## Success Criteria Summary

### Primary Goals (Must Achieve)

✅ **Fixed Bottom Navigation**
- Bottom nav remains stationary during all page transitions
- No color changes or position shifts
- Verified across all navigation paths

✅ **Adaptive Colors Update**
- Bottom nav selected color updates when track changes
- Colors extracted from album art flow to fixed nav
- Smooth color transitions without rebuilding nav structure

✅ **Mini Player Over Bottom Nav**
- Mini player positioned above bottom nav in all screens
- Expands over nav, not behind it
- Z-order correct throughout expansion animation

✅ **Fluid Hero Animations**
- Album cover, title, artist name morph smoothly
- Artist image and name morph smoothly
- Library → Artist hero animation FIXED
- All navigation paths show smooth transitions

✅ **No Regressions**
- All existing functionality works
- No new bugs introduced
- Performance maintained or improved

---

### Secondary Goals (Nice to Have)

⭐ **Visual Polish**
- Detail screens look balanced without bottom nav
- Back button clearly visible on all backgrounds
- Content spacing optimized for mini player only

⭐ **Performance Improvements**
- Faster page transitions (fewer widgets to render)
- Reduced widget tree complexity
- 60 FPS maintained throughout

⭐ **Code Quality**
- Cleaner code (removed duplication)
- Consistent navigation pattern
- Well-documented changes

---

## Completion Checklist

### Phase 1: Library Hero Animation
- [ ] Hero widgets added to Library artist tiles
- [ ] Hero tags match ArtistDetailsScreen expectations
- [ ] Library → Artist transition shows smooth hero animation
- [ ] Checkpoint 1 passed

### Phase 2: Album Bottom Nav
- [ ] bottomNavigationBar removed from AlbumDetailsScreen
- [ ] Home → Album transition shows fixed bottom nav
- [ ] Library → Album transition shows fixed bottom nav
- [ ] Checkpoint 2 passed

### Phase 3: Artist Bottom Nav
- [ ] bottomNavigationBar removed from ArtistDetailsScreen
- [ ] Home → Artist transition shows fixed bottom nav
- [ ] Library → Artist transition shows fixed bottom nav
- [ ] Checkpoint 3 passed

### Phase 4: Integration Testing
- [ ] Fixed bottom nav test matrix complete (8/8 paths)
- [ ] Hero animation test matrix complete (9/9 animations)
- [ ] Mini player layering test complete (7/7 scenarios)
- [ ] Adaptive colors test complete (7/7 scenarios)
- [ ] Edge cases test complete (8/8 cases)
- [ ] Performance testing complete (60 FPS target met)
- [ ] Checkpoint 4 passed

### Phase 5: Optional Polish
- [ ] Bottom padding adjusted if needed
- [ ] Back button visibility improved if needed
- [ ] Page transition standardized if needed
- [ ] Any other polish items addressed
- [ ] Checkpoint 5 passed

### Final Validation
- [ ] All primary goals achieved
- [ ] No regressions introduced
- [ ] Code reviewed
- [ ] User testing feedback incorporated
- [ ] Ready to merge

---

## Notes & Considerations

### Design Decisions

**Why Remove Bottom Nav Instead of Fixing It?**
- Simpler implementation (remove code vs add complexity)
- Standard pattern in music streaming apps
- Completely eliminates animation issue
- Reduces widget tree complexity
- Focuses user attention on detail content

**Why Not Use go_router?**
- Overkill for this relatively simple app
- High migration effort for minimal benefit
- Current Navigator works well
- No need for deep linking or complex routing

**Why Fix Hero Animation First?**
- Independent of bottom nav changes
- Quick win to validate approach
- Tests hero animation system works
- Low risk, easy to verify

---

### Future Considerations

**If App Grows More Complex:**
- Consider go_router for advanced routing needs
- May want nested navigators for tab-specific stacks
- Could implement custom page transitions per route
- Might need more sophisticated state management

**If Performance Becomes Issue:**
- Profile color extraction (may need caching)
- Consider virtualized lists for large libraries
- May need to optimize hero animation flightShuttleBuilder
- Could reduce animation durations on low-end devices

**If Users Request Features:**
- Could add gesture to swipe between tabs from detail screens
- Could implement custom back button with more visibility
- Could add breadcrumb navigation
- Could implement "recently viewed" navigation

---

### Maintenance Notes

**Code Locations to Remember:**
- Hero tags defined in: `lib/constants/hero_tags.dart`
- Bottom nav adaptive colors in: `lib/screens/home_screen.dart`
- Color extraction in: `lib/widgets/expandable_player.dart`
- Theme management in: `lib/theme/theme_provider.dart`
- Player overlay in: `lib/widgets/global_player_overlay.dart`

**If Bottom Nav Needs to Be Added Back:**
- Reference analysis document for original code
- Can copy from HomeScreen implementation
- Remember to use adaptive colors via ThemeProvider
- Consider using ValueListenableBuilder for player expansion lerp

**If Hero Animations Break:**
- Verify hero tags match exactly between screens
- Check for duplicate hero tags
- Ensure Material wrapper on Text heroes
- Test with standard MaterialPageRoute first

---

## Appendix: Alternative Approach (If Needed)

### Phase 2 Alternative: Keep Bottom Nav with Adaptive Colors

**If user requires bottom nav in detail screens**, implement this instead of removing:

#### Change 1: AlbumDetailsScreen Adaptive Colors
**File:** `/home/home-server/Ensemble/lib/screens/album_details_screen.dart`
**Location:** Build method and bottomNavigationBar

```dart
@override
Widget build(BuildContext context) {
  final themeProvider = context.watch<ThemeProvider>();
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Calculate adaptive color
  var navSelectedColor = themeProvider.adaptiveTheme
      ? themeProvider.adaptivePrimaryColor
      : colorScheme.primary;

  // Ensure contrast (same logic as HomeScreen)
  if (isDark && navSelectedColor.computeLuminance() < 0.2) {
    final hsl = HSLColor.fromColor(navSelectedColor);
    navSelectedColor = hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 0.8)).toColor();
  }

  return Scaffold(
    backgroundColor: colorScheme.background,
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        selectedItemColor: navSelectedColor, // Use adaptive color
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    ),
    body: CustomScrollView(
      // ... existing body
    ),
  );
}
```

#### Change 2: ArtistDetailsScreen Adaptive Colors
**File:** `/home/home-server/Ensemble/lib/screens/artist_details_screen.dart`

Same changes as above - use `themeProvider.adaptivePrimaryColor` for selectedItemColor.

#### Testing Alternative Approach
- [ ] Detail screen nav colors match HomeScreen nav colors
- [ ] Colors update when track changes
- [ ] Cross-fade animation is less jarring (same color transition)
- [ ] Bottom nav still animates (position/opacity) but feels better

**Note:** This is a fallback. Recommended approach is still to remove detail screen navs entirely.

---

## Document Version Control

**Version:** 1.0
**Date:** December 4, 2025
**Status:** Ready for Implementation
**Approved By:** [Pending User Approval]

**Revision History:**
- v1.0 (2025-12-04): Initial plan created based on analysis document

**Next Review:** After Phase 4 completion to assess if Phase 5 needed

---

## Contact & Questions

**For Implementation Questions:**
- Review analysis document: `/home/home-server/Ensemble/docs/analysis/ensemble-navigation-animation-analysis.md`
- Check Flutter hero animation docs: https://docs.flutter.dev/development/ui/animations/hero-animations
- Reference HomeScreen implementation for adaptive color pattern

**For Testing Questions:**
- Review Phase 4 testing matrix
- Use Flutter DevTools for performance profiling
- Enable debug mode flags for animation inspection

**For Architectural Questions:**
- Review "Solution Options" section in analysis document
- Consider trade-offs documented in each option
- Consult team if pivoting from chosen approach

---

**END OF IMPLEMENTATION PLAN**
