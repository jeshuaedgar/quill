# Phase 3 — Polish: Detailed Plan

## Current State

| Item | Status | Details |
|------|--------|---------|
| Widgets (all sizes) | **Done** | Small, medium, large, lock screen (rectangular + circular) all in `QuillWidget.swift`. Live Activities in `QuillLiveActivityViews.swift`. |
| Siri / App Intents | **Done** | `AddReminderIntent`, `ShowRemindersIntent`, `QuillShortcutsProvider` all wired up. |
| Animations & haptics | **Done** | `AnimatedCheckbox` (spring + scale), `HapticManager` (impact/notification/selection), card appear animations. |
| Themes & icons | **Done** | 8 accent colors + light/dark/system via `ThemeManager`. 4 app icon variants (default, monochrome, gradient, outline) with picker in Settings. |
| Settings & onboarding | **Done** | 4-page onboarding flow, full settings screen with appearance, defaults, location, intelligence, data, notifications, about, debug sections. |

**Phase 3 is 100% complete.** All work items done.

---

## Item 1: Large Widget

### What
Add `.systemLarge` family to `QuillWidget.swift` showing today's active reminders as a scrollable list plus a stats header row (total active, overdue count, urgent count).

### Current code state
- `QuillEntry` already carries `reminders: [WidgetReminder]` and `totalCount: Int`
- `QuillWidgetEntryView` routes by `widgetFamily` but only handles `.systemSmall` and `.systemMedium`
- `QuillWidget.supportedFamilies` is `[.systemSmall, .systemMedium]`
- `WidgetReminder` has `title`, `dueDate`, `priority`, `isOverdue`

### Changes required

**File: `QuillWidget/QuillWidget.swift`**

1. Extend `QuillEntry` to add `overdueCount: Int` and `urgentCount: Int` computed from `reminders` (or add them as stored properties fetched in `QuillTimelineProvider.fetchEntry()`).
2. Create `QuillWidgetLargeView(entry:)`:
   - Header: "Quill" icon + title, today's date, stat badges in an HStack (total / overdue / urgent) using `StatBadge` mini component.
   - Body: `ForEach(entry.reminders.prefix(8))` showing each reminder with: priority circle indicator, title (2-line limit), relative date, overdue highlight in red.
   - Footer: if `entry.reminders.count > 8`, show "+N more" text.
   - Empty state: "All clear! Enjoy your day" centered message.
3. Update `QuillWidgetEntryView.body` to add `.systemLarge` case.
4. Update `QuillWidget.supportedFamilies` to include `.systemLarge`.
5. Add `#Preview(as: .systemLarge)` block.

### Acceptance criteria
- Large widget shows up to 8 reminders with stats header.
- Tapping opens the app (deep link to home view).
- Empty state displays when no active reminders.
- Previews render correctly in Xcode.

---

## Item 2: Lock Screen Widgets

### What
Two new widget families for the iOS 16+ lock screen:
- `.accessoryRectangular` — shows next upcoming reminder (title + relative date)
- `.accessoryCircular` — shows today's active reminder count as a badge

### Current code state
- No lock screen widget views exist.
- WidgetKit lock screen widgets require `AccessoryWidgetGroup` or similar SF Symbol styling.
- The existing `QuillEntry` data is sufficient — no new data fetching needed.

### Changes required

**File: `QuillWidget/QuillWidget.swift`** (or new file `QuillWidget/LockScreenWidgets.swift` — decide based on file length; keep in one file if < 400 lines)

1. Create `QuillWidgetRectangularView(entry:)`:
   - `VStack(alignment: .leading)` with SF Symbol icon, reminder title (1 line), relative date below.
   - Use `.widgetURL(URL(string: "quill://reminder/next"))` for deep linking.
   - Empty state: "No upcoming reminders" text.

2. Create `QuillWidgetCircularView(entry:)`:
   - `ZStack` with `AccessoryWidgetBackground()`, centered large number (`entry.totalCount`), "tasks" label below.
   - Use `.widgetURL(URL(string: "quill://reminders"))` for deep linking.

3. Add `.accessoryRectangular` and `.accessoryCircular` to the existing `QuillWidget`'s `supportedFamilies` and handle them in the entry view switch.

4. Update `QuillWidgetEntryView.body` with new cases.

5. Add lock screen previews.

### Acceptance criteria
- Rectangular widget shows next reminder with title and date.
- Circular widget shows count badge.
- Both use appropriate lock screen styling (no container background).
- Previews render.

---

## Item 3: Custom App Icons

### What
3–4 alternate app icon variants (monochrome, gradient, outlined, etc.) that users can select from Settings. Icons displayed in a grid picker.

### Current code state
- `ThemeManager` has `appIconName: String` property persisted to UserDefaults.
- `SettingsView` does not expose an icon picker — `appIconName` is unused in the UI.
- `Assets.xcassets` has only `AppIcon.appiconset` with the default icon.
- No alternate icon assets exist.

### Changes required

**File: `Quill/Resources/Assets.xcassets/`**:

1. Add 3 alternate `AppIcon.appiconset` entries:
   - `AppIcon-Monochrome` — single-color icon (white on black or vice versa)
   - `AppIcon-Gradient` — purple-to-pink gradient variant
   - `AppIcon-Outline` — outlined/line-art variant
   
   Each needs a `Contents.json` with `idiom: "universal"` and proper size entries matching the existing icon's sizes.

   For now, create placeholder asset catalogs with the correct `Contents.json` structure. The actual image files can be added later by a designer.

**File: `Quill/Helpers/ThemeManager.swift`**:

2. Add an `AppIcon` enum:
   ```swift
   enum AppIcon: String, CaseIterable, Identifiable {
       case primary = "AppIcon"
       case monochrome = "AppIcon-Monochrome"
       case gradient = "AppIcon-Gradient"
       case outline = "AppIcon-Outline"
       
       var id: String { rawValue }
       var label: String { ... }
       var preview: String { ... } // SF Symbol for the picker preview
   }
   ```

3. Add `setAppIcon(_ icon: AppIcon)` method:
   - Calls `UIApplication.shared.setAlternateIconName(icon == .primary ? nil : icon.rawValue)`
   - Updates `appIconName` property.

**File: `Quill/Views/Settings/SettingsView.swift`**:

4. Add "App Icon" section to the Appearance section:
   - LazyVGrid with 4 icon buttons (2×2 grid).
   - Each button shows a rounded rectangle with the SF Symbol preview, label, and checkmark if selected.
   - Tapping calls `themeManager.setAppIcon(...)`.
   - Include haptic feedback on selection.

### Acceptance criteria
- 4 icon options visible in Settings → Appearance.
- Selecting an icon changes the home screen icon.
- Selection persists across app launches.
- Placeholder asset catalogs exist with correct structure (actual PNGs can come later).

---

## Item 4: Live Activities

### What
A Live Activity that displays the currently "focused" or in-progress reminder, shown on the Lock Screen and in the Dynamic Island (compact, minimal, expanded views).

### Trigger behavior
- **Manual**: User taps a "Focus" toggle on `ReminderDetailView` to start/stop a Live Activity for that reminder.
- **Auto-start**: When a reminder's `dueDate` is within 30 minutes and it's not yet completed, automatically start a Live Activity. A background check (via `BGAppRefreshTask` or `onChange(of: scenePhase)` foreground check) evaluates this.

### Current code state
- No `ActivityAttributes`, no `DynamicIsland` code.
- `Reminder` model has no `isFocused` or activity ID fields.
- The app currently has no concept of "focusing on" a specific reminder.

### Changes required

**New file: `QuillWidget/QuillLiveActivity.swift`**

1. Define `QuillActivityAttributes` conforming to `ActivityAttributes`:
   ```swift
   struct QuillActivityAttributes: ActivityAttributes {
       struct ContentState: Codable, Hashable {
           let reminderTitle: String
           let dueDate: Date?
           let priority: Priority
           let isCompleted: Bool
       }
       let reminderID: UUID
   }
   ```

**File: `Quill/Models/Reminder.swift`**:

2. Add `activityID: String?` property to `Reminder` model to track the active Live Activity identifier. Set to `nil` when no activity is active.

**New file: `Quill/Services/LiveActivityManager.swift`**:

3. Create `LiveActivityManager` (singleton, `@Observable`):
   - `startActivity(for reminder: Reminder)` — requests a `QuillActivityAttributes` activity, stores the returned activity ID in `reminder.activityID`.
   - `updateActivity(for reminder: Reminder)` — updates the content state (e.g., when title changes or completion toggles).
   - `endActivity(for reminder: Reminder)` — ends the activity with `.dismiss` policy, clears `reminder.activityID`.
   - `checkAutoStart()` — iterates reminders with `dueDate` in the next 30 min, not completed, no active activity — starts one for each.
   - Stores active `Activity<QuillActivityAttributes>` references in `[UUID: Activity<...>]` dictionary.
   - On init, rehydrates existing activities via `Activity<QuillActivityAttributes>.activities`.

**New file: `QuillWidget/QuillLiveActivityViews.swift`**:

4. Lock screen banner view:
   - Reminder title, priority badge, due date countdown (relative).
   - Tap to deep-link to reminder detail.

5. Dynamic Island compact view:
   - Leading: priority-colored circle.
   - Trailing: reminder title (truncated).

6. Dynamic Island minimal view:
   - Priority-colored circle only.

7. Dynamic Island expanded view:
   - Leading: priority circle + title.
   - Trailing: due date.
   - Bottom: "Open in Quill" button.

**File: `Quill/Views/Detail/ReminderDetailView.swift`**:

8. Add a "Focus" toggle button in the toolbar or as a prominent action:
   - Shows filled target icon when active, outline when inactive.
   - Calls `LiveActivityManager.shared.startActivity(for:)` or `endActivity(for:)`.
   - Haptic feedback on toggle.

**File: `Quill/App/QuillApp.swift`**:

9. Add `.onChange(of: scenePhase)` that calls `LiveActivityManager.shared.checkAutoStart()` when returning to foreground. This catches reminders that became "within 30 min" while the app was backgrounded.

**File: `QuillWidget/QuillWidgetBundle.swift`**:

10. If the Live Activity uses a separate `Widget` declaration, register it in the bundle. Otherwise, if bundled into `QuillWidget`, no change needed.

**File: `quill.xcodeproj/project.pbxproj`**:

11. Add new Swift files to the widget extension target (`QuillLiveActivity.swift`, `QuillLiveActivityViews.swift`) and main target (`LiveActivityManager.swift`, changes to `Reminder.swift`, `ReminderDetailView.swift`, `QuillApp.swift`).

### Auto-start logic detail
```
on foreground resume:
  for each reminder where:
    - isCompleted == false
    - dueDate is within next 30 minutes
    - activityID == nil
  → start Live Activity
  → store activity ID on reminder

on reminder completion:
  → if activityID != nil, end activity

on dueDate pass without completion:
  → activity stays visible until dismissed or completed
```

### Acceptance criteria
- Tapping "Focus" on a reminder detail starts a Live Activity.
- When a reminder is within 30 min of due, an activity auto-starts on foreground resume.
- Activity appears on Lock Screen with reminder info and countdown.
- Dynamic Island shows compact/minimal/expanded views.
- Completing a reminder dismisses its activity.
- Multiple concurrent activities supported (one per focused reminder).
- Activity rehydrates correctly after app restart.

---

## Execution Order

| Order | Item | Effort | Dependencies | Status |
|-------|------|--------|-------------|--------|
| 1 | Large Widget | Small | Extends existing widget code | **Done** |
| 2 | Lock Screen Widgets | Small | Same file, same entry model | **Done** |
| 3 | Custom App Icons | Small | Independent of widgets | **Done** |
| 4 | Live Activities | Medium | New files, new service, touches ViewModel and DetailView | **Done** |

All items completed. Widgets (1–2) built on the same code. Icons (3) independent. Live Activities (4) was the most complex.

---

## Files Modified (Summary)

| File | Action |
|------|--------|
| `QuillWidget/QuillWidget.swift` | **Done** — large + lock screen views, new families |
| `QuillWidget/QuillLiveActivity.swift` | **Done** — ActivityAttributes definition |
| `QuillWidget/QuillLiveActivityViews.swift` | **Done** — Lock screen + Dynamic Island views |
| `QuillWidget/QuillWidgetBundle.swift` | **Done** — registered activity widget |
| `Quill/Models/Reminder.swift` | **Done** — added `activityID` field |
| `Quill/Services/LiveActivityManager.swift` | **Done** — Activity lifecycle management |
| `Quill/Views/Detail/ReminderDetailView.swift` | **Done** — Focus toggle button |
| `Quill/App/QuillApp.swift` | **Done** — foreground auto-start check |
| `Quill/Helpers/ThemeManager.swift` | **Done** — AppIcon enum, setAppIcon method |
| `Quill/Views/Settings/SettingsView.swift` | **Done** — icon picker UI |
| `Quill/Resources/Assets.xcassets/` | **Done** — 3 alternate icon asset catalogs |
