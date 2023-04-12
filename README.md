# custom_mouse_cursor

![](https://img.shields.io/pub/v/custom_mouse_cursor?color=green)
![Publisher: hiveright.tech](https://img.shields.io/pub/publisher/custom_mouse_cursor)
[![Apache 2.0 License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](/LICENSE)

This package provides simple custom mouse cursor support for Flutter.  The custom mouse cursors are devicePixelRatio aware so they will remanin the proper size on different devicePixelRatio's and on machines with multiple monitors with varying devicePixelRatios.  Simply create [CustomMouseCursor]()'s objects and use them
int the same way you would use [SystemMouseCursors](). 


<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_app_windowcapture_01.png" width="100%">

CustomMouseCursor's can be created directly from any flutter image asset as well as flutter icons (just as you would with Flutter Icon).
For power users Flutter's ui.Image objects can also be used (allowing for anything you might dream up, even animated cursor's).

CustomMouseCursors are very performant.  All work is cached so switching between monitors of varying devicePixelRatio's is seemless.

The custom mouse cursors will be automatically adjusted for the system's devicePixelRatio and when moving the flutter window between monitors with varying devicePixelRatios.

###Note

CUrrently Flutter master channel is currently required for windows support.  This package provides platform plugins that provide support for macos and limux platforms.  
Proper window's support is not possible without [changes to the fluter engine](https://github.com/flutter/engine/pull/36143) that are included within the master channel.

I have submitted a PR [pr number on engine] that provides support for the web platform.  With luck that PR will land in the master channel soon.

## Supported Platforms

- [x] macOS (works with current flutter `stable` channel or `master`)
- [x] Linux (works with current flutter `stable` channel or `master`)
- [x] Windows (requires the flutter `master` channel)*
- [x] Web (requires flutter engine PR #xyz, hopefully `master` channel soon)*

* As of 4/9/23 Windows support requires the master channel (until [flutter engine PR#36143](https://github.com/flutter/engine/pull/36143) lands in stable).
* As of 4/9/23 Web support requires custom engine with [flutter engine PR#xxxx](https://github.com/flutter/engine/pull/36143) lands in the master channel.

This package could not exist without the work of @Kingtous's [flutter engine PR#36143](https://github.com/flutter/engine/pull/36143) allowing proper windows support and @imiskolee's github for original the [Windows, Mac and linux support](https://github.com/imiskolee/flutter_custom_cursor).


Note: Currently, the api required by this plugin on Windows is included in flutter `master` branch. It means that u need to use this plugin with flutter master branch on Windows platform. See [flutter engine PR#36143](https://github.com/flutter/engine/pull/36143) for details.

## Example use
Each example shows excerpt from example app with the the cursor the example code created showing on the left side of the image.
The `CustomMouseCursor` cursor objects are used exactly as you would any `SystemMouseCursors.xxxx` cursor.
Custom mouse cursors are can be created from asset images or icons.

`CustomMouseCursor.asset()` and `CustomMouseCursor.exactasset()` are used to create custom cursors from asset images.
`CustomMouseCursor.icon()` is used to create custom cursor from any IconData object (just as you would a regular `Icon` widget in flutter).

<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_cursor1.png" width="100%">

```DART
  // Example of image asset that has many device pixel ratio versions (1.5x,2.0x,2.5x,3.0x,3.5x,4.0x,8.0x
  assetCursor = await CustomMouseCursor.asset(
      "assets/cursors/startrek_mousepointer.png",
      hotX: 18,
      hotY: 0);
```

<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_cursor2.png" width="100%">

```dart
  // Example of image asset that has obly device pixel ratio versions (1.0x ands 2.5x)
  assetCursor = await CustomMouseCursor.asset(
      "assets/cursors/startrek_mousepointer.png",
      hotX: 18,
      hotY: 0);

```

<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_cursor3.png" width="100%">

```dart
  // Example of image asset only at 8x native DevicePixelRatio so will get scaled down to most/all encoutered DPR's
  assetNative8x = await CustomMouseCursor.exactAsset(
      "assets/cursors/star-trek-mouse-pointer-cursor292x512.png",
      hotX: 144,
      hotY: 0,
      nativeDevicePixelRatio: 8.0);
```

<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_cursor4.png" width="100%">

```dart
  List<Shadow> shadows = [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.8),
      offset: Offset(4, 3),
      blurRadius: 3,
      spreadRadius: 2,
    ),
  ];
  iconCursor = await CustomMouseCursor.icon(
      Icons.redo,
      size: 24,
      hotX: 22,
      hotY: 17,
      color: Colors.pinkAccent,
      shadows: shadows);
```

<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_cursor5.png" width="100%">

```dart
  msIconCursor = await CustomMouseCursor.icon(
      MaterialSymbols.arrow_selector_tool,
      size: 32,
      hotX: 8,
      hotY: 2,
      fill: 1,
      color: Colors.blueAccent,
      shadows: shadows);
```

<img src="https://raw.githubusercontent.com/timmaffett/custom_mouse_cursor/master/media/example_cursor6.png" width="100%">

```DART
  assetCursorSingleSize = await CustomMouseCursor.exactAsset(
      "assets/cursors/example_game_cursor_64x64.png",
      hotX: 2,
      hotY: 2,
      nativeDevicePixelRatio: 2.0);
```

