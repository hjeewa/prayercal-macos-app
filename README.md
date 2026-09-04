# PrayerCal

A prayer-focused native macOS menu-bar app that keeps the next prayer visible and makes prayer times, reminders, and calendar planning readily accessible. Optional Hijri tools cover dates, notable Sunni events, and birthdays.

## Download

[Download the latest PrayerCal DMG](https://github.com/hjeewa/prayercal-macos-app/releases/latest/download/PrayerCal.dmg)

Requires macOS 14 or later. Open the DMG and drag **PrayerCal** into **Applications**. The current builds are ad-hoc signed but not Apple-notarized, so macOS may ask you to confirm the first launch in **System Settings → Privacy & Security**.

## Features

- Local prayer times and next-prayer menu-bar status
- Branded prayer popover with today plus seven days of forward navigation
- First-run onboarding for location, calculation method, reminders, and optional Hijri tools
- Moonsighting Committee, MWL, ISNA, Umm al-Qura, Karachi and regional calculation methods
- Compatibility adjustments matching PrayerCal's existing calendar generator
- Standard or Hanafi Asr calculation and configurable high-latitude rules
- Per-prayer reminders, calendar inclusion, and event duration
- Optional full-screen prayer reminders across every connected display, with snooze
- Live Webcal subscriptions generated and continually refreshed by PrayerCal
- One-click subscription for Apple Calendar, Google Calendar, and Outlook
- Optional current Hijri date, observances, and birthdays in the menu-bar popover
- Significant Sunni observances and upcoming dates
- Gregorian-to-Hijri birthday conversion
- Hijri age tracking for multiple people
- Offline operation using Apple's Umm al-Qura calendar
- Universal app for Apple Silicon and Intel Macs
- Automatic update checks powered by Sparkle, with signed update feeds

## Run locally

```sh
swift run PrayerCal
```

The app appears in the menu bar as the next prayer and its time. Click it to see the upcoming schedule and navigate up to seven days ahead. Open **Settings** to configure prayer calculations, reminders, Calendar export, and the optional Hijri tools.

Hijri conversion uses Apple's Umm al-Qura calendar and works offline. Calendar dates can differ by a day depending on local moon sighting.

## Versioning and releases

PrayerCal follows [Semantic Versioning](https://semver.org/). The current version is stored in [`VERSION`](VERSION). Pushing a matching tag such as `v0.4.0` runs the test suite, builds a universal app, creates a DMG, and publishes it on GitHub Releases.

To publish a release after updating `VERSION` and the changelog:

```sh
git tag v0.4.0
git push origin main v0.4.0
```

## Changelog

### 0.4.0 — 2026-09-04

- Made prayer times the primary menu-bar experience, with the next prayer and today's full schedule.
- Added a branded first-run onboarding flow and seven-day prayer schedule navigation.
- Added current-location and manual-coordinate setup with location-aware time zones.
- Added Moonsighting Committee, MWL, ISNA, Umm al-Qura, Karachi, Diyanet and regional calculation methods.
- Added Standard and Hanafi Asr calculation plus configurable high-latitude rules.
- Added per-prayer reminders with configurable lead times.
- Added optional full-screen prayer alerts on every display, including a five-minute snooze.
- Made the Hijri date, events, and birthday tools optional.
- Added PrayerCal-hosted Webcal subscriptions with Apple Calendar, Google Calendar, Outlook, and copy-link actions.
- Added Sparkle automatic update checks and a signed appcast release pipeline.
- Added Adhan Swift calculation coverage and Calendar export tests.

### 0.3.0 — 2026-09-04

- Renamed the app from HijriBar to PrayerCal to reflect its prayer-focused direction.
- Added a Calendar Dates settings screen where every event can be viewed or removed.
- Added support for manually creating significant or personal Hijri dates.
- Expanded the seeded calendar with Tasu'a, the last ten nights of Ramadan, the first ten days of Dhu al-Hijjah, the Days of Tashreeq, and selected prophetic-era anniversaries including Badr, Uhud, the Hijrah arrival, and the Conquest of Makkah.
- Added clear notes where the precise historical date differs between reports.

### 0.2.0 — 2026-09-04

- Added the number of days until each person's next Hijri birthday beside their birthday date.
- Added natural countdown labels for birthdays that are today or tomorrow.
- Handles birthdays on day 30 when that Hijri month has only 29 days in a later year.

### 0.1.0 — 2026-09-04

- Initial release.
- Added the live Hijri menu-bar date and calendar popover.
- Added significant Sunni observances with moon-sighting guidance.
- Added persistent people, Gregorian birthday conversion, and Hijri age tracking.
- Added universal Apple Silicon and Intel packaging.
