# Notes

## Summary

- Added a white-stroke barbell vector drawable for the notification icon (`android/app/src/main/res/drawable/ic_stat_sport_timer.xml`).
- Added `android/app/src/main/res/raw/keep.xml` so release builds keep only the notification icon.
- `DefaultBackgroundKeepAlive` now passes `androidNotificationIcon: 'drawable/ic_stat_sport_timer'` through a `@visibleForTesting` `notificationConfig`. The channel id, name and foreground setting are unchanged.

## Evidence

- The notification icon is `drawable/ic_stat_sport_timer`: "uses the barbell drawable as the notification icon" passes.
- Channel id, channel name and stop-foreground setting are unchanged: "keeps the workout channel and foreground settings" passes.
- The drawable is a vector with the barbell path and white strokes only: "the notification icon drawable draws the barbell in white strokes only" passes.
- `keep.xml` keeps only the notification icon: "keep.xml keeps only the notification icon" passes.

## Points to review

None

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
