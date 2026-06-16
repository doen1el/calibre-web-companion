#!/usr/bin/env bash
# Generates a Play Store "What's New" directory from the Fastlane changelogs of
# the current versionCode.
set -euo pipefail

VERSION_CODE="${1:?versionCode required}"
OUT_DIR="${2:-distribution/whatsnew}"
META_DIR="fastlane/metadata/android"

MAX_LEN=500

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

found=0
for dir in "$META_DIR"/*/; do
  locale="$(basename "$dir")"
  changelog="${dir}changelogs/${VERSION_CODE}.txt"
  [[ -f "$changelog" ]] || continue

  text="$(cat "$changelog")"
  if [[ "${#text}" -gt "$MAX_LEN" ]]; then
    echo "::warning::Changelog for $locale ($VERSION_CODE) is ${#text} chars (>$MAX_LEN); truncating."
    text="${text:0:$((MAX_LEN - 10))}..."
  fi

  printf '%s' "$text" > "$OUT_DIR/whatsnew-${locale}"
  echo "  $locale -> whatsnew-${locale}"
  found=$((found + 1))
done

if [[ "$found" -eq 0 ]]; then
  echo "::warning::No Fastlane changelogs found for versionCode $VERSION_CODE."
fi
echo "Generated $found What's-New file(s) in $OUT_DIR"
