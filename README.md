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

