
# Changelog for custom_mouse_cursor package

## 1.1.1

* Fix generateUniqueKey() to use DateTime.now().microsecond as random seed instead of millisecond and keep
  the Random() generator around so the reuse it and the seed time being the same will never be an issue.

## 1.1.0

* Fix exactAsset dpr 1->2 bug

## 1.0.3

* Fix onMetricsChange() callback to chain to previous set callback.
* Cleanup logging and enable const setting to eliminate entirely.
* Made imageBuffer non-nullable and always present in cache.

## 1.0.2

* Clean up readme and example.

## 1.0.1

* Add Flutter engine [PR#41186](https://github.com/flutter/engine/pull/41186) to README.md

## 1.0.0

* Initial release
