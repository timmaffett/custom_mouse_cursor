import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:custom_mouse_cursor/custom_mouse_cursor.dart';

// IMPORT PACKAGE
import 'package:signature/signature.dart';
import 'package:material_symbols_icons/sharp.dart';
import 'package:google_fonts/google_fonts.dart';

/*

// Some of these api entry points require my custom version of the Win32 package
//  I used this to experiment with using Windows's SetThreadCursorCreationScaling() functiun
//  but that did not work when creating cursors from mempory based bitmaps.
//  The mehtod that the package now uses to support varying DPI/DevicePixelRatio's is
//  better anyway because it is completely cross platform and is very fast and seemless.
import 'package:win32/win32.dart' as win32;
import 'package:win32/winrt.dart' as winrt;

void queryWin32() {
  winrt.UISettings uisettings = winrt.UISettings();
  final cursorSize = uisettings.cursorSize;

  print(
      'uisettings cursorSize.width x height=${cursorSize.Width} x ${cursorSize.Height}');
  final systemDPI = win32.GetDpiForSystem();
  print('systemDPI = $systemDPI');
  final prevDPI = win32.SetThreadCursorCreationScaling(192);
  print(
      'called SetThreadCursorCreationScaling( 192 ) and the prev value was $prevDPI');

  final DPI_AWARENESS_CONTEXT_UNAWARE =
      win32.GetDpiFromDpiAwarenessContext(/*(DPI_AWARENESS_CONTEXT)*/ -1);
  final DPI_AWARENESS_CONTEXT_SYSTEM_AWARE =
      win32.GetDpiFromDpiAwarenessContext(/*(DPI_AWARENESS_CONTEXT)*/ -2);
  final DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE =
      win32.GetDpiFromDpiAwarenessContext(/*(DPI_AWARENESS_CONTEXT)*/ -3);
  final DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 =
      win32.GetDpiFromDpiAwarenessContext(/*(DPI_AWARENESS_CONTEXT)*/ -4);
  final DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED =
      win32.GetDpiFromDpiAwarenessContext(/*(DPI_AWARENESS_CONTEXT)*/ -5);

  print(
      'DPI_AWARENESS_CONTEXT_UNAWARE                  $DPI_AWARENESS_CONTEXT_UNAWARE             ');
  print(
      'DPI_AWARENESS_CONTEXT_SYSTEM_AWARE             $DPI_AWARENESS_CONTEXT_SYSTEM_AWARE        ');
  print(
      'DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE        $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE   ');
  print(
      'DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2     $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2');
  print(
      'DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED        $DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED   ');

  int hWin = win32.GetForegroundWindow();
  int winDPI = win32.GetDpiForWindow(hWin);
  print('winDPI = $winDPI');
}
//WIN32//
*/

late CustomMouseCursor assetCursor;
late CustomMouseCursor assetCursorOnly25;
late CustomMouseCursor assetNative8x;
late CustomMouseCursor iconCursor;
late CustomMouseCursor msIconCursor;
late CustomMouseCursor assetCursorSingleSize;

Future<void> initializeCursors() async {
  print("Creating cursor from asset and from icon");
  //final byte = await rootBundle.load("assets/cursors/mouse.png");

  // Example of image asset that has many device pixel ratio versions (1.5x,2.0x,2.5x,3.0x,3.5x,4.0x,8.0x
  assetCursor = await CustomMouseCursor.asset(
      "assets/cursors/startrek_mousepointer.png",
      hotX: 18,
      hotY: 0);

  assetCursorOnly25 = await CustomMouseCursor.asset(
      "assets/cursors/startrek_mousepointer25Only.png",
      hotX: 18,
      hotY: 0);

  // Example of image asset only at 8x native DevicePixelRatio so will get scaled down to most/all encoutered DPR's
  assetNative8x = await CustomMouseCursor.exactAsset(
      "assets/cursors/star-trek-mouse-pointer-cursor292x512.png",
      hotX: 144,
      hotY: 0,
      nativeDevicePixelRatio: 8.0);

  List<Shadow> shadows = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.8),
      offset: Offset(2, 2),
      blurRadius: 2,
      spreadRadius: 2,
    ),
  ];
  iconCursor = await CustomMouseCursor.icon(Icons.redo,
      size: 24, //48,
      hotX: 22, //48,
      hotY: 17, //33,
      color: Colors.pinkAccent,
      shadows: shadows);

  msIconCursor = await CustomMouseCursor.icon(
      MaterialSymbols.arrow_selector_tool,
      size: 64,
      hotX: 16,
      hotY: 4,
      nativeDevicePixelRatio: 2.0,
      fill: 1,
      color: Colors.blueAccent);

  assetCursorSingleSize = await CustomMouseCursor.exactAsset(
      "assets/cursors/example_game_cursor_64x64.png",
      hotX: 2,
      hotY: 2,
      nativeDevicePixelRatio: 2.0);
}

/*
void viewsReport(String message) {
  print('Entering viewsReport() - $message');
  for(final view in WidgetsBinding.instance.platformDispatcher.views) {
    view.platformDispatcher.onMetricsChanged = () {
      print('view.platformdispatcher.onMetricsChanged() !!!!!');
    };
    print('View is DPR ${view.devicePixelRatio}   view.viewId=${view.viewId}');
  }
  final implicitView = PlatformDispatcher.instance.implicitView;
  print('PlatformDispatcher.instance.implicitView.viewId = ${implicitView?.viewId ?? 'implicitView IS NULL'} ');
  print('leaving viewsReport()');
}
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

/*
  WidgetsBinding.instance.platformDispatcher.onMetricsChanged = () {
    print('platformDispatcher - onMetricsChanged() (set in main) !!!');
  };
*/
  //CustomMouseCursor.noOnMetricsChangedHook = true;
  //KLUDGE//viewsReport('Called from MAIN');

  await initializeCursors();

  runApp(const MyApp());

  //called immediately// CustomMouseCursor.disposeAll();
}

/*
Future<img2.Image> getImage(Uint8List bytes) async {
  img = img2.decodePng(bytes)!;
  return img;
}
*/

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

typedef SelectCursorCallback = void Function(CustomMouseCursor);

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final SignatureController _signatureController;
  late final Widget _signatureCanvas;

  CustomMouseCursor? currentDrawCursor;

  late Size _lastSize;
  late double _lastDevicePixelRatio;

  @override
  void didChangeMetrics() {
    print('WIDGETS onChangeMetrics() callback called!!!!');
    setState(() {
      double prevDPR = _lastDevicePixelRatio;
      _lastSize = WidgetsBinding.instance.window.physicalSize;
      _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      print(
          'in didChangeMetrics() Window size is $_lastSize  prevDPR=$prevDPR  new DevicePixelRatio=$_lastDevicePixelRatio');

      CustomMouseCursor.ensurePointersMatchDevicePixelRatio(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('WIDGETS didChangeDependencies() callback called!!!!');

    double prevDPR = _lastDevicePixelRatio;
    _lastSize = WidgetsBinding.instance.window.physicalSize;
    _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    print(
        'in didChangeDependencies() Window size is $_lastSize   prevDPR=$prevDPR  new DevicePixelRatio=$_lastDevicePixelRatio');

    CustomMouseCursor.ensurePointersMatchDevicePixelRatio(context);
  }

  void selectCursorCallback(CustomMouseCursor cursor) {
    print('Changing to cursor key=${cursor.key}');
    //queryWin32();
    setState(() {
      currentDrawCursor = cursor;
      _signatureController.clear();
    });
  }

  @override
  void initState() {
    print('MyApp initState() called');
    super.initState();

    _lastSize = WidgetsBinding.instance.window.physicalSize;
    _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    print(
        'Window size is $_lastSize    _lastDevicePixelRatio=$_lastDevicePixelRatio');
    WidgetsBinding.instance.addObserver(this);

    // Initialise a controller. It will contains signature points, stroke width and pen color.
    // It will allow you to interact with the widget
    _signatureController = SignatureController(
      penStrokeWidth: 1,
      penColor: Colors.blueAccent,
      exportBackgroundColor: Colors.blueGrey,
    );

    _signatureCanvas = Expanded(
        child: Signature(
      //width: 300,
      height: 300,
      controller: _signatureController,
      backgroundColor: Colors.white,
    ));

    //KLUDGE//viewsReport('Called from End of InitState()');
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);

    _signatureController.dispose();
    CustomMouseCursor.disposeAll();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CustomMouseCursor example app'),
        ),
        body: Center(
            child: ListView(
          children: [
            CursorTesterSelectorRegion(
              assetCursor,
              message: 'Click to Select Asset Cursor',
              note: '(with 1.0x,1.5x,2.0x,2.5x,3.0x,3.5x,4.0x, and 8.0x assets present)',
              details:
                  'CustomMouseCursor.asset("assets/cursors/startrek_mousepointer.png", hotX:18, hotY:0)',
              color: Colors.indigoAccent,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetCursorOnly25,
              message: 'Click to Select Asset (Only 1.0 & 2.5x) Cursor',
              note: '(only 1.0x and 2.5x assets present) (should be identical to above)',
              details:
                  'CustomMouseCursor.asset("assets/cursors/startrek_mousepointer25Only.png", hotX:18, hotY:0)',
              color: Colors.blue,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetNative8x,
              message: 'Click to Select 8x DPR ExactAsset Cursor',
              note: '(single 8.0x exactAsset specified) (should be identical to above)',
              details:
                  'CustomMouseCursor.exactAsset("assets/cursors/star-trek-mouse-pointer-cursor292x512.png", hotX: 144, hotY: 0, nativeDevicePixelRatio: 8.0);',
              color: ui.Color.fromARGB(255, 26, 133, 172),
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              iconCursor,
              message: 'Click to Select Icon Cursor',
              details:
                  'CustomMouseCursor.icon( Icons.redo,size: 48, hotX:48, hotY:33, color:Colors.red, shadows:shadows)',
              color: Colors.green,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              msIconCursor,
              message: 'Click to Select Material Symbols Icon Cursor',
              note: '(specified with 2.0x DPR size/hot spot coords)',
              details:
                  'CustomMouseCursor.icon( MaterialSymbols.arrow_selector_tool, size: 64, hotX: 12, hotY: 8, nativeDevicePixelRatio: 2.0, fill: 1, color: Colors.blueAccent )',
              color: Colors.yellow,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetCursorSingleSize,
              message:
                  'Click to Select ExactAsset Cursor',
              note: '(DPR 2.0 asset/hotspot coords)',
              details:
                  'CustomMouseCursor.exactAsset("assets/cursors/example_game_cursor_64x64.png",  hotX: 2, hotY: 2, nativeDevicePixelRatio: 2.0)',
              color: Colors.orange,
              selectCursorCallback: selectCursorCallback,
            ),
            MouseRegion(
              cursor: currentDrawCursor != null
                  ? currentDrawCursor!
                  : SystemMouseCursors.precise,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("Click/drag to draw with mouse and to test cursor's hot spot (X,Y).",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ]),
                    Row(children: [_signatureCanvas]),
                  ]),
            ),
          ],
        )),
      ),
    );
  }
}

class CursorTesterSelectorRegion extends StatelessWidget {
  final Color color;
  final SelectCursorCallback? selectCursorCallback;
  final String message;
  final String? note;
  final String? details;
  final CustomMouseCursor cursor;

  const CursorTesterSelectorRegion(this.cursor,
      {required this.message,
      this.note,
      this.details,
      this.color = Colors.white,
      this.selectCursorCallback});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: () {
          selectCursorCallback?.call(cursor);
        },
        child: Container(
          decoration: BoxDecoration(
                        color: color,
                        border: Border( bottom: BorderSide(color: Colors.black, width: 1),
                      ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                Text(message,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      )),
                if(note!=null) SizedBox(width:20),
                if(note!=null) 
                  Text(note!,
                  style: const TextStyle(
                      fontSize: 16, fontStyle: FontStyle.italic,
                    )),
              ]),
              if (details != null)
                Container(
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Text(
                      details!,

                      style: TextStyle(
                          fontSize: 16,
                          backgroundColor: Colors
                              .grey), //GoogleFonts.jetBrainsMono(fontSize: 16, backgroundColor:Colors.grey)
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/*
	ui.Image image = repaintBoundary.toImageSync(pixelRatio: pixelRatio);


		ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);


CSS url cursor format

/* URL with mandatory keyword fallback */
cursor: url(hand.cur), pointer;

/* URL and coordinates, with mandatory keyword fallback */
cursor: url(cursor_1.png) 4 12, auto;
cursor: url(cursor_2.png) 2 2, pointer;

/* URLs and fallback URLs (some with coordinates), with mandatory keyword fallback */
cursor: url(cursor_1.svg) 4 5, url(cursor_2.svg), /* … ,*/ url(cursor_n.cur) 5 5,
  progress;


Icon size limits
While the specification does not limit the cursor image size, user agents commonly restrict them to avoid
potential misuse. For example, on Firefox and Chromium cursor images are restricted to 128x128 pixels by
default, but it is recommended to limit the cursor image size to 32x32 pixels. Cursor changes using images
that are larger than the user-agent maximum supported size will generally just be ignored.

Supported image file formats
User agents are required by the specification to support PNG files, SVG v1.1 files in secure static mode
that contain a natural size, and any other non-animated image file formats that they support for images
in other properties. Desktop browsers also broadly support the .cur file format.

The specification further indicates that user agents should also support SVG v1.1 files in secure
animated mode that contain a natural size, along with any other animated images file formats they
support for images in other properties. User agents may support both static and animated SVG images
that do not contain a natural size.


BASE 64 encode:

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
String imagepath = " /data/user/img.jpg"; 
//image path, you can get it with image_picker package

File imagefile = File(imagepath); //convert Path to File
Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
String base64string = base64.encode(imagebytes); //convert bytes to base64 string
print(base64string); 

/* Output:
  /9j/4Q0nRXhpZgAATU0AKgAAAAgAFAIgAAQAAAABAAAAAAEAAAQAAAABAAAJ3
  wIhAAQAAAABAAAAAAEBAAQAAAABAAAJ5gIiAAQAAAABAAAAAAIjAAQAAAABAAA
  AAAIkAAQAAAABAAAAAAIlAAIAAAAgAAAA/gEoAA ... long string output
*/ 


OR alternate base64

convert our Image file to bytes with the help of dart:io library.
import 'dart:io' as Io;

final bytes = await Io.File(image).readAsBytes();
// or
final bytes = Io.File(image).readAsBytesSync();
use dart:convert library base64Encode() function to encode bytes to Base64.
It is the shorthand for base64.encode().

String base64Encode(List<int> bytes) => base64.encode(bytes);

*/

Future<ByteData?> _timimageByteDataFromShader(
  Shader shader,
  Size size,
) async {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Paint paint = Paint()..shader = shader;
  canvas.drawPaint(paint);
  final Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    size.width.floor(),
    size.height.floor(),
  );
  return image.toByteData();
}

/// Creates am image with the passed shader of the requested size
ui.Image _createImageFromIconSync(IconData icon,
    {double size = 32, Color color = Colors.black, List<Shadow>? shadows}) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  //final Paint paint = Paint()..color = Colors.red;
  //canvas.drawPaint(paint);

  final textSpan = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      /*fontVariations: <FontVariation>[
            if (iconFill != null) FontVariation('FILL', iconFill),
            if (iconWeight != null) FontVariation('wght', iconWeight),
            if (iconGrade != null) FontVariation('GRAD', iconGrade),
            if (iconOpticalSize != null) FontVariation('opsz', iconOpticalSize),
          ],*/
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

class Icon_TIM extends StatelessWidget {
  /// Creates an icon.
  const Icon_TIM(
    this.icon, {
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.textDirection,
  })  : assert(fill == null || (0.0 <= fill && fill <= 1.0)),
        assert(weight == null || (0.0 < weight)),
        assert(opticalSize == null || (0.0 < opticalSize));

  /// The icon to display. The available icons are described in [Icons].
  ///
  /// The icon can be null, in which case the widget will render as an empty
  /// space of the specified [size].
  final IconData? icon;

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.size].
  ///
  /// If this [Icon] is being placed inside an [IconButton], then use
  /// [IconButton.iconSize] instead, so that the [IconButton] can make the splash
  /// area the appropriate size as well. The [IconButton] uses an [IconTheme] to
  /// pass down the size to the [Icon].
  final double? size;

  /// The fill for drawing the icon.
  ///
  /// Requires the underlying icon font to support the `FILL` [FontVariation]
  /// axis, otherwise has no effect. Variable font filenames often indicate
  /// the supported axes. Must be between 0.0 (unfilled) and 1.0 (filled),
  /// inclusive.
  ///
  /// Can be used to convey a state transition for animation or interaction.
  ///
  /// Defaults to nearest [IconTheme]'s [IconThemeData.fill].
  ///
  /// See also:
  ///  * [weight], for controlling stroke weight.
  ///  * [grade], for controlling stroke weight in a more granular way.
  ///  * [opticalSize], for controlling optical size.
  final double? fill;

  /// The stroke weight for drawing the icon.
  ///
  /// Requires the underlying icon font to support the `wght` [FontVariation]
  /// axis, otherwise has no effect. Variable font filenames often indicate
  /// the supported axes. Must be greater than 0.
  ///
  /// Defaults to nearest [IconTheme]'s [IconThemeData.weight].
  ///
  /// See also:
  ///  * [fill], for controlling fill.
  ///  * [grade], for controlling stroke weight in a more granular way.
  ///  * [opticalSize], for controlling optical size.
  ///  * https://fonts.google.com/knowledge/glossary/weight_axis
  final double? weight;

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
  /// Defaults to nearest [IconTheme]'s [IconThemeData.grade].
  ///
  /// See also:
  ///  * [fill], for controlling fill.
  ///  * [weight], for controlling stroke weight in a less granular way.
  ///  * [opticalSize], for controlling optical size.
  ///  * https://fonts.google.com/knowledge/glossary/grade_axis
  final double? grade;

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
  /// Defaults to nearest [IconTheme]'s [IconThemeData.opticalSize].
  ///
  /// See also:
  ///  * [fill], for controlling fill.
  ///  * [weight], for controlling stroke weight.
  ///  * [grade], for controlling stroke weight in a more granular way.
  ///  * https://fonts.google.com/knowledge/glossary/optical_size_axis
  final double? opticalSize;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.color].
  ///
  /// The color (whether specified explicitly here or obtained from the
  /// [IconTheme]) will be further adjusted by the nearest [IconTheme]'s
  /// [IconThemeData.opacity].
  ///
  /// {@tool snippet}
  /// Typically, a Material Design color will be used, as follows:
  ///
  /// ```dart
  /// Icon(
  ///   Icons.widgets,
  ///   color: Colors.blue.shade400,
  /// )
  /// ```
  /// {@end-tool}
  final Color? color;

  /// A list of [Shadow]s that will be painted underneath the icon.
  ///
  /// Multiple shadows are supported to replicate lighting from multiple light
  /// sources.
  ///
  /// Shadows must be in the same order for [Icon] to be considered as
  /// equivalent as order produces differing transparency.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.shadows].
  final List<Shadow>? shadows;

  /// The text direction to use for rendering the icon.
  ///
  /// If this is null, the ambient [Directionality] is used instead.
  ///
  /// Some icons follow the reading direction. For example, "back" buttons point
  /// left in left-to-right environments and right in right-to-left
  /// environments. Such icons have their [IconData.matchTextDirection] field
  /// set to true, and the [Icon] widget uses the [textDirection] to determine
  /// the orientation in which to draw the icon.
  ///
  /// This property has no effect if the [icon]'s [IconData.matchTextDirection]
  /// field is false, but for consistency a text direction value must always be
  /// specified, either directly using this property or using [Directionality].
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    assert(this.textDirection != null || debugCheckHasDirectionality(context));
    final TextDirection textDirection =
        this.textDirection ?? Directionality.of(context);

    final IconThemeData iconTheme = IconTheme.of(context);

    final double? iconSize = size ?? iconTheme.size;

    final double? iconFill = fill ?? iconTheme.fill;

    final double? iconWeight = weight ?? iconTheme.weight;

    final double? iconGrade = grade ?? iconTheme.grade;

    final double? iconOpticalSize = opticalSize ?? iconTheme.opticalSize;

    final List<Shadow>? iconShadows = shadows ?? iconTheme.shadows;

    if (icon == null) {
      return SizedBox(width: iconSize, height: iconSize);
    }

    final double iconOpacity = iconTheme.opacity ?? 1.0;
    Color iconColor = color ?? iconTheme.color!;
    if (iconOpacity != 1.0) {
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);
    }

    Widget iconWidget = RichText(
      overflow: TextOverflow.visible, // Never clip.
      textDirection:
          textDirection, // Since we already fetched it for the assert...
      text: TextSpan(
        text: String.fromCharCode(icon!.codePoint),
        style: TextStyle(
          fontVariations: <FontVariation>[
            if (iconFill != null) FontVariation('FILL', iconFill),
            if (iconWeight != null) FontVariation('wght', iconWeight),
            if (iconGrade != null) FontVariation('GRAD', iconGrade),
            if (iconOpticalSize != null) FontVariation('opsz', iconOpticalSize),
          ],
          inherit: false,
          color: iconColor,
          fontSize: iconSize,
          fontFamily: icon!.fontFamily,
          package: icon!.fontPackage,
          shadows: iconShadows,
        ),
      ),
    );

    if (icon!.matchTextDirection) {
      switch (textDirection) {
        case TextDirection.rtl:
          iconWidget = Transform(
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            alignment: Alignment.center,
            transformHitTests: false,
            child: iconWidget,
          );
          break;
        case TextDirection.ltr:
          break;
      }
    }

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Center(
        child: iconWidget,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        IconDataProperty('icon', icon, ifNull: '<empty>', showName: false));
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(DoubleProperty('fill', fill, defaultValue: null));
    properties.add(DoubleProperty('weight', weight, defaultValue: null));
    properties.add(DoubleProperty('grade', grade, defaultValue: null));
    properties
        .add(DoubleProperty('opticalSize', opticalSize, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties
        .add(IterableProperty<Shadow>('shadows', shadows, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}

/*
Example game pointers

https://www.construct.net/en/game-assets/graphics/icons/game-cursors-1484#


USING AssetImage


FROM : https://api.flutter.dev/flutter/painting/AssetImage-class.html

Other info:
https://docs.flutter.dev/development/ui/assets-and-images



class MyImage extends StatefulWidget {
  const MyImage({
    super.key,
    required this.assetImage,
  });

  final AssetImage assetImage;

  @override
  State<MyImage> createState() => _MyImageState();
}

class _MyImageState extends State<MyImage> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We call _getImage here because createLocalImageConfiguration() needs to
    // be called again if the dependencies changed, in case the changes relate
    // to the DefaultAssetBundle, MediaQuery, etc, which that method uses.
    _getImage();
  }

  @override
  void didUpdateWidget(MyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assetImage != oldWidget.assetImage) {
      _getImage();
    }
  }

  void _getImage() {
    final ImageStream? oldImageStream = _imageStream;
    _imageStream = widget.assetImage.resolve(createLocalImageConfiguration(context));
    if (_imageStream!.key != oldImageStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateImage);
      oldImageStream?.removeListener(listener);
      _imageStream!.addListener(listener);
    }
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _imageInfo?.dispose();
      _imageInfo = imageInfo;
    });
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_updateImage));
    _imageInfo?.dispose();
    _imageInfo = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawImage(
      image: _imageInfo?.image, // this is a dart:ui Image object
      scale: _imageInfo?.scale ?? 1.0,
    );
  }
}


*/
