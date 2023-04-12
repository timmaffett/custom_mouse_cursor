import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//NOLONGERUSERMD5//import 'package:crypto/crypto.dart';

class _Logger {
  static void log(String message) {}
}

/// The [CustomMouseCursor] class allows the user to create custom system mouse cursors from various
/// sources.  See [MouseCursor] for more information on using cursors within flutter.
/// [CustomMouseCursor] cursor objects can be used just as you would any [SystemMouseCursor] built in cursor
/// from [SystemMouseCursors].
///
/// ## Using cursors
///
/// A [CustomMouseCursor] object is used by being assigned to a [MouseRegion] or
/// another widget that exposes the [MouseRegion] API, such as
/// [InkResponse.mouseCursor].  This is behavior is identical for any [MouseCursor]
/// subclass.
///
/// The [asset] and [exactasset] static methods can be use to create custom cursors from flutter
/// assets.
/// The [icon] static method can be used to create custom cursors from any flutter [IconData].
/// There is a [image] static method exposed that is intended for ONLY power users to create icon's from
/// [ui.Image] objects.  These cursors would not be devicePixelRatio responsive.  That would is
/// left to the user in when using this method.
///
///
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
  /// If [originStory]==[_CustomMouseCursorCreationType.asset] then [_assetBundleImageProvider]
  /// contains the [AssetImage] used in its creation (and used for updating on DevicePixelRatio changes).
  /// If [originStory]==[_CustomMouseCursorCreationType.exactasset] then [_assetBundleImageProvider]
  /// contains the [ExactAssetImage] used in its creation (and used for updating on DevicePixelRatio changes).
  /// If [originStory]==[_CustomMouseCursorCreationType.icon] then [_iconCreationInfo] will hold
  /// information on how to regenerate the icon cursor on DevicePixelRatio changes.
  /// If [originStory]==[_CustomMouseCursorCreationType.image] then there will be
  /// no automatic handling of the cursore for DevicePixelRatio changes.
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
  /// This applys only to desktop native platforms (windows, macOS, and linux).
  /// On web systems the [key] holds a cursor definition that includes support for all
  /// encountered DevicePixelRatios - and this will simply hold the device pixel ratio
  /// that was last encountered.
  double currentCursorDevicePixelRatio;

  /// If [originStory]==[_CustomMouseCursorCreationType.asset] then this contains the
  /// [AssetImage] used in its created (and used for updating on DevicePixelRatio changes).
  /// If [originStory]==[_CustomMouseCursorCreationType.exactasset] then this contains the
  /// [ExactAssetImage] used in its created (and used for updating on DevicePixelRatio changes).
  AssetBundleImageProvider? _assetBundleImageProvider;

  //NOLONGER//AssetBundleImageKey? _currentAssetAwareKey;

  /// Used to store the unchanged orginal assetName passed to asset() or exactasset().
  //OLDWAY//String? _originalUnchangedAssetName;

  /// This was exactAssetDevicePixelRatio passed to exactasset() - otherwise it will match
  /// nativeDevicePixelRatio.
  double? _exactAssetDevicePixelRatio;

  _CustomMouseCursorFromIconOriginInfo? _iconCreationInfo;

  /// This holds cache of the bitmaps/info we have made for this bitmap for different
  /// DevicePixelRatio monitors.
  final Map<double, _CustomMouseCursorDPRBitmapCache> _dprBitmapCache = {};

/* NO LONGER NEEDED
  /// This holds cache of the css cursor definitions for web platforms.
  /// Once we have created a web css cursor we cache it here for reuse
  /// when switching between monitors with different DevicePixelRatios.
  final Map<double, String> _dprCSSCursorCache = {};
*/

  /// Whether to use OLD FLUTTER deprecated APIS - this is required for using stable channel ?
  static const bool _oldFlutterAPIS = false;

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

  /// Creates a cursor with the image obtained from an exact asset
  /// bundle. The key for the image is given by the [assetName] argument.
  /// Using this method allows the pixel-density-aware asset resolution to be avoided.
  ///
  /// This method works the same as [asset] but allows the user to specify
  /// the *exact* image resource that they would like to load.  This bypasses
  /// the considerstion of devicePixelRatio when loading the image and instead
  /// loads the exact asset resource specified by the [assetName].
  /// (Internally this is implemented with a call to [asset] with the [useExactAssetImage]
  /// argument set to true).
  ///
  /// The [package] argument must be non-null when displaying an image from a
  /// package and null otherwise. See the `Assets in packages` section for
  /// details.
  ///
  /// If the [bundle] argument is omitted or null, then the
  /// [DefaultAssetBundle] will be used.
  ///
  /// ## Assets in packages
  ///
  /// To create the widget with an asset from a package, the [package] argument
  /// must be provided. For instance, suppose a package called `my_icons` has
  /// `icons/heart.png` .
  ///
  /// {@tool snippet}
  /// Then to display the image, use:
  ///
  /// ```dart
  /// Image.asset('icons/heart.png', package: 'my_icons')
  /// ```
  /// {@end-tool}
  ///
  /// Assets used by the package itself should also be displayed using the
  /// [package] argument as above.
  ///
  /// If the desired asset is specified in the `pubspec.yaml` of the package, it
  /// is bundled automatically with the app. In particular, assets used by the
  /// package itself must be specified in its `pubspec.yaml`.
  ///
  /// A package can also choose to have assets in its 'lib/' folder that are not
  /// specified in its `pubspec.yaml`. In this case for those images to be
  /// bundled, the app has to specify which ones to include. For instance a
  /// package named `fancy_backgrounds` could have:
  ///
  ///     lib/backgrounds/background1.png
  ///     lib/backgrounds/background2.png
  ///     lib/backgrounds/background3.png
  ///
  /// To include, say the first image, the `pubspec.yaml` of the app should
  /// specify it in the assets section:
  ///
  /// ```yaml
  ///   assets:
  ///     - packages/fancy_backgrounds/backgrounds/background1.png
  /// ```
  ///
  /// The `lib/` is implied, so it should not be included in the asset path.
  ///
  /// See also:
  ///
  ///  * [ExactAssetImage], (this is used with a scale=1.0 for loading the image asset).
  ///  * <https://flutter.dev/assets-and-images/>, an introduction to assets in
  ///    Flutter.
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

    /// This argument is passed to [ExactAssetImage]. If the `bundle` argument is omitted or null, then the
    /// [DefaultAssetBundle] will be used.
    AssetBundle? bundle,

    /// This argument is passed to [ExactAssetImage]. Assets used by the package itself should also be displayed using the
    /// [package] argument as above.
    String? package,
  }) async {
    return asset(assetName,
        hotX: hotX,
        hotY: hotY,
        nativeDevicePixelRatio: nativeDevicePixelRatio,
        existingCursorToUpdate: existingCursorToUpdate,
        context: context,
        bundle: bundle,
        useExactAssetImage: true);
  }

  /// Creates a cursor with the image obtained from an asset
  /// bundle. The key for the image is given by the [assetName] argument.
  ///
  /// The [package] argument must be non-null when displaying an image from a
  /// package and null otherwise. See the `Assets in packages` section for
  /// details.
  ///
  /// If the [bundle] argument is omitted or null, then the
  /// [DefaultAssetBundle] will be used.
  ///
  /// By default, the pixel-density-aware asset resolution will be attempted. In
  /// addition:
  ///
  /// {@tool snippet}
  ///
  /// Suppose that the project's `pubspec.yaml` file contains the following:
  ///
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - images/cat.png
  ///     - images/2x/cat.png
  ///     - images/3.5x/cat.png
  /// ```
  /// {@end-tool}
  ///
  /// On a screen with a device pixel ratio of 2.0, the following widget would
  /// render the `images/2x/cat.png` file:
  ///
  /// ```dart
  /// Image.asset('images/cat.png')
  /// ```
  ///
  /// This corresponds to the file that is in the project's `images/2x/`
  /// directory with the name `cat.png` (the paths are relative to the
  /// `pubspec.yaml` file).
  ///
  /// On a device with a 4.0 device pixel ratio, the `images/3.5x/cat.png` asset
  /// would be used. On a device with a 1.0 device pixel ratio, the
  /// `images/cat.png` resource would be used.
  ///
  /// The `images/cat.png` image can be omitted from disk (though it must still
  /// be present in the manifest). If it is omitted, then on a device with a 1.0
  /// device pixel ratio, the `images/2x/cat.png` image would be used instead.
  ///
  ///
  /// ## Assets in packages
  ///
  /// To create the widget with an asset from a package, the [package] argument
  /// must be provided. For instance, suppose a package called `my_icons` has
  /// `icons/heart.png` .
  ///
  /// {@tool snippet}
  /// Then to display the image, use:
  ///
  /// ```dart
  /// Image.asset('icons/heart.png', package: 'my_icons')
  /// ```
  /// {@end-tool}
  ///
  /// Assets used by the package itself should also be displayed using the
  /// [package] argument as above.
  ///
  /// If the desired asset is specified in the `pubspec.yaml` of the package, it
  /// is bundled automatically with the app. In particular, assets used by the
  /// package itself must be specified in its `pubspec.yaml`.
  ///
  /// A package can also choose to have assets in its 'lib/' folder that are not
  /// specified in its `pubspec.yaml`. In this case for those images to be
  /// bundled, the app has to specify which ones to include. For instance a
  /// package named `fancy_backgrounds` could have:
  ///
  ///     lib/backgrounds/background1.png
  ///     lib/backgrounds/background2.png
  ///     lib/backgrounds/background3.png
  ///
  /// To include, say the first image, the `pubspec.yaml` of the app should
  /// specify it in the assets section:
  ///
  /// ```yaml
  ///   assets:
  ///     - packages/fancy_backgrounds/backgrounds/background1.png
  /// ```
  ///
  /// The `lib/` is implied, so it should not be included in the asset path.
  ///
  ///
  /// See also:
  ///
  ///  * [AssetImage], which is used to implement the behavior when the scale is
  ///    omitted.
  ///  * [ExactAssetImage], which is used to implement the behavior when the
  ///    scale is present.
  ///  * <https://flutter.dev/assets-and-images/>, an introduction to assets in
  ///    Flutter.
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

    /// This argument is passed to [AssetImage]. If the `bundle` argument is omitted or null, then the
    /// [DefaultAssetBundle] will be used.
    AssetBundle? bundle,

    /// This argument is passed to [AssetImage]. Assets used by the package itself should also be displayed using the
    /// [package] argument as above.
    String? package,
  }) async {
    //OBSOLETE//final originalUnchangedAssetName = assetName;
    double exactAssetDevicePixelRatio = nativeDevicePixelRatio;
    _Logger.log(
        '\n.\n:\n;\n,\n${useExactAssetImage ? 'EXACT' : ''}Asset() assetName=$assetName useExactAssetImage=$useExactAssetImage nativeDevicePixelRatio=$nativeDevicePixelRatio existingCursorToUpdate=$existingCursorToUpdate');
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
          ? ExactAssetImage(assetName, bundle: bundle, package: package)
          : AssetImage(assetName, bundle: bundle, package: package);
      assetAwareKey =
          await assetBundleImageProvider.obtainKey(_lastImageConfiguration!);
      _Logger.log(
          '  _lastImageConfiguration returned DPR of ${_lastImageConfiguration!.devicePixelRatio} for system');
      _Logger.log(
          '  assetAwareKey was obtainKey`ed() to be ${assetAwareKey.name} scale=${assetAwareKey.scale}');

      if (nativeDevicePixelRatio != 1.0 && assetAwareKey.scale == 1.0) {
        // WE were told that the 1.0 is actually [nativeDevicePixelRatio] SO USE THAT
        //  (ExactImageAsset() will always return scale of 1.0)
        rescaleRatioRequiredForImage =
            _lastImageConfiguration!.devicePixelRatio! / nativeDevicePixelRatio;
        _Logger.log('  ASSETAWAREKET SCALE==1.0 SPECIAL CASE');
        _Logger.log(
            '  $nativeDevicePixelRatio was PASSED for native - but then _lastImageConfiguration!.devicePixelRatio=${_lastImageConfiguration!.devicePixelRatio} and assetAwareKey.scale=${assetAwareKey.scale}');
        _Logger.log(
            '  made  rescaleRatioRequiredForImage=$rescaleRatioRequiredForImage');
      } else {
        // At this point it has chosen *SOME* scale of image to use - this MIGHT NOT BE the devicePixelRatio exactly,
        //  so we will need to scale to that..
        rescaleRatioRequiredForImage =
            _lastImageConfiguration!.devicePixelRatio! / assetAwareKey.scale;
      }

      _Logger.log(
          '  Using lastImageConfiguration got rescaleRatioRequiredForImage=$rescaleRatioRequiredForImage  name=${assetAwareKey.name} scale=${assetAwareKey.scale}');
      if (nativeDevicePixelRatio !=
          _lastImageConfiguration!.devicePixelRatio!) {
        _Logger.log(
            '  CHANGING NATIVE PIXEL RATIO (OLD DPR=$nativeDevicePixelRatio hotX=$hotX hotY=$hotY)');
        double adjustHotsToNativeDPRChange =
            _lastImageConfiguration!.devicePixelRatio! / nativeDevicePixelRatio;
        hotX = (hotX * adjustHotsToNativeDPRChange).round();
        hotY = (hotY * adjustHotsToNativeDPRChange).round();
        nativeDevicePixelRatio = _lastImageConfiguration!.devicePixelRatio!;
        if (!useExactAssetImage) {
          exactAssetDevicePixelRatio = nativeDevicePixelRatio;
        }
        _Logger.log(
            '  UPDATED values DPR=$nativeDevicePixelRatio hotX=$hotX hotY=$hotY   exactAssetDevicePixelRatio=$exactAssetDevicePixelRatio');
      }
      //
      assetName = assetAwareKey.name;
    } else {
      // THIS CASE SHOULD NEVER BE ABLE TO HAPPEN
      // todo: tmm  CLEAN THIS AND REMOVE THIS CODE
      double currentDevicePixelRatio;
      currentDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      _Logger.log(
          '  In asset() Loading but lastImageConfiguration WAS NULL and currentDevicePixelRatio=$currentDevicePixelRatio');
      _Logger.log('  WILL NOT START WITH DPI AssetImage() load');
      throw ('Unknown DevicePixelRatio in asset');
    }

    // NOW we have decide on the name we will use then check for existing cursor
    if (_cursorCacheOfAllCreatedCursors.containsKey(assetName)) {
      _Logger.log('  Found cursor in cache with assetname =$assetName');
      return _cursorCacheOfAllCreatedCursors[assetName]!;
    }

    // and load the asset
    final rawAssetImageBytes = await rootBundle.load(assetName);

    final rawUint8 = rawAssetImageBytes.buffer.asUint8List();

    final uiImage = await _createUIImageFromUint8ListBufferPossiblyScale(
        rawUint8,
        rescaleRatioRequiredForImage: rescaleRatioRequiredForImage);
/*
    //OLDWAY//
    ui.Image? uiImage;
    if(_oldFlutterAPIS) {
      // Flutter deprecated version
      uiImage = await decodeImageFromList(rawUint8);
      if(rescaleRatioRequiredForImage!=1.0) {
        final ui.Codec codec = await PaintingBinding.instance
          .instantiateImageCodec(
            rawUint8,
            cacheWidth:( uiImage.width * rescaleRatioRequiredForImage).round(),
            cacheHeight:(uiImage.height * rescaleRatioRequiredForImage).round(),
            allowUpscaling:(rescaleRatioRequiredForImage>1.0) );  
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        uiImage = frameInfo.image;
      }        
    } else {
      // Flutter non deprecated version
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
      uiImage = frameInfo.image;
    }
  */
    _Logger.log(
        '  Loaded Asset image width=${uiImage.width} height=${uiImage.height}');

    final cursor = await image(uiImage, hotX, hotY, nativeDevicePixelRatio,
        key: assetName,
        originStory: useExactAssetImage
            ? _CustomMouseCursorCreationType.exactasset
            : _CustomMouseCursorCreationType.asset,
        existingCursorToUpdate: existingCursorToUpdate);

    cursor._assetBundleImageProvider = assetBundleImageProvider;
    //NOLONGER//cursor._currentAssetAwareKey = assetAwareKey;
    //OLDWAY//cursor._originalUnchangedAssetName = originalUnchangedAssetName;
    cursor._exactAssetDevicePixelRatio = exactAssetDevicePixelRatio;

    _Logger.log(
        '  ALMOST DONE ABOUT TO CHECK _createDevicePixelRatio1xVersion IS WEB=$kIsWeb  _useURLDataURICursorCSS=$_useURLDataURICursorCSS  nativeDevicePixelRatio=$nativeDevicePixelRatio');
    if (kIsWeb && _useURLDataURICursorCSS && nativeDevicePixelRatio != 1.0) {
      // For web platform when using legacy URL datauri css cursors we need to always include
      // a 1.0 DPR version of the cursor.
      await _createDevicePixelRatio1xVersion(cursor);
    }

    return cursor;
  }

  /// This is similar to asset() but for UPDATING a cursor with an additional devicePixelRatio version.
  /// If the cursor was created with asset() then AssetImage() is used to get the closest image to the
  /// requested [newDevicePixelRatio], otherwise ExactAssetImage() used and the same asset used original is
  /// used again.  The loaded image is scaled to be the exact DPR requested by [newDevicePixelRatio] if
  /// necessary.
  Future<void> _updateAssetToNewDpi(double newDevicePixelRatio) async {
    if (originStory != _CustomMouseCursorCreationType.asset &&
        originStory != _CustomMouseCursorCreationType.exactasset) {
      throw ('\n!\n_updateAssetToNewDpi() called on non asset cursor (${originStory} key=$key)');
    }

    bool useExactAssetImage =
        (originStory == _CustomMouseCursorCreationType.exactasset);
    //OLDWAY//AssetBundleImageProvider? assetBundleImageProvider;
    AssetBundleImageKey? assetAwareKey;
    double rescaleRatioRequiredForImage = 0;
    // call and get an ImageConfiguration if we don't have one yet
    final forcedImageConfig =
        _createLocalImageConfigurationWithOrWithoutContext(
            forceDevicePixelRatio: newDevicePixelRatio);

    //OLDWAY//assetBundleImageProvider = useExactAssetImage
    //OLDWAY//    ? ExactAssetImage(_originalUnchangedAssetName!)
    //OLDWAY//    : AssetImage(_originalUnchangedAssetName!);

    AssetBundleImageProvider assetBundleImageProvider =
        _assetBundleImageProvider!;
    assetAwareKey = await assetBundleImageProvider.obtainKey(forcedImageConfig);
    _Logger.log(
        '  forcedImageConfig returned DPR of ${forcedImageConfig.devicePixelRatio} for system');
    _Logger.log(
        '  assetAwareKey was obtainKey`ed() to be ${assetAwareKey.name} scale=${assetAwareKey.scale}');

    if (useExactAssetImage &&
        nativeDevicePixelRatio != 1.0 &&
        assetAwareKey.scale == 1.0) {
      // During EXACTASSET were told that the 1.0 is actually [nativeDevicePixelRatio] SO USE THAT
      //  (ExactImageAsset() will always return scale of 1.0)
      rescaleRatioRequiredForImage =
          newDevicePixelRatio / _exactAssetDevicePixelRatio!;
      _Logger.log('  ASSETAWAREKET SCALE==1.0 SPECIAL CASE');
      _Logger.log(
          '  newDevicePixelRatio=$newDevicePixelRatio (orginally we were told nativeDevicePixelRatio=$nativeDevicePixelRatio) was PASSED for native - but then newDevicePixelRatio=${newDevicePixelRatio} and assetAwareKey.scale=${assetAwareKey.scale}');
      _Logger.log(
          '  made  rescaleRatioRequiredForImage=$rescaleRatioRequiredForImage');
    } else {
      // At this point it has chosen *SOME* scale of image to use - this MIGHT NOT BE the devicePixelRatio exactly,
      //  so we will need to scale to that..
      rescaleRatioRequiredForImage = newDevicePixelRatio / assetAwareKey.scale;
    }

    // HOT SPOTS where orginally STORED at [nativeDevicePixelRatio] DPR (which may have changed from what user
    // passed to original asset()/exactasset() call), so we must adjust them with [nativeDevicePixelRatio]
    // from there to the [newDevicePixelRatio]
    double adjustHotSpotRatio = newDevicePixelRatio / nativeDevicePixelRatio;
    double hotX = hotXAtNativeDevicePixelRatio * adjustHotSpotRatio;
    double hotY = hotYAtNativeDevicePixelRatio * adjustHotSpotRatio;

    _Logger.log(
        '  _updateAssetToNewDpi() updating by LOADING asset ${assetAwareKey.name} scale=${assetAwareKey.scale} rescaleRatioRequiredForImage=$rescaleRatioRequiredForImage adjusted adjustHotSpotRatio=$adjustHotSpotRatio hotX=$hotX hotY=$hotY');

    final rawAssetImageBytes = await rootBundle.load(assetAwareKey.name);

    final rawUint8 = rawAssetImageBytes.buffer.asUint8List();

    final uiImage = await _createUIImageFromUint8ListBufferPossiblyScale(
        rawUint8,
        rescaleRatioRequiredForImage: rescaleRatioRequiredForImage);
    /*  //OLDWAY//ui.Image uiImage = await decodeImageFromList(rawUint8);
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
*/
    _Logger.log(
        '  _updateAssetToNewDpi() UPDATE Asset loaded image width=${uiImage.width} height=${uiImage.height}');
    _Logger.log(
        '  calling image() with EXISTING ASSET CURSOR newDevicePixelRatio=$newDevicePixelRatio');
    await image(uiImage, hotX.round(), hotY.round(), newDevicePixelRatio,
        key: key, originStory: originStory, existingCursorToUpdate: this);
  }

  /// Creates a custom mouse cursor with a glyph from a font described in
  /// an [IconData] such as material's predefined [IconData]s in [Icons].
  ///
  /// The size (in logical pixels) of the icon used for the cursor is specified
  /// with the [size] argument.
  /// The hot spot location (in logical pixels) is specified with the
  /// [hotX] and [hotY] arguments.
  ///
  /// The appearance of the icon can be further customized with the
  /// [color], [fill], [weight], [opticalSize] and [shadows] arguments.
  ///
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

/*OBSOLETE
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
*/
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
      sizeInLogicalPixels: size,
      hotXInLogicalPixels: hotX,
      hotYInLogicalPixels: hotY,
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
    if (currentDevicePixelRatio != 1.0 /*nativeDevicePixelRatio*/) {
      _Logger.log(
          '\n.\n;\n,\nEntering ICON creation currentDevicePixelRatio=$currentDevicePixelRatio');
      _Logger.log('  Must adjust size=$size   hotX=$hotX   hotY=$hotY ');
      double adjustRatio =
          currentDevicePixelRatio / 1.0 /*nativeDevicePixelRatio*/;
      size = size * adjustRatio;
      hotX = (hotX * adjustRatio).round();
      hotY = (hotY * adjustRatio).round();
      _Logger.log('  ADJUSTED adjust size=$size   hotX=$hotX   hotY=$hotY ');
    }

    ui.Image iconImage = _createImageFromIconSync(icon,
        size: size,
        color: color,
        iconFill: fill,
        iconWeight: weight,
        iconGrade: grade,
        iconOpticalSize: opticalSize,
        shadows: shadows);

    final cursor = await image(iconImage, hotX, hotY,
        currentDevicePixelRatio /* WE MADE image/hotX/hotY match currentDevicePixelRatio!*/,
        originStory: _CustomMouseCursorCreationType.icon,
        existingCursorToUpdate: existingCursorToUpdate);

    cursor._iconCreationInfo = iconCreationInfo;

    _Logger.log(
        '  About to check for NEED TO CREATE 1x for web - IS WEB=$kIsWeb  _useURLDataURICursorCSS=$_useURLDataURICursorCSS  currentDevicePixelRatio=$currentDevicePixelRatio');
    if (kIsWeb && _useURLDataURICursorCSS && currentDevicePixelRatio != 1.0) {
      // For web platform when using legacy URL datauri css cursors we need to always include
      // a 1.0 DPR version of the cursor.
      await _createDevicePixelRatio1xVersion(cursor);
    }

    return cursor;
  }

  Future<void> _updateIconToNewDpi(double newDevicePixelRatio) async {
    if (originStory != _CustomMouseCursorCreationType.icon) {
      throw ('ENTERING _updateIconToNewDpi() called on non icon cursor');
    }
    if (_iconCreationInfo != null) {
      double scaleRatio = newDevicePixelRatio;
      double newSize = _iconCreationInfo!.sizeInLogicalPixels * scaleRatio;
      int newHotX =
          (_iconCreationInfo!.hotXInLogicalPixels * scaleRatio).round();
      int newHotY =
          (_iconCreationInfo!.hotYInLogicalPixels * scaleRatio).round();

      _Logger.log(
          '  updateIconToNewDpi() making icon at newSize=$newSize   (scaleRatio=$scaleRatio)');

      ui.Image iconImage = _createImageFromIconSync(_iconCreationInfo!.icon,
          size: newSize,
          color: _iconCreationInfo!.color,
          iconFill: _iconCreationInfo!.fill,
          iconWeight: _iconCreationInfo!.weight,
          iconGrade: _iconCreationInfo!.grade,
          iconOpticalSize: _iconCreationInfo!.opticalSize,
          shadows: _iconCreationInfo!.shadows);
      _Logger.log(
          '  CALLING image with EXISTING ICON IMAGE TO UPDATE WITH NEW icon Image newDevicePixelRatio=$newDevicePixelRatio');
      image(iconImage, newHotX, newHotY, newDevicePixelRatio,
          originStory: _CustomMouseCursorCreationType.icon,
          existingCursorToUpdate: this);
    }
  }

  /// image() creates cursor from ui.Image.  This is primarily an internal method for the asset(),
  /// exactasset() and icon() methods.  It is left exposed to allow for flexibilty of user's creating cursors
  /// from any ui.Image.
  /// [uiImage] specifies the [ui.Image] object to create the icon from.
  /// [thisImagesDevicePixelRatio] specifies the DPR of the ui.Image.
  /// [hotX],[hotY] specify the location of the cursor hotspot in the DPR specified by [thisImagesDevicePixelRatio].
  ///  the Native DevicePixelRatio for this size.
  /// [key] optionally specifies the key of this image - this may be completely disregard on some platforms,
  ///   on web platforms it will dynmically be replaces as this is the cursor definition.
  ///   This can be left null and the system will handle it's assignment.
  /// [originStory] is used to specify how this image was originally created.  The [_CustomMouseCursorCreationType] class
  /// is private so external users can not change this parameter from the default.
  static Future<CustomMouseCursor> image(
    ui.Image uiImage,
    int hotX,
    int hotY,
    double thisImagesDevicePixelRatio, {
    String? key,
    _CustomMouseCursorCreationType originStory =
        _CustomMouseCursorCreationType.image,

    /// An existing cursor that should be updated instead of creating a new cursor.
    /// This is used on DevicePixelRatio changes to update the cursors backing
    /// image.
    CustomMouseCursor? existingCursorToUpdate,
  }) async {
    _Logger.log(
        'ENTERING image() with existingCursorToUpdate=$existingCursorToUpdate');
    // KLUDGE - maybe not best place but ensure we have callbacks to detect DevicePixelRatio changes
    _setupViewsOnMetricChangedCallbacks();

    int width = uiImage.width;
    int height = uiImage.height;

    late double currentDevicePixelRatio;
    // If we have a ImageConfiguration object already from didChangeDependencies() being called
    // use that to use AssetImage to do a DPI aware loading of the pointer
    if (_lastImageConfiguration != null) {
      _Logger.log(
          '  Using lastImageConfiguration devicePixelRatio = ${_lastImageConfiguration?.devicePixelRatio ?? 'ImageConfiguration MISSING DEVICEPIXELRATIO'}');

      currentDevicePixelRatio = _lastImageConfiguration?.devicePixelRatio ??
          WidgetsBinding.instance.window.devicePixelRatio;
    } // else {
    currentDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    _Logger.log(
        '  image() existingCursorToUpdate=$existingCursorToUpdate  Current currentDevicePixelRatio from WidgetsBinding! devicePixelRatio = ${currentDevicePixelRatio}');

    //}

    if (currentDevicePixelRatio != thisImagesDevicePixelRatio) {
      _Logger.log(
          '  !!!!!! In Image Creation and thisImagesDevicePixelRatio DPR ($currentDevicePixelRatio) != NATIVE ($thisImagesDevicePixelRatio)');
      currentDevicePixelRatio = thisImagesDevicePixelRatio;
      _Logger.log(
          '  CHANGED CURRENT TO MATCH thisImagesDevicePixelRatio FOR THIS CREATION');
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
      _Logger.log('  CREATING NEW CURSOR');
      // if no key was passed in we generate a unique key from md5 of image buffer.
      key ??= generateUniqueKey(imageBuffer);

      late final String registeredKey;
      String? base64ImageDataUri;
      if (!kIsWeb) {
        registeredKey =
            await _CustomMouseCursorPlatformInterface.registerCursor(key,
                imageBuffer, width, height, hotX.toDouble(), hotY.toDouble());
        assert(registeredKey == key);
      } else {
        // for the web the registeredKey *IS* the css cursor data-uri defining this cursor
        base64ImageDataUri =
            _createDataURIForImage(imageBuffer, thisImagesDevicePixelRatio);

        registeredKey = _createCursorCSSDefinition(
            base64ImageDataUri, hotX, hotY, thisImagesDevicePixelRatio, null);
      }
      final cursor = CustomMouseCursor._(registeredKey, originStory,
          thisImagesDevicePixelRatio, hotX, hotY, currentDevicePixelRatio);

      if (!kIsWeb) {
        cursor._dprBitmapCache[thisImagesDevicePixelRatio] =
            _CustomMouseCursorDPRBitmapCache(
                imageBuffer, null, width, height, hotX, hotY);
      } else {
        // Cache the base64ImageDataURI
        cursor._dprBitmapCache[thisImagesDevicePixelRatio] =
            _CustomMouseCursorDPRBitmapCache(
                null, base64ImageDataUri, width, height, hotX, hotY);

        _Logger.log(
            'WEB Added TO CACHE for thisImagesDevicePixelRatio=$thisImagesDevicePixelRatio  !!');
        //NO LONGER NEEDED//cursor._dprCSSCursorCache[thisImagesDevicePixelRatio] = registeredKey;
      }

      _cursorCacheOfAllCreatedCursors[key] = cursor;

      return cursor;
    } else {
      /*
        This is an EXISTING cursor and we are going to update it with a new DPR version of
        the cursor.
      */
      key = existingCursorToUpdate.key;
      _Logger.log('  WE ARE in image() UPDATING the backing image key=$key ');

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
                imageBuffer, null, width, height, hotX, hotY);

        assert(newRegisteredKey == key);
      } else {
        // for the web the registeredKey *IS* the css cursor data-uri defining this cursor
        final base64ImageDataUri =
            _createDataURIForImage(imageBuffer, thisImagesDevicePixelRatio);
        existingCursorToUpdate._dprBitmapCache[thisImagesDevicePixelRatio] =
            _CustomMouseCursorDPRBitmapCache(
                null, base64ImageDataUri, width, height, hotX, hotY);

        existingCursorToUpdate.key = _createCursorCSSDefinition(
            base64ImageDataUri,
            hotX,
            hotY,
            thisImagesDevicePixelRatio,
            existingCursorToUpdate._dprBitmapCache);

        /*NOLONGER NEEDED//existingCursorToUpdate._dprCSSCursorCache[thisImagesDevicePixelRatio] =
            existingCursorToUpdate.key;
        */
      }
      existingCursorToUpdate.currentCursorDevicePixelRatio =
          thisImagesDevicePixelRatio;
      return existingCursorToUpdate;
    }
  }

  /// Creates a CSS URL Data URI with the image definition
  static String _createDataURIForImage(
      Uint8List imageBuffer, double forDebugging) {
    final base64ImageDataUri =
        base64.encode(imageBuffer); //.replaceAll('\n','').replaceAll('\r','');
    //TRACKINGDEBUG//final base64ImageDataUri = ' IMAGE-DATAURI FOR  DPR-$forDebugging';
    return 'url("data:image/png;base64,$base64ImageDataUri")';
  }

  /// Whether or not to use '-webkit-image-set' or 'image-set' for CSS.  Currently the '-webkit-image-set' is the more
  /// widely useable CSS command until full adoption.
  /// Defaults to true.
  static bool useWebKitImageSet = true;

  /// If set then ONLY image-set() style CSS cursor defintions will be generated.  These are new
  /// versions which properly support higher resolution devicePixelRatio cursors, such as 2.0x and 3.0x.
  /// If set then the older 'url()' style CSS cursor definitions WILL NOT BE included at all.
  /// This reduces the size of the cursor defintion and can save time by preventing the need to generate
  /// a 1.0x image on systems where the screen devicePixelRatio is 2.0x (or at least not 1.0x).
  /// (Older style CSS cursor defintions must be supplied 1.0x images because the browser scales them up as necessary
  /// in that case.   If image-set style CSS cursors are being generated anyway the only time the older url() style
  /// defintions are needed is to support older browsers.  At some point the url() style defintions will not be needed
  /// at all as all browsers will support image-set.)
  static set useOnlyImageSetCSS(bool newVal) {
    if (newVal) {
      _useURLDataURICursorCSS = false;
    }
    _useImageSetCSS = true;
  }

  static bool get useOnlyImageSetCSS =>
      _useImageSetCSS && !_useURLDataURICursorCSS;
  static bool _useImageSetCSS = true;

  /// If set then ONLY the older 'url()' style CSS cursor definition will be included.  Image-set cursor defintions will
  /// not be included at all.   All cursors will be generated at 1.0x only and scaled up when needed.  This will result
  /// in pixelated cursors on 2.0x and higher systems as no higher resolution cursors will be able to be supplied
  /// using image-set().
  /// (Older style url() CSS cursor defintions must be supplied 1.0x images only as the browser ALWAYS scales them up
  /// to match the devicePixelRatio and assumes that they are being supplied as 1.0x only).
  static set useOnlyURLDataURICursorCSS(bool newVal) {
    if (newVal) {
      _useImageSetCSS = false;
    }
    _useURLDataURICursorCSS = true;
  }

  static bool get useOnlyURLDataURICursorCSS =>
      _useURLDataURICursorCSS && !_useImageSetCSS;
  static bool _useURLDataURICursorCSS = true;

  /// Makes a CSS cursor definition string
  /// This function will include BOTH 'image-set' and 'url' versions of the
  /// CSS cursor definition unless [_useOnlyImageSetCSS] is true in which
  /// case it will create image-set css only.
  /// If [_useOnlyURLDataURICursorCSS] is true then only URL DataURI
  /// versions of cursors will be created.
  /// NOTE: There is a special case we need to handle - If the [nativeDevicePixelRatio] is NOT 1.0x,
  /// and [_useURLDataURICursorCSS] is true we MUST have a 1.0x image to include in the
  /// cursor definitions, browsers expect 1.0x bitmap that THEY will scale when not using image-set.
  /// If there is not a 1.0x version of the bitmap in the cursors cache, then WE must create one.
  static String _createCursorCSSDefinition(
      String base64ImageDataUri,
      int hotX,
      int hotY,
      double nativeDevicePixelRatio,
      Map<double, _CustomMouseCursorDPRBitmapCache>? dprBitmapCache) {
    _Logger.log(
        'Enteted createCursorCSSDefinition() and nativeDevicePixelRatio=$nativeDevicePixelRatio  dprBitmapCache=$dprBitmapCache');

    //TRACKINGDEBUG//base64ImageDataUri='  ADDING DPR=$nativeDevicePixelRatio ';

    String imageset = '';
    String urldatauri = '';
    if (nativeDevicePixelRatio != 1.0) {
      // hotX and hotY must be in 1.0x location
      hotX = (hotX / nativeDevicePixelRatio).round();
      hotY = (hotY / nativeDevicePixelRatio).round();
    }
    String? dpr1Base64ImageDataUri;
    if (nativeDevicePixelRatio == 1.0) {
      dpr1Base64ImageDataUri = base64ImageDataUri;
    }
    if (_useImageSetCSS) {
      // todo: tmm FINISH bitmap cache version
      if (dprBitmapCache != null) {
        // If we have the cache WE KNOW that the [base64ImageDataUri] is already present in the cache,
        // (because it was added to cache before this call to createCursorCSSDefinition()
        // so we don't need to worry about including [base64ImageDataUri] separately.
        _Logger.log('  LOOPING on cache');
        // first get sizes and sort
        final dprs = dprBitmapCache.keys;

        _Logger.log('  dpr key list = $dprs');
        // LOOP over all bitmaps in the cache and generate our multi DPR image-set defintion
        StringBuffer innerimageset = StringBuffer();
        for (final dpr in dprs) {
          _Logger.log(
              '  Current DRP = $dpr   datauri=${dprBitmapCache[dpr]!.base64ImageDataUri!}');
          String curDprBase64ImageDataUri =
              dprBitmapCache[dpr]!.base64ImageDataUri!;
          if (innerimageset.isNotEmpty) innerimageset.write(', ');
          innerimageset.write('$curDprBase64ImageDataUri ${dpr}x');
          if (dpr == 1.0) {
            dpr1Base64ImageDataUri = curDprBase64ImageDataUri;
          }
        }
        imageset =
            '${useWebKitImageSet ? '-webkit-image-set' : 'image-set'}( $innerimageset ) $hotX $hotY';
      } else {
        // single image
        imageset =
            '${useWebKitImageSet ? '-webkit-image-set' : 'image-set'}( $base64ImageDataUri ${nativeDevicePixelRatio}x ) $hotX $hotY';
      }
    }
    // It is possible that we wont have [dprBase64ImageDataUri] yet, but if we need one then
    // [createDevicePixelRatio_1x_Version()] will be called later and we will update it.
    if (_useURLDataURICursorCSS && dpr1Base64ImageDataUri != null) {
      urldatauri = '$dpr1Base64ImageDataUri $hotX $hotY';
    }
    // This will create a CSS cursor url that will look something like (if this is a 2x devicePixelRatio case)
    // "image-set( url(data1...) 1x, url(data2..) 2x ) 10 10, url(data1) 10 10, pointer"
    // which will have image-set() version with 1x and 2x devicePixelRatios, a fallback older
    // CSS style cursor with just a url(datauri) with a 1x image that will be scaled up on machines with
    // higher DPR, and then a finally a 'pointer' fallback if the browser could handle the first 2 cases.
    final ret =
        '${imageset != '' ? '$imageset, ' : ''}${urldatauri != '' ? '$urldatauri, ' : ''}pointer';
    _Logger.log(
        '  LEAVING createCursorCSSDefinition() MADE CURSOR= "$ret"!!!!');
    return ret;
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
    _Logger.log('disposeAll() called');
    for (final cursor in _cursorCacheOfAllCreatedCursors.values) {
      _Logger.log('Calling dispose on ${cursor.key}');
      cursor.dispose();
    }
    _cursorCacheOfAllCreatedCursors.clear();
  }

  static ImageConfiguration? _lastImageConfiguration;
  static double _lastEnsuredDevicePixelRatio = 0;

  /// This method creates a DPR 1.0x version of the cursor for the WEB platform for use in the
  /// older CSS url() style cursor defintions (where 1.0x is ASSUMED by the browser).
  /// If the platform is NOT web, or older style URL cursors are not being included in the defintion
  /// ([_useURLDataURICursorCSS] is false) then this method returns immediately.
  static _createDevicePixelRatio1xVersion(CustomMouseCursor cursor) async {
    _Logger.log('ENTERING _createDevicePixelRatio1xVersion() entered');

    if (!kIsWeb ||
        !_useURLDataURICursorCSS ||
        cursor._dprBitmapCache.containsKey(1.0)) {
      // this cursor alreay has a 1.0 DPR version present so it is set
      _Logger.log(
          '   We found the 1.0X KEY - existing  _createDevicePixelRatio1xVersion()!!!!!');
      return;
    }

    // Because this is the WEB PLATFORM only when we call_updateAssetToNewDpi() or _updateIconToNewDpi() below
    // we will just be ADDING the 1.0x cursor image to the existing cursor definition.
    if (cursor.originStory == _CustomMouseCursorCreationType.asset ||
        cursor.originStory == _CustomMouseCursorCreationType.exactasset) {
      final imageConfigurationDPR_1 =
          _createLocalImageConfigurationWithOrWithoutContext(
              forceDevicePixelRatio: 1.0);

      _Logger.log('  creating 1.0X FOR ASSET CURSOR key=${cursor.key}');

      if (cursor._assetBundleImageProvider != null) {
        AssetBundleImageKey newAssetAwareKey = await cursor
            ._assetBundleImageProvider!
            .obtainKey(imageConfigurationDPR_1);
        //NOLONGER//cursor._currentAssetAwareKey = newAssetAwareKey;
        await cursor._updateAssetToNewDpi(1.0);
      } else {
        // should not be able to happen
        throw ('_assetBundleImageProvider was null in _createDevicePixelRatio1xVersion');
      }
    } else if (cursor.originStory == _CustomMouseCursorCreationType.icon) {
      _Logger.log(
          '  Creating 1.0x for ICON CURSOR ${cursor._iconCreationInfo!.icon}');
      await cursor._updateIconToNewDpi(1.0);
    }
  }

  /// This method ensures that all pointers have support for any changes to the devicePixelRatio
  /// This can happen on windows moving to new monitors with different DPR or by changing system
  /// settings for display.
  /// This is called from our onMetricsChanged() hook or by user themselves (typically from their
  /// root widget's didChangeDependencies() handler.
  static void ensurePointersMatchDevicePixelRatio(BuildContext? context) async {
    _Logger.log('ENTERED ensurePointersMatchDevicePixelRatio()');
    double devicePixelRatio = _getDevicePixelRatioFromView();
    if (devicePixelRatio == _lastEnsuredDevicePixelRatio) {
      _Logger.log(
          '  lastEnsuredDevicePixelRatio IMMEDIATE RETURN already $_lastEnsuredDevicePixelRatio');
      return;
    }

    _lastImageConfiguration =
        _createLocalImageConfigurationWithOrWithoutContext(context: context);

    double currentDevicePixelRatio =
        _lastImageConfiguration?.devicePixelRatio ?? devicePixelRatio;

    _Logger.log(
        '  Determined Current currentDevicePixelRatio= ${currentDevicePixelRatio}');

    _Logger.log(
        '  createLocalImageConfiguration  devicePixelRatio=${_lastImageConfiguration!.devicePixelRatio}  platform=${_lastImageConfiguration!.platform}');
/* OLD TEST CODE
    String assetName = 'assets/cursors/startrek_mousepointer.png';
    AssetImage assetImage = AssetImage(assetName);
    if (_lastImageConfiguration != null) {
      AssetBundleImageKey assetAwareKey =
          await assetImage.obtainKey(_lastImageConfiguration!);

      Logger.log(
          'Using lastImageConfiguration got name=${assetAwareKey.name} scale=${assetAwareKey.scale}');
    }
*/
    _Logger.log('  CHECKING ALL CURSORS');
    for (final cursor in _cursorCacheOfAllCreatedCursors.values) {
      _Logger.log(
          '    Checking DPR for ${cursor.key}  cursor.originStory=${cursor.originStory}');
      if (cursor.currentCursorDevicePixelRatio != currentDevicePixelRatio) {
        _Logger.log(
            '    Current DPI is different than cursors DPI!!!    cursor.currentCursorDevicePixelRatio=${cursor.currentCursorDevicePixelRatio} != currentDevicePixelRatio=${currentDevicePixelRatio}');

        // First we check this cursors DPR cache
        if (!kIsWeb) {
          if (cursor._dprBitmapCache.containsKey(currentDevicePixelRatio)) {
            _Logger.log(
                '    Getting DPR $currentDevicePixelRatio from cursors BITMAP cache!!!');
            final cachedInfo = cursor._dprBitmapCache[currentDevicePixelRatio]!;
            // WE ARE UPDATING an existing cursor's backing image, so delete previous image and
            _CustomMouseCursorPlatformInterface.deleteCursor(cursor.key);
            // get new version with new dpi image
            _CustomMouseCursorPlatformInterface.registerCursor(
                cursor.key,
                cachedInfo.imageBuffer!,
                cachedInfo.width,
                cachedInfo.height,
                cachedInfo.hotX.toDouble(),
                cachedInfo.hotY.toDouble());
            cursor.currentCursorDevicePixelRatio = currentDevicePixelRatio;
            continue;
          }
        } else {
          if (cursor._dprBitmapCache.containsKey(currentDevicePixelRatio)) {
            // WE found this DPU in the cache so we know it is included in the cursor defintion
            _Logger.log(
                '     Found DPR $currentDevicePixelRatio from cursors cache!!!  WE CAN SKIP THISONE');
            cursor.currentCursorDevicePixelRatio = currentDevicePixelRatio;
            continue;
          }
        }

        // not in cache, so go create new cursor bitmap for this DPR
        if (cursor.originStory == _CustomMouseCursorCreationType.asset ||
            cursor.originStory == _CustomMouseCursorCreationType.exactasset) {
          _Logger.log(
              '    UPGRADING Asset cursor ${cursor.key} cursor.originStory=${cursor.originStory} assetImage=${cursor._assetBundleImageProvider}');
/*NOT USED
          if (cursor._assetBundleImageProvider == null) {
            // We need to get this cursors AssetImage, it couldn't be created when it was
            cursor._assetBundleImageProvider = AssetImage(assetName);

            //KLUDGE do we ever use this cursor.currentAssetAwareKey?????
            cursor._currentAssetAwareKey = await cursor
                ._assetBundleImageProvider!
                .obtainKey(_lastImageConfiguration!);
          }*/
          if (cursor._assetBundleImageProvider != null &&
              _lastImageConfiguration != null) {
            AssetBundleImageKey newAssetAwareKey = await cursor
                ._assetBundleImageProvider!
                .obtainKey(_lastImageConfiguration!);

            _Logger.log(
                '      WE SHOULD SWITCH origin IMAGE TO name=${newAssetAwareKey.name} scale=${newAssetAwareKey.scale}');
            //NOLONGER//_Logger.log(
            //NOLONGER//    '         previous AssetAwareKey =${cursor._currentAssetAwareKey!.name} scale=${cursor._currentAssetAwareKey!.scale}');
            //NOLONGER//._currentAssetAwareKey = newAssetAwareKey;

            _Logger.log(
                '    UPDATING ASSET CURSOR - CALLING cursor.updateAssetToNewDpi( $currentDevicePixelRatio );');

            await cursor._updateAssetToNewDpi(currentDevicePixelRatio);
          } else {
            throw ('_assetBundleImageProvider==null or _lastImageConfiguration==null in ensurePointersMatchDevicePixelRatio');
          }
        } else if (cursor.originStory == _CustomMouseCursorCreationType.icon) {
          _Logger.log(
              '      UPDATING ICON CURSOR - CALLING cursor.updateIconToNewDpi( $currentDevicePixelRatio );');
          cursor._updateIconToNewDpi(currentDevicePixelRatio);
        }
      }
    }
    _lastEnsuredDevicePixelRatio = currentDevicePixelRatio;
    _Logger.log('  LEAVING ensurePointersMatchDevicePixelRatio()!!!!!');
  }

  /// Our onMetricsChanged() callback
  /// Curiously this takes no args and we have to detect where it came from OURSELVES ??
  /// todo: tmm  clean this up once flutter mutliwindow stuff is complete
  static void onMetricsChanged() {
    ensurePointersMatchDevicePixelRatio(null);
  }

  /// If a context is supplied then [createLocalImageConfiguration] is used as normal to create the [ImageConfiguration]
  /// object.  Otherwise the devicePixelRatio from [PlatformDispatcher] is used (or the [foreceDevicePixelRatio] value)
  /// to create a ImageConfiguration().
  static ImageConfiguration _createLocalImageConfigurationWithOrWithoutContext(
      {BuildContext? context, double? forceDevicePixelRatio}) {
    if (forceDevicePixelRatio != null || context == null) {
      // MAKE our own default ImageConfiguration() with devicePixelRatio from PlatformDispatcher
      // or the supplied forceDevicePixelRatio.
      final returnImageConfiguration = ImageConfiguration(
        bundle: rootBundle,
        devicePixelRatio:
            forceDevicePixelRatio ?? _getDevicePixelRatioFromView(),
        locale: PlatformDispatcher.instance.locale,
        textDirection: TextDirection.ltr,
        size: null,
        platform: defaultTargetPlatform,
      );
      if (forceDevicePixelRatio == null) {
        // ONLY REMEMBER THIS AS [_lastImageConfiguration] if it was NOT FORCED
        _lastImageConfiguration = returnImageConfiguration;
      }
      return returnImageConfiguration;
    } else {
      // we were supplied a [context] so use that to get create [ImageConfiguration].
      _lastImageConfiguration = createLocalImageConfiguration(context);
      return _lastImageConfiguration!;
    }
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
    if (kIsWeb && _useURLDataURICursorCSS && !_useImageSetCSS) {
      // If we are using ONLY URL data uri cursors and NOT image-set(), so ONLY 1.0x images will
      // be generated and browser will scale them.  We won't be able to give DPR specific versions of images
      // without image-set.
      return 1.0;
    }

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

    _Logger.log(
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
        _Logger.log(
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
    _Logger.log('  RETURNING lastDevicePixelRatio=$_lastDevicePixelRatio');
    return _lastDevicePixelRatio;
  }

  static void _setupViewsOnMetricChangedCallbacks() {
    if (!_onMetricChangedCallbackSet && !_noOnMetricsChangedHook) {
      _onMetricChangedCallbackSet = true;
      _Logger.log(
          'setupViewsOnMetricChangedCallbacks() called and BEING SET UP usePlatformDipatcherOnMetricsChanged=$_usePlatformDipatcherOnMetricsChanged');
      if (_usePlatformDipatcherOnMetricsChanged) {
        // Just use platformDispatcher instance
        WidgetsBinding.instance.platformDispatcher.onMetricsChanged = () {
          _Logger.log(
              'onMetricsChanged() SINGLE instance.platformDispatcher() version!!!!!');
          onMetricsChanged();
        };
      } else {
        // TODO: tmm  properly develop/test this once multiple windows/views is implemented in flutter
        // put the callback on ALL views
        for (final view in WidgetsBinding.instance.platformDispatcher.views) {
          view.platformDispatcher.onMetricsChanged = () {
            _Logger.log('view.platformdispatcher.onMetricsChanged() !!!!!');
            _Logger.log(
                'View is DPR ${view.devicePixelRatio}   view.viewId=${view.viewId}');
            onMetricsChanged();
          };
        }
      }
    }
  }

  // todo: tmm  remove entirely after testing and not include crypto or take time to do md5
  static String generateUniqueKey(Uint8List input) {
    return UniqueKey().toString(); //return md5.convert(input).toString();
  }

  /// Returns Uint8List of the ui.Image's pixels in BGRA format
  static Future<Uint8List> _getBytesAsBGRAFromImage(ui.Image image) async {
    int width = image.width;
    int height = image.height;
    final rgbaBD = await image.toByteData(format: ImageByteFormat.rawRgba);
    final rgba = rgbaBD?.buffer.asUint8List();
    return _getRGBABytesAsBGRA(rgba!, width, height);
  }

  /// Convert RGBA formmated Uint8List into BGRA format.
  /// (This format is needed for creating cursors on windows platform)
  static Uint8List _getRGBABytesAsBGRA(Uint8List rgba, int width, int height) {
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
  static ui.Image _createImageFromIconSync(IconData icon,
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

  static Future<ui.Image> _createUIImageFromUint8ListBufferPossiblyScale(
      Uint8List rawUint8,
      {rescaleRatioRequiredForImage = 1.0}) async {
    // nonscaled case just use decodeImageFromList()
    if (rescaleRatioRequiredForImage == 1.0)
      return await decodeImageFromList(rawUint8);

    // otherwise scaling required - there is the deprecated way and non-deprecated way - second way requires the MASTER CHANNEL
    ui.Image? uiImage;
    if (_oldFlutterAPIS) {
      // Flutter deprecated version
      uiImage = await decodeImageFromList(rawUint8);
      if (rescaleRatioRequiredForImage != 1.0) {
        final ui.Codec codec = await PaintingBinding.instance
            .instantiateImageCodec(rawUint8,
                cacheWidth:
                    (uiImage.width * rescaleRatioRequiredForImage).round(),
                cacheHeight:
                    (uiImage.height * rescaleRatioRequiredForImage).round(),
                allowUpscaling: (rescaleRatioRequiredForImage > 1.0));
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        uiImage = frameInfo.image;
      }
    } else {
      // Flutter non deprecated version
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
      uiImage = frameInfo.image;
    }
    return uiImage;
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
/// This plugin's platform channel accepts commands in the identical format as the flutter engine's built in
/// windows platform implementation.
class _CustomMouseCursorPlatformInterface {
  static const createCursorKey = "createCustomCursor";
  static const setCursorMethod = "setCustomCursor";
  static const deleteCursorMethod = "deleteCustomCursor";

  _CustomMouseCursorPlatformInterface._();

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

enum _CustomMouseCursorCreationType { exactasset, asset, image, icon }

/// This class is used to remember the parameters originally passed to icon() method so regeneration
/// of the icon based cursor's image is possible when the devicePixelRatio changes.
class _CustomMouseCursorFromIconOriginInfo {
  _CustomMouseCursorFromIconOriginInfo({
    required this.icon,
    required this.sizeInLogicalPixels,
    required this.hotXInLogicalPixels,
    required this.hotYInLogicalPixels,
    required this.fill,
    required this.weight,
    required this.opticalSize,
    required this.grade,
    required this.color,
    required this.shadows,
  });
  final double sizeInLogicalPixels;
  final int hotXInLogicalPixels;
  final int hotYInLogicalPixels;
  final IconData icon;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color color;
  final List<Shadow>? shadows;
}

/// This is used to cache information about images used by already created cursors for a specific
/// DevicePixelRatio.  This allows us to skip re-loading/creation of bitmaps for
/// a given DPR when the flutter window moves between different DPR screens.
/// Instead the system cursor can be regenerated from the cached bitmap data within [imageBuffer].
/// On the web platform this instead cache's the images generated [base64ImageDataUri]
/// so that it can be re-used when generating web cursors which support additional devicePixelRatios.
class _CustomMouseCursorDPRBitmapCache {
  const _CustomMouseCursorDPRBitmapCache(this.imageBuffer,
      this.base64ImageDataUri, this.width, this.height, this.hotX, this.hotY);
  final Uint8List? imageBuffer;
  final String? base64ImageDataUri;
  final int width;
  final int height;
  final int hotX;
  final int hotY;
}
