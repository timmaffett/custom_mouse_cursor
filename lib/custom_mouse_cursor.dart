import 'dart:async';
import 'dart:io';

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';

//WIN32//import 'package:win32/win32.dart';
//WIN32//import 'package:win32/winrt.dart' hide Color;

enum _CustomMouseCursorCreationType { exactasset, asset, image, icon }

class _CustomMouseCursorFromIconOriginInfo {
  _CustomMouseCursorFromIconOriginInfo({
    required this.icon,
    required this.size,
    required this.hotX,
    required this.hotY,
    required this.nativeDevicePixelRatio,
    required this.fill,
    required this.weight,
    required this.opticalSize,
    required this.grade,
    required this.color,
    required this.shadows,
  });
  final double size;
  final double nativeDevicePixelRatio;
  final int hotX;
  final int hotY;
  final IconData icon;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color color;
  final List<Shadow>? shadows;
}

/// This is used to cache information about already created cursors for a specific
/// DevicePixelRatio.  This allows us to skip re-loading/creation of bitmaps for
/// a given DPR when the flutter window moves between different DPR screens.
class _CustomMouseCursorDPRBitmapCache {
  const _CustomMouseCursorDPRBitmapCache(
      this.imageBuffer, this.width, this.height, this.hotX, this.hotY);
  final Uint8List imageBuffer;
  final int width;
  final int height;
  final int hotX;
  final int hotY;
}

//ignore: must_be_immutable
class CustomMouseCursor extends MouseCursor {
  /// This is the cursor's key - it is *actually* final for all platforms EXCEPT web,
  /// where it can change on DPI resolution changes because on the web platform this
  /// *IS* the cursor definition (as a CSS cursor data-uri image)
  String _key;

  String get key => _key;

  set key(String newKey) {
    if (!kIsWeb) {
      throw ('Attempt to change the key on a CustomMouseCursor when the platform is not web!');
    }
    _key = newKey;
  }

  /// The origin story for this cursor, whether it was created from an exact asset,
  /// a DPI aware AssetImage, an icon or an image.  This is used to decide how to
  /// RE-create the cursor when the DPI/DevicePixelRatio changes.
  final _CustomMouseCursorCreationType originStory;

  /// When the DevicePixelRatio is different or changes from this size
  /// the the pointer will be scaled accordingly when
  /// CustomMousePointer.didChangeDependencies() is called.
  /// The user should always call CustomMousePointer.didChangeDependencies() from
  /// their top level widget's didChangeDependencies() handler to
  /// ensure that pointers change to DPI/DevicePixelRatio dependent sizes.
  ///
  /// For example if you were specifying a size of 32 for the icon, and the
  /// DevicePixelRatio changed to 2.0, the icon would be scaled
  /// by ratio=newDevicePixelRatio/nativeDevicePixelRatio=2.0 and
  /// the icon would be scaled up to newSize=2.0x32=64 pixels.
  /// This is the DevicePixelRatio for which the
  /// [hotXAtNativeDevicePixelRatio] and [hotYAtNativeDevicePixelRatio]
  /// are specified.
  final double nativeDevicePixelRatio;

  /// This is the X location of hot spot at the [nativeDevicePixelRatio]
  /// This gets scaled accordingly on DPI changes.
  final int hotXAtNativeDevicePixelRatio;

  /// This is the Y location of hot spot at the [nativeDevicePixelRatio]
  /// This gets scaled accordingly on DPI changes.
  final int hotYAtNativeDevicePixelRatio;

  /// The DevicePixelRatio for which the current backing cursor was created.
  double currentCursorDevicePixelRatio;

  /// If [originStory]==[_CustomMouseCursorCreationType.asset] then this contains the
  /// [AssetImage] used in its created (and used for updating on DevicePixelRatio changes).
  /// If [originStory]==[_CustomMouseCursorCreationType.exactasset] then this contains the
  /// [ExactAssetImage] used in its created (and used for updating on DevicePixelRatio changes).
  AssetBundleImageProvider? _assetBundleImageProvider;

  AssetBundleImageKey? _currentAssetAwareKey;

  _CustomMouseCursorFromIconOriginInfo? _iconCreationInfo;

  /// This holds cache of the bitmaps/info we have made for this bitmap for different
  /// DevicePixelRatio monitors.
  final Map<double, _CustomMouseCursorDPRBitmapCache> _dprBitmapCache = {};

  /// This holds cache of the css cursor definitions for web platforms.
  /// Once we have created a web css cursor we cache it here for reuse
  /// when switching between monitors with different DevicePixelRatios.
  final Map<double, String> _dprCSSCursorCache = {};

  /// Cache of all the created custom cursors
  static final Map<String, CustomMouseCursor> _cursorCacheOfAllCreatedCursors =
      {};

  CustomMouseCursor._(
      this._key,
      this.originStory,
      this.nativeDevicePixelRatio,
      this.hotXAtNativeDevicePixelRatio,
      this.hotYAtNativeDevicePixelRatio,
      this.currentCursorDevicePixelRatio)
      : assert(_key != "");

  Future<ui.Image> getUiImage(
      String imageAssetPath, int height, int width) async {
    final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
    final codec = await ui.instantiateImageCodec(
      assetImageByteData.buffer.asUint8List(),
      targetHeight: height,
      targetWidth: width,
    );
    final image = (await codec.getNextFrame()).image;
    return image;
  }

  static Future<CustomMouseCursor> exactAsset(
    String assetName, {
    int hotX = 0,
    int hotY = 0,
    double nativeDevicePixelRatio = 1.0,

    /// An existing cursor that should be updated instead of creating a new cursor.
    /// This is used on DevicePixelRatio changes to update the cursors backing
    /// image.
    CustomMouseCursor? existingCursorToUpdate,

    /// Optionally allow caller to send BuildContext to use to get a ImageConfiguration (if needed)
    BuildContext? context,
  }) async {
    return asset(assetName,
        hotX: hotX,
        hotY: hotY,
        nativeDevicePixelRatio: nativeDevicePixelRatio,
        existingCursorToUpdate: existingCursorToUpdate,
        context: context,
        useExactAssetImage: true);
    /*
    ExactAssetImage? assetImage;
    AssetBundleImageKey? assetAwareKey;

    double rescaleRatioRequiredForImage = 0;
    // call and get an ImageConfiguration if we don't have one yet
    _lastImageConfiguration ??= _createLocalImageConfigurationWithOrWithoutContext(context:context);

    if (_lastImageConfiguration != null && _lastImageConfiguration!.devicePixelRatio!=null) {
      assetImage = ExactAssetImage(assetName);
      assetAwareKey = await assetImage.obtainKey(_lastImageConfiguration!);

      rescaleRatioRequiredForImage = _lastImageConfiguration!.devicePixelRatio!/nativeDevicePixelRatio;

      if(nativeDevicePixelRatio!=_lastImageConfiguration!.devicePixelRatio!) {
        print('CHANGING NATIVE PIXEL RATIO (OLD DPR=$nativeDevicePixelRatio hotX=$hotX hotY=$hotY)');
        hotX = (hotX * rescaleRatioRequiredForImage).round();
        hotY = (hotY * rescaleRatioRequiredForImage).round();
        nativeDevicePixelRatio = _lastImageConfiguration!.devicePixelRatio!;
        print('  UPDATED values DPR=$nativeDevicePixelRatio hotX=$hotX hotY=$hotY');
      }
      //
      assetName = assetAwareKey.name;
    } else {
      // THIS CASE SHOULD NEVER BE ABLE TO HAPPEN
      // todo: tmm  CLEAN THIS AND REMOVE THIS CODE
      double currentDevicePixelRatio;
      currentDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      print('In asset() Loading but lastImageConfiguration WAS NULL and currentDevicePixelRatio=$currentDevicePixelRatio');
      print('  WILL NOT START WITH DPI AssetImage() load');
      throw('Unknown DevicePixelRatio in exactasset');
    }

    // NOW we have decide on the name we will use then check for existing cursor
    if (cursorCache.containsKey(assetName)) {
      return cursorCache[assetName]!;
    }

    // and load the asset
    final rawAssetImageBytes = await rootBundle.load(assetName);

    final rawUint8 = rawAssetImageBytes.buffer.asUint8List();

    //OLDWAYui.Image uiImage = await decodeImageFromList(rawUint8);
  final ui.Codec codec = await PaintingBinding.instance.instantiateImageCodecWithSize(
          await ImmutableBuffer.fromUint8List(rawUint8),
          getTargetSize: rescaleRatioRequiredForImage==1.0 ? null : (int width, int height) {
            return TargetImageSize(width:(width*rescaleRatioRequiredForImage).round(),
                              height:(height*rescaleRatioRequiredForImage).round() );
          } );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    ui.Image uiImage = frameInfo.image;

    print('Asset loaded image width=${uiImage.width} height=${uiImage.height}');

    final cursor = await image(assetName, uiImage, hotX, hotY,
        _CustomMouseCursorCreationType.asset, nativeDevicePixelRatio,
        existingCursorToUpdate: existingCursorToUpdate);

    cursor.assetBundleImageProvider = assetImage;
    cursor.currentAssetAwareKey = assetAwareKey;
    return cursor;
    */
  }

  static Future<CustomMouseCursor> asset(
    String assetName, {
    int hotX = 0,
    int hotY = 0,
    double nativeDevicePixelRatio = 1.0,

    /// An existing cursor that should be updated instead of creating a new cursor.
    /// This is used on DevicePixelRatio changes to update the cursors backing
    /// image.
    CustomMouseCursor? existingCursorToUpdate,

    /// Optionally allow caller to send BuildContext to use to get a ImageConfiguration (if needed)
    BuildContext? context,

    /// Optionally specify that ExactAssetImage should be used instead of AssetImage
    bool useExactAssetImage = false,
  }) async {
    print(
        'Asset() assetName=$assetName nativeDevicePixelRatio=$nativeDevicePixelRatio');
    // If we have a ImageConfiguration object already from didChangeDependencies() being called
    // use that to use AssetImage to do a DPI aware loading of the pointer
    AssetBundleImageProvider? assetBundleImageProvider;
    AssetBundleImageKey? assetAwareKey;
    double rescaleRatioRequiredForImage = 0;
    // call and get an ImageConfiguration if we don't have one yet
    _lastImageConfiguration ??=
        _createLocalImageConfigurationWithOrWithoutContext(context: context);

    if (_lastImageConfiguration != null &&
        _lastImageConfiguration!.devicePixelRatio != null) {
      assetBundleImageProvider = useExactAssetImage
          ? ExactAssetImage(assetName)
          : AssetImage(assetName);
      assetAwareKey =
          await assetBundleImageProvider.obtainKey(_lastImageConfiguration!);

      if (nativeDevicePixelRatio != 1.0 && assetAwareKey.scale == 1.0) {
        // WE were told that the 1.0 is actually [nativeDevicePixelRatio] SO USE THAT
        //  (ExactImageAsset() will always return scale of 1.0)
        rescaleRatioRequiredForImage =
            _lastImageConfiguration!.devicePixelRatio! / nativeDevicePixelRatio;
      } else {
        // At this point it has chosen *SOME* scale of image to use - this MIGHT NOT BE the devicePixelRatio exactly,
        //  so we will need to scale to that..
        rescaleRatioRequiredForImage =
            _lastImageConfiguration!.devicePixelRatio! / assetAwareKey.scale;
      }

      print(
          'Using lastImageConfiguration got rescaleRatioRequiredForImage=$rescaleRatioRequiredForImage  name=${assetAwareKey.name} scale=${assetAwareKey.scale}');
      if (nativeDevicePixelRatio !=
          _lastImageConfiguration!.devicePixelRatio!) {
        print(
            'CHANGING NATIVE PIXEL RATIO (OLD DPR=$nativeDevicePixelRatio hotX=$hotX hotY=$hotY)');
        double adjustHotsToNativeDPRChange =
            _lastImageConfiguration!.devicePixelRatio! / nativeDevicePixelRatio;
        hotX = (hotX * adjustHotsToNativeDPRChange).round();
        hotY = (hotY * adjustHotsToNativeDPRChange).round();
        nativeDevicePixelRatio = _lastImageConfiguration!.devicePixelRatio!;
        print(
            '  UPDATED values DPR=$nativeDevicePixelRatio hotX=$hotX hotY=$hotY');
      }
      //
      assetName = assetAwareKey.name;
    } else {
      // THIS CASE SHOULD NEVER BE ABLE TO HAPPEN
      // todo: tmm  CLEAN THIS AND REMOVE THIS CODE
      double currentDevicePixelRatio;
      currentDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      print(
          'In asset() Loading but lastImageConfiguration WAS NULL and currentDevicePixelRatio=$currentDevicePixelRatio');
      print('  WILL NOT START WITH DPI AssetImage() load');
      throw ('Unknown DevicePixelRatio in asset');
    }

    // NOW we have decide on the name we will use then check for existing cursor
    if (_cursorCacheOfAllCreatedCursors.containsKey(assetName)) {
      return _cursorCacheOfAllCreatedCursors[assetName]!;
    }

    // and load the asset
    final rawAssetImageBytes = await rootBundle.load(assetName);

    final rawUint8 = rawAssetImageBytes.buffer.asUint8List();

    //OLDWAY//ui.Image uiImage = await decodeImageFromList(rawUint8);

    //if(rescaleRequiredForImage!=1.0) {
    //  Size newSize = Size( uiImage.width*rescaleRequiredForImage, uiImage.height*rescaleRequiredForImage);
    final ui.Codec codec = await PaintingBinding.instance
        .instantiateImageCodecWithSize(
            await ImmutableBuffer.fromUint8List(rawUint8),
            getTargetSize: rescaleRatioRequiredForImage == 1.0
                ? null
                : (int width, int height) {
                    return TargetImageSize(
                        width: (width * rescaleRatioRequiredForImage).round(),
                        height:
                            (height * rescaleRatioRequiredForImage).round());
                  });
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    ui.Image uiImage = frameInfo.image;

    print('Asset loaded image width=${uiImage.width} height=${uiImage.height}');

    final cursor = await image(
        assetName,
        uiImage,
        hotX,
        hotY,
        useExactAssetImage
            ? _CustomMouseCursorCreationType.exactasset
            : _CustomMouseCursorCreationType.asset,
        nativeDevicePixelRatio,
        existingCursorToUpdate: existingCursorToUpdate);

    cursor._assetBundleImageProvider = assetBundleImageProvider;
    cursor._currentAssetAwareKey = assetAwareKey;
    return cursor;
  }

  Future<void> _updateAssetToNewDpi(double newDevicePixelRatio) async {
    if (originStory != _CustomMouseCursorCreationType.asset ||
        originStory != _CustomMouseCursorCreationType.exactasset) {
      throw ('updateAssetToNewDpi() called on non asset cursor');
    }

    if (_currentAssetAwareKey != null) {
      double hotAdjustRatio = newDevicePixelRatio / nativeDevicePixelRatio;
      double hotX = hotXAtNativeDevicePixelRatio * hotAdjustRatio;
      double hotY = hotYAtNativeDevicePixelRatio * hotAdjustRatio;

      print(
          'updateAssetToNewDpi() updating by LOADING asset ${_currentAssetAwareKey!.name}');

      final rawAssetImageBytes =
          await rootBundle.load(_currentAssetAwareKey!.name);

      final rawUint8 = rawAssetImageBytes.buffer.asUint8List();

      ui.Image uiImage = await decodeImageFromList(rawUint8);

      print(
          'UPDATE Asset loaded image width=${uiImage.width} height=${uiImage.height}');

      await image(key, uiImage, hotX.round(), hotY.round(), originStory,
          newDevicePixelRatio,
          existingCursorToUpdate: this);
    }
  }

  static Future<CustomMouseCursor> icon(
    /// The icon to display. The available icons are described in [Icons].
    ///
    /// The icon can be null, in which case the widget will render as an empty
    /// space of the specified [size].
    final IconData icon, {
    /// The size of the cursor to create in logical pixels.
    /// A size X size square cursor will be created.
    ///
    /// Defaults to 32.
    ///
    double size = 32,

    /// X coordinate of the cursor's hot spot.
    int hotX = 0,

    /// Y coordinate of the cursor's hot spot.
    int hotY = 0,

    /// Native DevicePixelRatio for this size.
    /// When the DevicePixelRatio is different or changes from this size
    /// the the pointer will be scaled accordingly when
    /// CustomMousePointer.ensurePointersMatchDevicePixelRatio() is called.
    /// The user should always call CustomMousePointer.ensurePointersMatchDevicePixelRatio() from
    /// their top level widget's didChangeDependencies() handler to
    /// ensure that pointers change to device DPI dependent sizes.
    ///
    /// For example if you were specifying a size of 32 for the icon, and the
    /// DevicePixelRatio changed to 2.0, the icon would be scaled
    /// by ratio=newDevicePixelRatio/nativeDevicePixelRatio=2.0 and
    /// the icon would be scaled up to newSize=2.0x32=64 pixels.
    final double nativeDevicePixelRatio = 1.0,

    /// The fill for drawing the icon.
    ///
    /// Requires the underlying icon font to support the `FILL` [FontVariation]
    /// axis, otherwise has no effect. Variable font filenames often indicate
    /// the supported axes. Must be between 0.0 (unfilled) and 1.0 (filled),
    /// inclusive.
    ///
    /// Can be used to convey a state transition for animation or interaction.
    ///
    /// Defaults to undefined.
    ///
    /// See also:
    ///  * [weight], for controlling stroke weight.
    ///  * [grade], for controlling stroke weight in a more granular way.
    ///  * [opticalSize], for controlling optical size.
    final double? fill,

    /// The stroke weight for drawing the icon.
    ///
    /// Requires the underlying icon font to support the `wght` [FontVariation]
    /// axis, otherwise has no effect. Variable font filenames often indicate
    /// the supported axes. Must be greater than 0.
    ///
    /// Defaults to undefined.
    ///
    /// See also:
    ///  * [fill], for controlling fill.
    ///  * [grade], for controlling stroke weight in a more granular way.
    ///  * [opticalSize], for controlling optical size.
    ///  * https://fonts.google.com/knowledge/glossary/weight_axis
    final double? weight,

    /// The grade (granular stroke weight) for drawing the icon.
    ///
    /// Requires the underlying icon font to support the `GRAD` [FontVariation]
    /// axis, otherwise has no effect. Variable font filenames often indicate
    /// the supported axes. Can be negative.
    ///
    /// Grade and [weight] both affect a symbol's stroke weight (thickness), but
    /// grade has a smaller impact on the size of the symbol.
    ///
    /// Grade is also available in some text fonts. One can match grade levels
    /// between text and symbols for a harmonious visual effect. For example, if
    /// the text font has a -25 grade value, the symbols can match it with a
    /// suitable value, say -25.
    ///
    /// Defaults to undefined.
    ///
    /// See also:
    ///  * [fill], for controlling fill.
    ///  * [weight], for controlling stroke weight in a less granular way.
    ///  * [opticalSize], for controlling optical size.
    ///  * https://fonts.google.com/knowledge/glossary/grade_axis
    final double? grade,

    /// The optical size for drawing the icon.
    ///
    /// Requires the underlying icon font to support the `opsz` [FontVariation]
    /// axis, otherwise has no effect. Variable font filenames often indicate
    /// the supported axes. Must be greater than 0.
    ///
    /// For an icon to look the same at different sizes, the stroke weight
    /// (thickness) must change as the icon size scales. Optical size offers a way
    /// to automatically adjust the stroke weight as icon size changes.
    ///
    /// Defaults to undefined.
    ///
    /// See also:
    ///  * [fill], for controlling fill.
    ///  * [weight], for controlling stroke weight.
    ///  * [grade], for controlling stroke weight in a more granular way.
    ///  * https://fonts.google.com/knowledge/glossary/optical_size_axis
    final double? opticalSize,

    /// The color to use when drawing the icon.
    ///
    /// Defaults to the [Colors.black].
    ///
    ///
    final Color color = Colors.black,

    /// A list of [Shadow]s that will be painted underneath the icon.
    ///
    /// Multiple shadows are supported to replicate lighting from multiple light
    /// sources.
    ///
    /// Shadows must be in the same order for [Icon] to be considered as
    /// equivalent as order produces differing transparency.
    ///
    /// Defaults to undefined.
    final List<Shadow>? shadows,

    /// An existing cursor that should be updated instead of creating a new cursor.
    /// This is used on DevicePixelRatio changes to update the cursors backing
    /// image.
    CustomMouseCursor? existingCursorToUpdate,
  }) async {
    assert(fill == null || (0.0 <= fill && fill <= 1.0));
    assert(weight == null || (0.0 < weight));
    assert(opticalSize == null || (0.0 < opticalSize));

    _CustomMouseCursorFromIconOriginInfo iconCreationInfo =
        _CustomMouseCursorFromIconOriginInfo(
      icon: icon,
      size: size,
      hotX: hotX,
      hotY: hotY,
      nativeDevicePixelRatio: nativeDevicePixelRatio,
      fill: fill,
      weight: weight,
      opticalSize: opticalSize,
      grade: grade,
      color: color,
      shadows: shadows,
    );

    double currentDevicePixelRatio =
        _lastImageConfiguration?.devicePixelRatio ??
            WidgetsBinding.instance.window.devicePixelRatio;
    if (currentDevicePixelRatio != nativeDevicePixelRatio) {
      print(
          'On ICON creation currentDevicePixelRatio=$currentDevicePixelRatio   nativeDevicePixelRatio=$nativeDevicePixelRatio');
      print('  Must adjust size=$size   hotX=$hotX   hotY=$hotY ');
      double adjustRatio = currentDevicePixelRatio / nativeDevicePixelRatio;
      size = size * adjustRatio;
      hotX = (hotX * adjustRatio).round();
      hotY = (hotY * adjustRatio).round();
      print('  ADJUSTED adjust size=$size   hotX=$hotX   hotY=$hotY ');
    }

    ui.Image iconImage = _createImageFromIconSync(icon,
        size: size,
        color: color,
        iconFill: fill,
        iconWeight: weight,
        iconGrade: grade,
        iconOpticalSize: opticalSize,
        shadows: shadows);

    final cursor = await image(
        null,
        iconImage,
        hotX,
        hotY,
        _CustomMouseCursorCreationType.icon,
        currentDevicePixelRatio /* WE MADE image/hotX/hotY match currentDevicePixelRatio!*/,
        existingCursorToUpdate: existingCursorToUpdate);

    cursor._iconCreationInfo = iconCreationInfo;

    return cursor;
  }

  Future<void> _updateIconToNewDpi(double newDevicePixelRatio) async {
    if (originStory != _CustomMouseCursorCreationType.icon) {
      throw ('updateIconToNewDpi() called on non icon cursor');
    }
    if (_iconCreationInfo != null) {
      double lastSize = _iconCreationInfo!.size;
      double lastNativeDPR = _iconCreationInfo!.nativeDevicePixelRatio;

      double scaleRatio = newDevicePixelRatio / lastNativeDPR;
      double newSize = lastSize * scaleRatio;
      int newHotX = (_iconCreationInfo!.hotX * scaleRatio).round();
      int newHotY = (_iconCreationInfo!.hotY * scaleRatio).round();

      print(
          'updateIconToNewDpi() making icon at newSize=$newSize   (scaleRatio=$scaleRatio)');

      ui.Image iconImage = _createImageFromIconSync(_iconCreationInfo!.icon,
          size: newSize,
          color: _iconCreationInfo!.color,
          iconFill: _iconCreationInfo!.fill,
          iconWeight: _iconCreationInfo!.weight,
          iconGrade: _iconCreationInfo!.grade,
          iconOpticalSize: _iconCreationInfo!.opticalSize,
          shadows: _iconCreationInfo!.shadows);

      image(null, iconImage, newHotX, newHotY,
          _CustomMouseCursorCreationType.icon, newDevicePixelRatio,
          existingCursorToUpdate: this);
    }
  }

  /// image() create cursor from uiImage
  /// Native DevicePixelRatio for this size.
  ///
  static Future<CustomMouseCursor> image(
    String? key,
    ui.Image uiImage,
    int hotX,
    int hotY,
    _CustomMouseCursorCreationType originStory,
    double thisImagesDevicePixelRatio, {
    /// An existing cursor that should be updated instead of creating a new cursor.
    /// This is used on DevicePixelRatio changes to update the cursors backing
    /// image.
    CustomMouseCursor? existingCursorToUpdate,
  }) async {
    // KLUDGE - maybe not best place but ensure we have callbacks to detect DevicePixelRatio changes
    _setupViewsOnMetricChangedCallbacks();

    int width = uiImage.width;
    int height = uiImage.height;

    late double currentDevicePixelRatio;
    // If we have a ImageConfiguration object already from didChangeDependencies() being called
    // use that to use AssetImage to do a DPI aware loading of the pointer
    if (_lastImageConfiguration != null) {
      print(
          'Using lastImageConfiguration devicePixelRatio = ${_lastImageConfiguration?.devicePixelRatio ?? 'ImageConfiguration MISSING DEVICEPIXELRATIO'}');

      currentDevicePixelRatio = _lastImageConfiguration?.devicePixelRatio ??
          WidgetsBinding.instance.window.devicePixelRatio;
    } // else {
    currentDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    print(
        'Current currentDevicePixelRatio from WidgetsBinding! devicePixelRatio = ${currentDevicePixelRatio}');

    //}

    if (currentDevicePixelRatio != thisImagesDevicePixelRatio) {
      print(
          '!!!!!! In Image Creation and thisImagesDevicePixelRatio DPR ($currentDevicePixelRatio) != NATIVE ($thisImagesDevicePixelRatio)');
      currentDevicePixelRatio = thisImagesDevicePixelRatio;
      print(
          'RESET CURRENT TO MATCH thisImagesDevicePixelRatio FOR THIS CREATION');
    }

    late Uint8List imageBuffer;
    if (!kIsWeb && Platform.isWindows) {
      // we need to re-encode as BGRA
      imageBuffer = await _getBytesAsBGRAFromImage(uiImage);
    } else {
      // on all other platforms we ENSURE the image buffer is PNG by re-encoding
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      imageBuffer = byteData!.buffer.asUint8List();
    }

    if (existingCursorToUpdate == null) {
      // CREATING A NEW CURSOR

      // if no key was passed in we generate a unique key from md5 of image buffer.
      key ??= generateMd5(imageBuffer);

      late final String registeredKey;
      if (!kIsWeb) {
        /*
        // This was experiment on WIndows so see if we could get the OS SetThreadCursorCreationScaling()
        // function to work for automatically scaling cursor for DPR - did not work
        //WIN32//
        UISettings uisettings = UISettings();
        final cursorSize = uisettings.cursorSize;
        print(
            'uisettings cursorSize.width x height=${cursorSize.Width} x ${cursorSize.Height}');
        final systemDPI = GetDpiForSystem();
        print('systemDPI = $systemDPI');
        int prevDPI =
            SetThreadCursorCreationScaling(CURSOR_CREATION_SCALING_NONE);
        print(
            'called SetThreadCursorCreationScaling(CURSOR_CREATION_SCALING_NONE (1)) and the prev value was $prevDPI');
        */

        registeredKey =
            await _CustomMouseCursorPlatformInterface.registerCursor(key,
                imageBuffer, width, height, hotX.toDouble(), hotY.toDouble());
        assert(registeredKey == key);
      } else {
        // for the web the registeredKey *IS* the css cursor data-uri defining this cursor
        final base64Image = base64.encode(imageBuffer);

        registeredKey =
            'url("data:image/png;base64,$base64Image") $hotX $hotY, pointer';
      }
      final cursor = CustomMouseCursor._(registeredKey, originStory,
          thisImagesDevicePixelRatio, hotX, hotY, currentDevicePixelRatio);

      if (!kIsWeb) {
        cursor._dprBitmapCache[thisImagesDevicePixelRatio] =
            _CustomMouseCursorDPRBitmapCache(
                imageBuffer, width, height, hotX, hotY);
      } else {}

      _cursorCacheOfAllCreatedCursors[key] = cursor;

      return cursor;
    } else {
      key = existingCursorToUpdate.key;
      print('WE ARE in image() UPDATING the backing image key=$key ');

      // WE ARE UPDATING an existing cursor's backing image, so delete previous image and
      if (!kIsWeb) {
        // delete previous version
        _CustomMouseCursorPlatformInterface.deleteCursor(key);
        // and create new version with new dpi image
        String newRegisteredKey =
            await _CustomMouseCursorPlatformInterface.registerCursor(key,
                imageBuffer, width, height, hotX.toDouble(), hotY.toDouble());

        existingCursorToUpdate._dprBitmapCache[thisImagesDevicePixelRatio] =
            _CustomMouseCursorDPRBitmapCache(
                imageBuffer, width, height, hotX, hotY);

        assert(newRegisteredKey == key);
      } else {
        // for the web the registeredKey *IS* the css cursor data-uri defining this cursor
        final base64Image = base64.encode(imageBuffer);

        existingCursorToUpdate.key =
            'url("data:image/png;base64,$base64Image") $hotX $hotY, pointer';

        existingCursorToUpdate._dprCSSCursorCache[thisImagesDevicePixelRatio] =
            existingCursorToUpdate.key;
      }
      existingCursorToUpdate.currentCursorDevicePixelRatio =
          thisImagesDevicePixelRatio;
      return existingCursorToUpdate;
    }
  }

  // ACTUALLY make DELAY creating cursor till HERE??? -
  // todo: tmm  Currently decided this does not help in any meaningful way
  @override
  MouseCursorSession createSession(int device) =>
      _CustomMouseCursorSession(this, device);

  @override
  String get debugDescription => objectRuntimeType(this, 'CustomMouseCursor');

  /// Returns true if this cursor object is still valid and it's platform backing
  /// cursor has not been deleted.  For web it always returns true as the
  /// cursor's key is the platform definition.
  bool get isValid =>
      kIsWeb || _cursorCacheOfAllCreatedCursors.containsKey(key);

  /// For cursors that have a backing platform cursor this frees that cursor and
  /// removes this cursor from the [_cursorCacheOfAllCreatedCursors].
  void dispose() {
    if (!kIsWeb) {
      _CustomMouseCursorPlatformInterface.deleteCursor(key);
      _cursorCacheOfAllCreatedCursors.remove(key);
    }
  }

  /// Disposes of all created cursors.
  static void disposeAll() {
    print('disposeAll() called');
    for (final cursor in _cursorCacheOfAllCreatedCursors.values) {
      print('Calling dispose on ${cursor.key}');
      cursor.dispose();
    }
    _cursorCacheOfAllCreatedCursors.clear();
  }

  static ImageConfiguration? _lastImageConfiguration;
  static double _lastEnsuredDevicePixelRatio = 0;

  /// Call from
  static void ensurePointersMatchDevicePixelRatio(BuildContext? context) async {
    if (_getDevicePixelRatioFromView() == _lastEnsuredDevicePixelRatio) {
      print(
          'lastEnsuredDevicePixelRatio IMMEDIATE RETURN already $_lastEnsuredDevicePixelRatio');
      return;
    }

    print('ensurePointersMatchDevicePixelRatio() entered');
    _lastImageConfiguration =
        _createLocalImageConfigurationWithOrWithoutContext(context: context);

    double currentDevicePixelRatio =
        _lastImageConfiguration?.devicePixelRatio ??
            _getDevicePixelRatioFromView();

    print('Current currentDevicePixelRatio= ${currentDevicePixelRatio}');

    print(
        'createLocalImageConfiguration  devicePixelRatio=${_lastImageConfiguration!.devicePixelRatio}  platform=${_lastImageConfiguration!.platform}');

    String assetName = 'assets/cursors/startrek_mousepointer.png';
    AssetImage assetImage = AssetImage(assetName);
    if (_lastImageConfiguration != null) {
      AssetBundleImageKey assetAwareKey =
          await assetImage.obtainKey(_lastImageConfiguration!);

      print(
          'Using lastImageConfiguration got name=${assetAwareKey.name} scale=${assetAwareKey.scale}');
    }

    for (final cursor in _cursorCacheOfAllCreatedCursors.values) {
      print(
          'Checking DPR for ${cursor.key}  cursor.originStory=${cursor.originStory}');
      if (cursor.currentCursorDevicePixelRatio != currentDevicePixelRatio) {
        print(
            '  Current DPI is different than cursors DPI!!!    cursor.currentCursorDevicePixelRatio=${cursor.currentCursorDevicePixelRatio} != currentDevicePixelRatio=${currentDevicePixelRatio}');

        // First we check this cursors DPR cache
        if (!kIsWeb) {
          if (cursor._dprBitmapCache.containsKey(currentDevicePixelRatio)) {
            print(
                '    Getting DPR $currentDevicePixelRatio from cursors BITMAP cache!!!');
            final cachedInfo = cursor._dprBitmapCache[currentDevicePixelRatio]!;
            // WE ARE UPDATING an existing cursor's backing image, so delete previous image and
            _CustomMouseCursorPlatformInterface.deleteCursor(cursor.key);
            // get new version with new dpi image
            _CustomMouseCursorPlatformInterface.registerCursor(
                cursor.key,
                cachedInfo.imageBuffer,
                cachedInfo.width,
                cachedInfo.height,
                cachedInfo.hotX.toDouble(),
                cachedInfo.hotY.toDouble());
            cursor.currentCursorDevicePixelRatio = currentDevicePixelRatio;
            continue;
          }
        } else {
          if (cursor._dprCSSCursorCache.containsKey(currentDevicePixelRatio)) {
            print(
                '    Getting DPR $currentDevicePixelRatio from cursors WEB cache!!!');
            cursor.key = cursor._dprCSSCursorCache[currentDevicePixelRatio]!;
            cursor.currentCursorDevicePixelRatio = currentDevicePixelRatio;
            continue;
          }
        }

        // not in cache, so go create new cursor bitmap for this DPR
        if (cursor.originStory == _CustomMouseCursorCreationType.asset ||
            cursor.originStory == _CustomMouseCursorCreationType.exactasset) {
          print(
              '  Asset cursor ${cursor.key} cursor.originStory=${cursor.originStory} assetImage=${cursor._assetBundleImageProvider}');

          if (cursor._assetBundleImageProvider == null) {
            // We need to get this cursors AssetImage, it couldn't be created when it was
            cursor._assetBundleImageProvider = AssetImage(assetName);

            //KLUDGE do we ever use this cursor.currentAssetAwareKey?????
            cursor._currentAssetAwareKey = await cursor
                ._assetBundleImageProvider!
                .obtainKey(_lastImageConfiguration!);
          }
          if (cursor._assetBundleImageProvider != null &&
              _lastImageConfiguration != null) {
            AssetBundleImageKey newAssetAwareKey = await cursor
                ._assetBundleImageProvider!
                .obtainKey(_lastImageConfiguration!);

            print(
                '      WE SHOULD SWITCH origin IMAGE TO name=${newAssetAwareKey.name} scale=${newAssetAwareKey.scale}');
            print(
                '         previous AssetAwareKey =${cursor._currentAssetAwareKey!.name} scale=${cursor._currentAssetAwareKey!.scale}');
            cursor._currentAssetAwareKey = newAssetAwareKey;

            print(
                '    calling cursor.updateAssetToNewDpi( $currentDevicePixelRatio );');

            await cursor._updateAssetToNewDpi(currentDevicePixelRatio);
          }
        } else if (cursor.originStory == _CustomMouseCursorCreationType.icon) {
          print(
              '      calling cursor.updateIconToNewDpi( $currentDevicePixelRatio );');
          cursor._updateIconToNewDpi(currentDevicePixelRatio);
        }
      }
    }
    _lastEnsuredDevicePixelRatio = currentDevicePixelRatio;
  }

  /// Our onMetricsChanged() callback
  /// Curiously this takes no args and we have to detect where it came from OURSELVES ??
  /// todo: tmm  clean this up once flutter mutliwindow stuff is complete
  static void onMetricsChanged() {
    ensurePointersMatchDevicePixelRatio(null);
  }

  static ImageConfiguration _createLocalImageConfigurationWithOrWithoutContext(
      {BuildContext? context}) {
    if (context != null) {
      _lastImageConfiguration = createLocalImageConfiguration(context);
    } else {
      // MAKE our own default ImageConfiguration() with devicePixelRatio from PlatformDispatcher
      _lastImageConfiguration = ImageConfiguration(
        bundle: rootBundle,
        devicePixelRatio: _getDevicePixelRatioFromView(),
        locale: PlatformDispatcher.instance.locale,
        textDirection: TextDirection.ltr,
        size: null,
        platform: defaultTargetPlatform,
      );
    }
    return _lastImageConfiguration!;
  }

  static bool _noOnMetricsChangedHook = false;

  static set noOnMetricsChangedHook(bool newVal) {
    if (!_noOnMetricsChangedHook && newVal && _onMetricChangedCallbackSet) {
      throw ('CustomMouseCursor aleady hooked onMetricsChanged() - set noOnDeviceMetricsHook BEFORE creating cursors');
    }
    _noOnMetricsChangedHook = true;
  }

  static const _usePlatformDipatcherOnMetricsChanged = true;
  static bool _onMetricChangedCallbackSet = false;

  static bool _multiWindowsSetupDetected = false;
  static double _lastDevicePixelRatio = 1.0;
  static const bool _usePreFlutter39 = false;

  static double _getDevicePixelRatioFromView() {
    if (_usePreFlutter39) {
      // deprecated way to get pixel ratio
      _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      return _lastDevicePixelRatio;
    }

    // Flutter 3.9
    if (PlatformDispatcher.instance.implicitView == null) {
      _multiWindowsSetupDetected = true;
      throw ('CustomMouseCursor detected null PlatformDispatcher.instance.implicitView which means Multiple Window Environment');
    }

    print(
        'getDevicePixelRatioFromView() called    :  usePlatformDipatcherOnMetricsChanged=$_usePlatformDipatcherOnMetricsChanged');
    if (_usePlatformDipatcherOnMetricsChanged) {
      _lastDevicePixelRatio =
          PlatformDispatcher.instance.implicitView!.devicePixelRatio;
    } else {
      // look at all views - verify that if there are >1 they all have same devicePixelRatio
      //  This of course will not always be true, but we THROW on it because we need to develop and
      //  test for mulitple window/views ONCE IT IS IMPLENTED IN FLUTTER -
      //  it is not yet. This is just to FORCE REVISTING THIS once it is. --tmm
      // TODO: tmm  Finish multi view/window support once it is implemented in flutter
      double? foundDevicePixelRatio;
      for (final view in WidgetsBinding.instance.platformDispatcher.views) {
        print(
            'View is DPR ${view.devicePixelRatio}   view.viewId=${view.viewId}');
        if (foundDevicePixelRatio == null) {
          foundDevicePixelRatio = view.devicePixelRatio;
        } else {
          // VERIFY THEY ARE ALL SAME devicePixelRatio
          if (view.devicePixelRatio != foundDevicePixelRatio) {
            throw ('Difference devicePixelRatio found on different views - WE HAVE NOT TESTED/DEVELOPED for this yet.');
          }
        }
      }
      if (foundDevicePixelRatio == null) {
        throw ('getDevicePixelRatioFromView() did not find views/devicePixelRatio');
      }
      _lastDevicePixelRatio = foundDevicePixelRatio;
    }
    print('  RETURNING lastDevicePixelRatio=$_lastDevicePixelRatio');
    return _lastDevicePixelRatio;
  }

  static void _setupViewsOnMetricChangedCallbacks() {
    if (!_onMetricChangedCallbackSet && !_noOnMetricsChangedHook) {
      _onMetricChangedCallbackSet = true;
      print(
          'setupViewsOnMetricChangedCallbacks() called and BEING SET UP usePlatformDipatcherOnMetricsChanged=$_usePlatformDipatcherOnMetricsChanged');
      if (_usePlatformDipatcherOnMetricsChanged) {
        // Just use platformDispatcher instance
        WidgetsBinding.instance.platformDispatcher.onMetricsChanged = () {
          print(
              'onMetricsChanged() SINGLE instance.platformDispatcher() version!!!!!');
          onMetricsChanged();
        };
      } else {
        // TODO: tmm  properly develop/test this once multiple windows/views is implemented in flutter
        // put the callback on ALL views
        for (final view in WidgetsBinding.instance.platformDispatcher.views) {
          view.platformDispatcher.onMetricsChanged = () {
            print('view.platformdispatcher.onMetricsChanged() !!!!!');
            print(
                'View is DPR ${view.devicePixelRatio}   view.viewId=${view.viewId}');
            onMetricsChanged();
          };
        }
      }
    }
  }
}

class _CustomMouseCursorSession extends MouseCursorSession {
  _CustomMouseCursorSession(CustomMouseCursor cursor, int device)
      : super(cursor, device);

  @override
  CustomMouseCursor get cursor => super.cursor as CustomMouseCursor;

  @override
  Future<void> activate() async {
    if (kIsWeb) {
      // for the web the cursor key is a CSS cursor data-uri definition
      return SystemChannels.mouseCursor.invokeMethod<void>(
        'activateSystemCursor',
        <String, dynamic>{
          'device': device,
          'kind': cursor.key,
        },
      );
    } else {
      if (cursor.isValid) {
        await _CustomMouseCursorPlatformInterface.setSystemCursor(cursor.key);
      } else {
        throw ('An attempt to use a CustomMouseCursor object (${cursor.key}) which previosuly had dispose() called.');
      }
    }
  }

  @override
  void dispose() {}
}

/// The platform interface either the flutter engine (windows) or our platform plugin channels for macOS and linux
class _CustomMouseCursorPlatformInterface {
  static const channel = SystemChannels.mouseCursor;
  static const createCursorKey = "createCustomCursor";
  static const setCursorMethod = "setCustomCursor";
  static const deleteCursorMethod = "deleteCustomCursor";

  _CustomMouseCursorPlatformInterface._();
  //static _CustomMouseCursorPlatformInterface instance = _CustomMouseCursorPlatformInterface._();

  static Future<String> registerCursor(
    String name,
    Uint8List buffer,
    int width,
    int height,
    double hotX,
    double hotY,
  ) async {
    final cursorName = await _getMethodChannel()
        .invokeMethod<String>(_getMethod(createCursorKey), <String, dynamic>{
      'name': name,
      'buffer': buffer,
      'width': width,
      'height': height,
      'hotX': hotX,
      'hotY': hotY,
    });
    assert(cursorName == name);
    return cursorName!;
  }

  static Future<void> deleteCursor(String name) async {
    await _getMethodChannel()
        .invokeMethod(_getMethod(deleteCursorMethod), {"name": name});
  }

  static Future<void> setSystemCursor(String name) async {
    await _getMethodChannel()
        .invokeMethod(_getMethod(setCursorMethod), {"name": name});
  }

  static MethodChannel _getMethodChannel() {
    if (Platform.isWindows) {
      return SystemChannels.mouseCursor;
    } else {
      return const MethodChannel('custom_mouse_cursor');
    }
  }

  static String _getMethod(String method) {
    if (Platform.isWindows) {
      return "$method/windows";
    } else {
      return method;
    }
  }
}

// todo: tmm  create a random unique id and not include crypto or take time to do md5
String generateMd5(Uint8List input) {
  return md5.convert(input).toString();
}

/// Returns Uint8List of the ui.Image's pixels in BGRA format
Future<Uint8List> _getBytesAsBGRAFromImage(ui.Image image) async {
  int width = image.width;
  int height = image.height;
  final rgbaBD = await image.toByteData(format: ImageByteFormat.rawRgba);
  final rgba = rgbaBD?.buffer.asUint8List();
  return _getRGBABytesAsBGRA(rgba!, width, height);
}

/// Convert RGBA formmated Uint8List into BGRA format.
/// (This format is needed for creating cursors on windows platform)
Uint8List _getRGBABytesAsBGRA(Uint8List rgba, int width, int height) {
  final length = width * height * 4;
  assert(rgba.lengthInBytes == length && rgba.lengthInBytes % 4 == 0);
  final bgra = Uint8List(length);
  for (var i = 0; i < length; i += 4) {
    bgra[i + 0] = rgba[i + 2];
    bgra[i + 1] = rgba[i + 1];
    bgra[i + 2] = rgba[i + 0];
    bgra[i + 3] = rgba[i + 3];
  }
  return bgra;
}

/// Creates am image from the specified icon.  This is essentially identical parameters
/// to the Icon() flutter widget but creates a ui.Image instead.
ui.Image _createImageFromIconSync(IconData icon,
    {double size = 32,
    Color color = Colors.black,
    double? iconFill,
    double? iconWeight,
    double? iconGrade,
    double? iconOpticalSize,
    List<Shadow>? shadows}) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  //final Paint paint = Paint()..color = Colors.red;
  //canvas.drawPaint(paint);

  final textSpan = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontVariations: <FontVariation>[
        if (iconFill != null) FontVariation('FILL', iconFill),
        if (iconWeight != null) FontVariation('wght', iconWeight),
        if (iconGrade != null) FontVariation('GRAD', iconGrade),
        if (iconOpticalSize != null) FontVariation('opsz', iconOpticalSize),
      ],
      inherit: false,
      color: color,
      fontSize: size,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      shadows: shadows,
    ),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset.zero);

  final Picture picture = recorder.endRecording();

  late final ui.Image uiimage;
  try {
    uiimage = picture.toImageSync(
      size.floor(),
      size.floor(),
    );
  } finally {
    picture.dispose();
  }
  return uiimage;
}
