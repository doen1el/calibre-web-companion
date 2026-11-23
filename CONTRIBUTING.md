# Contributing to Calibre Web Companion

Thanks for helping! Issues for bugs, feedback and feature ideas are always
welcome. GitHub is the primary repository; the
[Codeberg mirror](https://codeberg.org/doen1el/calibre-web-companion) is
read-only, so please open issues and pull requests on GitHub.

## Translations

Translations are managed on
[Weblate](https://hosted.weblate.org/projects/calibre-web-companion/app/).
Please do not edit the `.arb` files of other languages directly in a pull
request; changes there would be overwritten by Weblate.

## Pull requests

- Open pull requests against the `dev` branch.
- Keep a pull request focused on one fix or feature.
- Run `flutter analyze` and `flutter test` before submitting.
- If your change behaves differently on Android and iOS, mention how you
  tested it on each platform (or that you could not).

## License of contributions

Calibre Web Companion is licensed under the
[GNU General Public License, version 3](LICENSE), with an
[additional permission](LICENSE-EXCEPTION.md) that allows distribution through
app stores such as Apple's App Store.

By submitting a contribution (code, translations, documentation, artwork or
anything else) you confirm that:

1. You wrote it yourself, or you have the right to submit it under these terms.
2. You license it under the GPL, version 3, **together with the additional
   permission** in [LICENSE-EXCEPTION.md](LICENSE-EXCEPTION.md).

### About the App Store version

The iOS app is sold on the App Store for a small one-time price. That price
only exists to cover Apple's annual developer fee of 99 €; it is not meant to
make a profit. The source code stays free, and anyone can build the app and
sign the `.ipa` for their own devices without paying anything. All Android
builds stay free.
