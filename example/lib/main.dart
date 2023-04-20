import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:custom_mouse_cursor/custom_mouse_cursor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/sharp.dart';
import 'package:signature/signature.dart';
import 'package:chalkdart/chalk.dart';

class _Logger {
  static void log(String message) {
    debugPrint(message);
  }
}

late CustomMouseCursor assetCursor;
late CustomMouseCursor assetCursorOnly25;
late CustomMouseCursor assetCursorNative8x;
late CustomMouseCursor iconCursor;
late CustomMouseCursor msIconCursor;
late CustomMouseCursor assetCursorSingleSize;
late CustomMouseCursor catUiImageCursor;
late CustomMouseCursor helloKittyCursorNative8x;

/// Change this to true illustrates the widget calling the CustomMouseCursor DPR handler function
/// during didChangeDependencies call.
/// It is included here ONLY for testing that CustomMouseCursor does not interfere with these
/// events handling methods! (Whether or not CustomMouseCursor.noOnMetricsChangedHook is set to true).
const illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeDependencies =
    false;
const illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeMetricsCallback =
    false;
const includeHelloKitty8xExample = false;

Future<void> initializeCursors() async {
  _Logger.log(chalk.brightRed(
      'initializeCursors() Creating cursors from asset and from icon'));

  CustomMouseCursor.useWebKitImageSet =
      true; // Optional flag to specify web platform to use `-webkit-image-set` command instead of `image-set` (defaults to true).
  //CustomMouseCursor.useOnlyImageSetCSS = true;   // Optional flag to specify web platform to use `image-set()` css commands only. (defaults to false).
  //CustomMouseCursor.useOnlyURLDataURICursorCSS = true;  // Optional flag to specify web platform use only `url()` css commands. (defaults to false).

  // Example of image asset that has many device pixel ratio versions (1.5x,2.0x,2.5x,3.0x,3.5x,4.0x,8.0x).
  // The exact size required for most DevicePixelRatio will be able to be loaded directly and used
  // without scaling.
  assetCursor = await CustomMouseCursor.asset(
      'assets/cursors/startrek_mousepointer.png',
      hotX: 18,
      hotY: 0);

  // Example of image asset that has only device pixel ratio versions (1.0x ands 2.5x).
  // In this case if the devicePixelRatio was 2.0x the 2.5x asset would be loaded and
  // scaled down to 2.0x size.
  assetCursorOnly25 = await CustomMouseCursor.asset(
      'assets/cursors/startrek_mousepointer25Only.png',
      hotX: 18,
      hotY: 0);

  // Example of image asset only at 8x native DevicePixelRatio so will get scaled down
  // to most/all encoutered DPR's.
  assetCursorNative8x = await CustomMouseCursor.exactAsset(
      'assets/cursors/star-trek-mouse-pointer-cursor292x512.png',
      hotX: 144,
      hotY: 0,
      nativeDevicePixelRatio: 8.0);

  // Example of a custom cursor created from a icon, with drop shadow added.
  List<Shadow> shadows = [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.8),
      offset: Offset(4, 3),
      blurRadius: 3,
      spreadRadius: 2,
    ),
  ];
  iconCursor = await CustomMouseCursor.icon(Icons.redo,
      size: 24, hotX: 22, hotY: 17, color: Colors.pinkAccent, shadows: shadows);

  // example of custom cursor created from a icon that is filled, colored blue and
  // added drop shadow.
  msIconCursor = await CustomMouseCursor.icon(
      MaterialSymbols.arrow_selector_tool,
      size: 32,
      hotX: 8,
      hotY: 2,
      fill: 1,
      color: Colors.blueAccent,
      shadows: shadows);

  // another exactAsset example where the supplied image asset is a 2.0x image.  This will
  // be scaled down at 1.0x devicePixelRatios and scaled up for >2.0x device pixel ratios.
  assetCursorSingleSize = await CustomMouseCursor.exactAsset(
      'assets/cursors/example_game_cursor_64x64.png',
      hotX: 2,
      hotY: 2,
      nativeDevicePixelRatio: 2.0);

  // Now this is example of [image] use.  This is intended for more of a 'power user' interface
  // as it is lower level in that it accepts ui.Image objects. (Image from `import 'dart:ui'`).
  var rawBytes = await rootBundle
      .load('assets/cursors/cat_cursor4xWithPinkShadow.png'); // 196x272
  var rawUintList = rawBytes.buffer.asUint8List();
  final catCursorUiImage4x = await decodeImageFromList(rawUintList);
  rawBytes = await rootBundle
      .load('assets/cursors/cat_cursor2xWithBlueShadow.png'); // 98x136
  rawUintList = rawBytes.buffer.asUint8List();
  final ui.Image catCursorUiImage2x = await decodeImageFromList(rawUintList);
  // We create the image cursor with the 4.0x image - this could be the only image needed and all
  // devicePixelRatios will be drived from this image by scaling..
  catUiImageCursor = await CustomMouseCursor.image(catCursorUiImage4x,
      hotX: 4,
      hotY: 30,
      thisImagesDevicePixelRatio: 4.0,
      finalizeForCurrentDPR: false);

  // but we can also add additional images at other DPR to supply specific images for those
  // DPR without the need to scale.
  // By looking at the color of the shadow you can tell which cursor image is being used.
  // Experiment with commenting out the following and see that the shadow changes to pink.
  const illustrateUseOfAddtionalImages = false;
  if (illustrateUseOfAddtionalImages) {
    await catUiImageCursor.addImage(catCursorUiImage2x,
        thisImagesDevicePixelRatio: 2.0);
  }
  await catUiImageCursor.finalizeImages();

  // Example of image asset only at 36pixel 8x native DevicePixelRatio so will always get scaled down
  helloKittyCursorNative8x = await CustomMouseCursor.exactAsset(
    'assets/cursors/hello_kitty_cursor_8x.png',
    hotX: 36,
    hotY: 162,
    nativeDevicePixelRatio: 8.0,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This is here for testing to verify CustomMouseCursor does not interfere with these callbacks.
  // (Whether it is handling DPR changes automatically or not).
  if (illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeDependencies ||
      illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeMetricsCallback) {
    CustomMouseCursor.noOnMetricsChangedHook = true;
    _Logger.log(chalk.color.purple(
        'Setting ourselves to handle DPR and preventing CustomMouseCursor from hooking onMetricsChanged() event handler'));
  }
  // following is for future flutter multiwindow support
  //CustomMouseCursor.useViewsForOnMetricsChangedHook = false;   // if true it loops over new views array which can support multiple windows

  _Logger.log(
      'CustomMouseCursor.noOnMetricsChangedHook=${CustomMouseCursor.noOnMetricsChangedHook}   CustomMouseCursor.useViewsForOnMetricsChangedHook=${CustomMouseCursor.useViewsForOnMetricsChangedHook}');

  await initializeCursors();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final SignatureController _signatureController;
  late final Widget _signatureCanvas;

  CustomMouseCursor? currentDrawCursor;

  late Size _lastSize;
  late double _lastDevicePixelRatio;

  /*
    Illustrate OPTIONAL (power user) use of manual onMetricsChanged handling.
    This is included here to verify CustomMouseCursor does not interfere with didChangeMetrics()
    callbacks.
  */
  @override
  void didChangeMetrics() {
    _Logger.log(chalk.brightYellow(
        'WIDGETS didChangeMetrics() callback called!!!!   illustrateManualHandlingOfDevicePixelRatioChangesForCustomCursorsWithDidChangeMetricsCallback=$illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeMetricsCallback'));
    if (illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeMetricsCallback) {
      setState(() {
        double prevDPR = _lastDevicePixelRatio;
        /* deprecated way
        _lastSize = WidgetsBinding.instance.window.physicalSize;
        _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
        */
        _lastSize = WidgetsBinding
            .instance.platformDispatcher.implicitView!.physicalSize;
        _lastDevicePixelRatio = WidgetsBinding
            .instance.platformDispatcher.implicitView!.devicePixelRatio;
        _Logger.log(chalk.yellow(
            '  setState() in didChangeMetrics() Window size is $_lastSize  prevDPR=$prevDPR  new DevicePixelRatio=$_lastDevicePixelRatio'));
        _Logger.log(chalk.color.orange(
            '    calling ensurePointersMatchDevicePixelRatio(context)'));

        CustomMouseCursor.ensurePointersMatchDevicePixelRatio(context);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _Logger.log(chalk.yellow(
        'WIDGETS didChangeDependencies() callback called - illustrateManualHandlingOfDevicePixelRatioChangesForCustomCursors=$illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeDependencies!!!!'));

    // illustrate completely optional manual handling of DPR changes for CustomMouseCursor.
    if (illustrateManualHandlingOfDPRChangesForCursorsWithDidChangeDependencies) {
      double prevDPR = _lastDevicePixelRatio;
      /* deprecated way
      _lastSize = WidgetsBinding.instance.window.physicalSize;
      _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      */
      _lastSize =
          WidgetsBinding.instance.platformDispatcher.implicitView!.physicalSize;
      _lastDevicePixelRatio = WidgetsBinding
          .instance.platformDispatcher.implicitView!.devicePixelRatio;
      _Logger.log(chalk.yellow(
          '  didChangeDependencies() Window size is $_lastSize   prevDPR=$prevDPR  new DevicePixelRatio=$_lastDevicePixelRatio'));
      _Logger.log(chalk.color
          .orange('    calling ensurePointersMatchDevicePixelRatio(context)'));
      CustomMouseCursor.ensurePointersMatchDevicePixelRatio(context);
    }
  }

  void selectCursorCallback(CustomMouseCursor cursor) {
    _Logger.log('Changing to drawing area cursor to key=${cursor.key}');
    setState(() {
      currentDrawCursor = cursor;
      _signatureController.clear();
    });
  }

  @override
  void initState() {
    _Logger.log(chalk.brightRed('MyApp initState() called'));
    super.initState();

    /* deprecated way
    _lastSize = WidgetsBinding.instance.window.physicalSize;
    _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    */
    _lastSize =
        WidgetsBinding.instance.platformDispatcher.implicitView!.physicalSize;
    _lastDevicePixelRatio = WidgetsBinding
        .instance.platformDispatcher.implicitView!.devicePixelRatio;

    _Logger.log(chalk.red(
        'Window size is $_lastSize    _lastDevicePixelRatio=$_lastDevicePixelRatio'));

    // included only to verify that CustomMouseCursor does not interfere with this.
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
          title: RichText(
            text: TextSpan(
              text: 'CustomMouseCursor Example and Interactive Test App',
              style: const TextStyle(fontSize: 20),
              children: const <TextSpan>[
                TextSpan(
                    text:
                        '\n        (move window to monitor with different devicePixelRatio to support for test varying DPR)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
        ),
        body: Center(
            child: ListView(
          children: [
            CursorTesterSelectorRegion(
              assetCursor,
              message: 'Click to Select Asset Cursor',
              note:
                  '(with 1.0x,1.5x,2.0x,2.5x,3.0x,3.5x,4.0x, and 8.0x assets present)',
              note2: '(should appear as tall as this row)',
              details:
                  "CustomMouseCursor.asset('assets/cursors/startrek_mousepointer.png', hotX:18, hotY:0)",
              color: Colors.indigoAccent,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetCursorOnly25,
              message: 'Click to Select Asset (Only 1.0 & 2.5x) Cursor',
              note:
                  '(only 1.0x and 2.5x assets present) (should be identical to above)',
              details:
                  "CustomMouseCursor.asset('assets/cursors/startrek_mousepointer25Only.png', hotX:18, hotY:0)",
              color: Colors.blue,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetCursorNative8x,
              message: 'Click to Select 8x DPR ExactAsset Cursor',
              note:
                  '(single 8.0x exactAsset specified) (should be identical to above)',
              details:
                  "CustomMouseCursor.exactAsset('assets/cursors/star-trek-mouse-pointer-cursor292x512.png', hotX: 144, hotY: 0, nativeDevicePixelRatio: 8.0);",
              color: const ui.Color.fromARGB(255, 26, 133, 172),
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              iconCursor,
              message: 'Click to Select Icon Cursor',
              details:
                  'CustomMouseCursor.icon( Icons.redo, size: 24, hotX:22, hotY:17, color:Colors.red, shadows:shadows)',
              color: Colors.green,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              msIconCursor,
              message: 'Click to Select Material Symbols Icon Cursor',
              note: '(using material_symbols_icons package)',
              details:
                  'CustomMouseCursor.icon( MaterialSymbols.arrow_selector_tool, size: 32, hotX: 8, hotY: 2, fill: 1, color: Colors.blueAccent )',
              color: Colors.yellow,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetCursorSingleSize,
              message: 'Click to Select ExactAsset Cursor',
              note: '(DPR 2.0 asset/hotspot coords)',
              details:
                  "CustomMouseCursor.exactAsset('assets/cursors/example_game_cursor_64x64.png',  hotX: 2, hotY: 2, nativeDevicePixelRatio: 2.0)",
              color: Colors.orange,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              catUiImageCursor,
              message: 'Click to Select Image Cursor',
              note: '(created with a single ui.Image at DPR 4.0x)',
              details:
                  'CustomMouseCursor.image( uiImage, hotX: 4, hotY: 30, thisImagesDevicePixelRatio: 4.0)',
              color: Colors.redAccent,
              selectCursorCallback: selectCursorCallback,
            ),
            if (includeHelloKitty8xExample)
              CursorTesterSelectorRegion(
                helloKittyCursorNative8x,
                message: 'Click to Exact Asset 8x cursor',
                note:
                    '(created with a single asset at DPR 8.0x scaling to 36 logical pixels)',
                details:
                    "CustomMouseCursor.image( 'assets/cursors/hello_kitty_camera_cursor_8x.png', hotX: 36, hotY: 162, nativeDevicePixelRatio: 8.0)",
                color: ui.Color.fromARGB(255, 255, 13, 13),
                selectCursorCallback: selectCursorCallback,
              ),
            MouseRegion(
              cursor: currentDrawCursor != null
                  ? currentDrawCursor!
                  : SystemMouseCursors.precise,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                        // todo: const  but Not on stable channel
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                              "Click/drag to draw with mouse and to test cursor's hot spot (X,Y).",
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

typedef SelectCursorCallback = void Function(CustomMouseCursor);

class CursorTesterSelectorRegion extends StatelessWidget {
  final Color color;
  final SelectCursorCallback? selectCursorCallback;
  final String message;
  final String? note;
  final String? note2;
  final String? details;
  final CustomMouseCursor cursor;

  const CursorTesterSelectorRegion(this.cursor,
      {super.key,
      required this.message,
      this.note,
      this.note2,
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
            border: const Border(
              bottom: BorderSide(color: Colors.black, width: 1),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                    if (note != null) const SizedBox(width: 20),
                    if (note != null)
                      Text(note!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          )),
                    if (note2 != null) const SizedBox(width: 10),
                    if (note2 != null)
                      Text(note2!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
                    child: Text(details!,
                        style: //TextStyle(fontSize: 16, backgroundColor: Colors.grey),
                            GoogleFonts.jetBrainsMono(
                                fontSize: 12, backgroundColor: Colors.grey)),
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
