# HijriBar

A small native macOS menu-bar app showing the current Hijri date, notable Sunni calendar events, and saved people's Hijri birthdays and ages.

## Download

[Download the latest HijriBar DMG](https://github.com/hjeewa/prayercal-macos-app/releases/latest/download/HijriBar.dmg)

Requires macOS 14 or later. Open the DMG and drag **HijriBar** into **Applications**. The current builds are ad-hoc signed but not Apple-notarized, so macOS may ask you to confirm the first launch in **System Settings → Privacy & Security**.

## Features

- Current Hijri date in the macOS menu bar
- Significant Sunni observances and upcoming dates
- Gregorian-to-Hijri birthday conversion
- Hijri age tracking for multiple people
- Offline operation using Apple's Umm al-Qura calendar
- Universal app for Apple Silicon and Intel Macs

## Run locally

```sh
swift run HijriBar
```

The app appears in the menu bar as a short Hijri date. Click it to see the full date, observances, and saved birthdays. Open **Settings** from the popover to add or edit people.

Hijri conversion uses Apple's Umm al-Qura calendar and works offline. Calendar dates can differ by a day depending on local moon sighting.

## Versioning and releases

HijriBar follows [Semantic Versioning](https://semver.org/). The current version is stored in [`VERSION`](VERSION). Pushing a matching tag such as `v0.2.0` runs the test suite, builds a universal app, creates a DMG, and publishes it on GitHub Releases.

To publish a release after updating `VERSION` and the changelog:

```sh
git tag v0.2.0
git push origin main v0.2.0
```

## Changelog

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
