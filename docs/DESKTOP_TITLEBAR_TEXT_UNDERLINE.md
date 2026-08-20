# Desktop Title Bar: Stray Yellow Underline Under Text

## Symptom

After adding the app icon + "Keep Track" label to `DesktopTitleBar` (leftmost
position, next to the window minimize/maximize/close controls), the text
rendered with a solid yellow underline directly beneath it — visually
distinct from the text's own color, and not present anywhere else in the app
despite dozens of other `Text` widgets using the same fonts/colors.

## Investigation

1. **Ruled out a stale/duplicate process artifact.** This session had
   several messy `flutter run` restarts that left duplicate `keep_track.exe`
   processes running simultaneously (holding conflicting Hive file locks).
   Killed every instance, rebuilt from a single clean launch — the underline
   was still there. Not a leftover-process glitch.
2. **Zoomed into a cropped screenshot** of the title bar to inspect the
   underline itself: a clean, solid, straight line spanning exactly the
   width of the "Keep Track" text, positioned right at the text baseline.
   Not wavy (rules out an OS spell-check-style indicator), not offset from
   the text (rules out a stray `Divider`/`Container` border underneath it).
3. **Checked what else renders in the same title bar row.** The `Icon`
   widgets (help, settings, inbox buttons) were unaffected — only `Text`
   showed it. The pre-existing "OFFLINE" badge `Text` in the same row also
   didn't show it in the screenshot, so it wasn't a title-bar-wide theme
   issue either — it looked specific to the newly-added `Text`.
4. **Found the structural difference.** `DesktopTitleBar` isn't rendered
   inside the normal `Scaffold`/`Material` widget tree. It's injected via
   `MaterialApp`'s `builder` callback into a raw `Overlay`/`OverlayEntry`
   that sits as a sibling above the actual app `Navigator` (see `main.dart`):

   ```dart
   builder: (context, child) {
     if (!kIsWeb && DesktopTitleBar.isDesktopPlatform) {
       return Overlay(
         initialEntries: [
           OverlayEntry(
             builder: (_) => Column(
               children: [
                 const DesktopTitleBar(),
                 Expanded(child: child ?? const SizedBox()),
               ],
             ),
           ),
         ],
       );
     }
     return child ?? const SizedBox();
   },
   ```

   Because of this, `Text` widgets inside `DesktopTitleBar` resolve their
   effective style by merging with whatever `DefaultTextStyle` is ambient at
   that point in the tree — not the one a `Scaffold`/`Material` further down
   would normally provide. Every other `Text` widget in the app that looked
   fine lives *inside* the `Scaffold` tree via `child`, not inside this
   `Overlay`.
5. **Confirmed empirically.** Added `decoration: TextDecoration.none`
   explicitly to the "Keep Track" `Text`'s style and rebuilt — the underline
   was gone. This conclusively identified it as a `TextStyle.decoration`
   issue rather than an OS-level overlay (Windows text recognition,
   accessibility highlighting, etc.), even without pinning down the exact
   origin of the inherited `TextDecoration.underline`.

## Fix

Explicitly set `decoration: TextDecoration.none` on every `Text` widget
inside `DesktopTitleBar` (`lib/core/ui/desktop_title_bar.dart`), rather than
relying on the default (which normally doesn't need stating, but does here
because of the `Overlay`-based placement described above):

- `_AppTitle`'s "Keep Track" label
- `_OfflineIndicator`'s "OFFLINE" badge
- `_SyncStatusChip`'s sync-status label

## Guidance for future work in this file

Any new `Text` widget added inside `DesktopTitleBar` (or any other widget
placed in `main.dart`'s `Overlay`/`OverlayEntry`, outside the normal
`Scaffold` tree) should set `decoration: TextDecoration.none` explicitly on
its style. Don't assume "no decoration specified" behaves the same way it
does for `Text` widgets elsewhere in the app — the ambient `DefaultTextStyle`
at that point in the tree is different.
