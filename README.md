> [!CAUTION]
> ‼️ Android will become a locked-down platform. Learn more: https://keepandroidopen.org/

<p align="center">
    <img src="docs/icon/icon.png" alt="App Icon" width="100" />
    <br>
    v2.1.0
</p>

<p align="center">
    <a href="https://github.com/doen1el/calibre-web-companion/releases">
        <img src="https://img.shields.io/github/downloads/doen1el/calibre-web-companion/total?color=green&label=Downloads%20(GitHub)" alt="GitHub all releases">
    </a>
    <a href="https://f-droid.org/en/packages/de.doen1el.calibreWebCompanion/" >
        <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgithub.com%2Fkitswas%2Ffdroid-metrics-dashboard%2Fraw%2Frefs%2Fheads%2Fmain%2Fprocessed%2Ftotal%2Fde.doen1el.calibreWebCompanion.json&query=%24.total_downloads&logo=fdroid&label=Downloads%20(F-Droid)">
    </a>
    <a href="https://github.com/doen1el/calibre-web-companion/releases">
        <img src="https://img.shields.io/github/v/release/doen1el/calibre-web-companion?color=green&label=download&sort=semver" alt="GitHub release (latest SemVer)">
    </a>
    <a href="https://github.com/doen1el/calibre-web-companion/actions?query=workflow%3ABuild+branch%3Adev">
        <img src="https://img.shields.io/github/actions/workflow/status/doen1el/calibre-web-companion/main.yml?branch=dev" alt="GitHub Workflow Status">
    </a>
    <a href="https://hosted.weblate.org/engage/calibre-web-companion/">
        <img src="https://hosted.weblate.org/widget/calibre-web-companion/svg-badge.svg" alt="Translation status" />
    </a>
    <a href="https://codeberg.org/doen1el/calibre-web-companion">
        <img src="https://img.shields.io/badge/mirror-Codeberg-2185D0?logo=codeberg&logoColor=white" alt="Codeberg mirror">
    </a>
</p>

# Calibre Web Companion

This is an unofficial companion application for [Calibre Web](https://github.com/janeczku/calibre-web) (which also works for [Calibre Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated), [Grimmory](https://github.com/grimmory-tools/grimmory), [Calibre 'Sharing over the net'](https://github.com/kovidgoyal/calibre) and other OPDS providers (beta)), that allows you to browse your book collection and download books directly to your device. You can also interact with your books by marking them as read, unread or bookmarked. It is also possible to send books directly to your e-reader (Kindle/Kobo) thanks to the great work of [send2ereader](https://github.com/daniel-j/send2ereader).

The app is built with [Flutter](https://github.com/flutter/flutter) and uses **Material You**. It is currently available for **Android** only.

## 📦 Installation

<p align="left">
    <a href="https://f-droid.org/en/packages/de.doen1el.calibreWebCompanion/">
        <img src="https://f-droid.org/badge/get-it-on.png" alt="Get it on F-Droid" height="80">
    </a>
    <a href="https://play.google.com/store/apps/details?id=de.doen1el.calibreWebCompanion">
        <img src="docs/badges/badge_play.png" alt="Get it on Google Play" height="80">
    </a>
    <a href="https://github.com/doen1el/calibre-web-companion/releases">
        <img src="docs/badges/badge_github.png" alt="Get it on GitHub" height="80">
    </a>
    <a href="https://github.com/doen1el/calibre-web-companion/wiki/Installing-Calibre%E2%80%90Web%E2%80%90Companion-from-GitHub-using-Obtainium">
        <img src="docs/badges/badge_obtainium.png" alt="Get it on Obtainium" height="80">
    </a>
</p>

## 💪 Features

- Connect to your Calibre-Web (Automated), Grimmory, Calibre and OPDS servers, including reverse proxy/SSO setups, custom HTTP headers and self-signed certificates.
- Browse your whole library with smooth, fast navigation.
- Discover books by category, authors, series, publishers, ratings, hot & trending, and more.
- View rich details for every book, edit its metadata, and upload new covers.
- Mark books as read or unread, archive them, and organize them into shelves.
- Create, edit and browse Magic Shelves, dynamic, rule‑based shelves (Calibre‑Web Automated only).
- Add books quickly by scanning their ISBN barcode.
- Read books in the built‑in eBook reader and sync your reading progress across devices via WebDAV.
- Send books to your e‑reader via [send2ereader](https://github.com/daniel-j/send2ereader) (or your own instance) or Calibre‑Web's email function.
- Download books straight into your collection with [shelfmark](https://github.com/calibrain/shelfmark).
  - ⚠️ This app does **not** support, encourage or facilitate the piracy of copyrighted works. Please only download content you are legally entitled to, respecting copyright is your responsibility.
- Upload books to your Calibre‑Web server.
- Sync your whole library or selected books for offline reading.
- Check your collection statistics at a glance.
- Make it yours: reorder or hide book actions, detail sections and Discover sections, choose a theme, enable e‑ink mode, and adjust the text size, available in 15 languages.

## 🖼️ Impressions

<p align="center">
    <img src="docs/feature_graphics/1.png" alt="InApp" width="32%"/>
    <img src="docs/feature_graphics/2.png" alt="Share" width="32%" />
    <img src="docs/feature_graphics/3.png" alt="OpenTracks" width="32%" />
    <img src="docs/feature_graphics/4.png" alt="OpenTracks" width="32%" />
    <img src="docs/feature_graphics/5.png" alt="OpenTracks" width="32%" />
    <img src="docs/feature_graphics/6.png" alt="OpenTracks" width="32%" />
</p>

## 🌍 l10n

You can help translate Calibre Web Companion on [Weblate](https://hosted.weblate.org/projects/calibre-web-companion/app/).

<a href="https://hosted.weblate.org/engage/calibre-web-companion/">
<img src="https://hosted.weblate.org/widget/calibre-web-companion/app/multi-auto.svg" alt="Translation status" />
</a>

## 🚀 Contributing

You can of course open issues for bugs, feedback, and feature ideas. All suggestions are very welcome :)

The source code is also mirrored on [Codeberg](https://codeberg.org/doen1el/calibre-web-companion). GitHub remains the primary repository, so please open issues and pull requests here.

## 📜 Credits

- [Calibre Web](https://github.com/janeczku/calibre-web)
- [Calibre Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated)
- [shelfmark](https://github.com/calibrain/shelfmark)
- [send2ereader](https://github.com/daniel-j/send2ereader)
- [Flutter](https://github.com/flutter/flutter)
- [IconKitchen](https://icon.kitchen)
- [Weblate](https://hosted.weblate.org/)
- [CosmosEpub](https://github.com/Mamasodikov/cosmos_epub)
