import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  _Logger.log(
      'uisettings cursorSize.width x height=${cursorSize.Width} x ${cursorSize.Height}');
  final systemDPI = win32.GetDpiForSystem();
  _Logger.log('systemDPI = $systemDPI');
  final prevDPI = win32.SetThreadCursorCreationScaling(192);
  _Logger.log(
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

  _Logger.log(
      'DPI_AWARENESS_CONTEXT_UNAWARE                  $DPI_AWARENESS_CONTEXT_UNAWARE             ');
  _Logger.log(
      'DPI_AWARENESS_CONTEXT_SYSTEM_AWARE             $DPI_AWARENESS_CONTEXT_SYSTEM_AWARE        ');
  _Logger.log(
      'DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE        $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE   ');
  _Logger.log(
      'DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2     $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2');
  _Logger.log(
      'DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED        $DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED   ');

  int hWin = win32.GetForegroundWindow();
  int winDPI = win32.GetDpiForWindow(hWin);
  _Logger.log('winDPI = $winDPI');
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
  _Logger.log(chalk.brightRed("initializeCursors() Creating cursors from asset and from icon"));

  CustomMouseCursor.useWebKitImageSet = true; // Optional flag to specify web platform to use `-webkit-image-set` command instead of `image-set` (defaults to true).
  //CustomMouseCursor.useOnlyImageSetCSS = true;   // Optional flag to specify web platform to use `image-set()` css commands only. (defaults to false).
  //CustomMouseCursor.useOnlyURLDataURICursorCSS = true;  // Optional flag to specify web platform use only `url()` css commands. (defaults to false).

  // Example of image asset that has many device pixel ratio versions (1.5x,2.0x,2.5x,3.0x,3.5x,4.0x,8.0x).
  // The exact size required for most DevicePixelRatio will be able to be loaded directly and used
  // without scaling. 
  assetCursor = await CustomMouseCursor.asset(
      "assets/cursors/startrek_mousepointer.png",
      hotX: 18,
      hotY: 0);

  // Example of image asset that has only device pixel ratio versions (1.0x ands 2.5x).
  // In this case if the devicePixelRatio was 2.0x the 2.5x asset would be loaded and
  // scaled down to 2.0x size.
  assetCursorOnly25 = await CustomMouseCursor.asset(
      "assets/cursors/startrek_mousepointer25Only.png",
      hotX: 18,
      hotY: 0);

  // Example of image asset only at 8x native DevicePixelRatio so will get scaled down
  // to most/all encoutered DPR's.
  assetNative8x = await CustomMouseCursor.exactAsset(
      "assets/cursors/star-trek-mouse-pointer-cursor292x512.png",
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
      size: 24,
      hotX: 22,
      hotY: 17,
      color: Colors.pinkAccent,
      shadows: shadows);

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
      "assets/cursors/example_game_cursor_64x64.png",
      hotX: 2,
      hotY: 2,
      nativeDevicePixelRatio: 2.0);
}

/*
void viewsReport(String message) {
  _Logger.log('Entering viewsReport() - $message');
  for(final view in WidgetsBinding.instance.platformDispatcher.views) {
    view.platformDispatcher.onMetricsChanged = () {
      _Logger.log('view.platformdispatcher.onMetricsChanged() !!!!!');
    };
    _Logger.log('View is DPR ${view.devicePixelRatio}   view.viewId=${view.viewId}');
  }
  final implicitView = PlatformDispatcher.instance.implicitView;
  _Logger.log('PlatformDispatcher.instance.implicitView.viewId = ${implicitView?.viewId ?? 'implicitView IS NULL'} ');
  _Logger.log('leaving viewsReport()');
}
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

/*
  WidgetsBinding.instance.platformDispatcher.onMetricsChanged = () {
    _Logger.log('platformDispatcher - onMetricsChanged() (set in main) !!!');
  };
*/
  //CustomMouseCursor.noOnMetricsChangedHook = true;
  //KLUDGE//viewsReport('Called from MAIN');

  await initializeCursors();

  runApp(const MyApp());

  //called immediately// CustomMouseCursor.disposeAll();
}

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
    _Logger.log(chalk.brightYellow('WIDGETS onChangeMetrics() callback called!!!!'));
    setState(() {
      double prevDPR = _lastDevicePixelRatio;
      _lastSize = WidgetsBinding.instance.window.physicalSize;
      _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
      _Logger.log(
          chalk.yellow('setState() in didChangeMetrics() Window size is $_lastSize  prevDPR=$prevDPR  new DevicePixelRatio=$_lastDevicePixelRatio'));

      CustomMouseCursor.ensurePointersMatchDevicePixelRatio(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _Logger.log(chalk.yellow('WIDGETS didChangeDependencies() callback called!!!!'));

    double prevDPR = _lastDevicePixelRatio;
    _lastSize = WidgetsBinding.instance.window.physicalSize;
    _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    _Logger.log(
        chalk.yellow('in didChangeDependencies() Window size is $_lastSize   prevDPR=$prevDPR  new DevicePixelRatio=$_lastDevicePixelRatio'));

    CustomMouseCursor.ensurePointersMatchDevicePixelRatio(context);
  }

  void selectCursorCallback(CustomMouseCursor cursor) {
    _Logger.log('Changing to cursor key=${cursor.key}');
    //queryWin32();
    setState(() {
      currentDrawCursor = cursor;
      _signatureController.clear();
    });
  }

  @override
  void initState() {
    _Logger.log(chalk.brightRed('MyApp initState() called'));
    super.initState();

    _lastSize = WidgetsBinding.instance.window.physicalSize;
    _lastDevicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    _Logger.log(
        chalk.red('Window size is $_lastSize    _lastDevicePixelRatio=$_lastDevicePixelRatio'));
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
          title: RichText(
            text: TextSpan(
              text: 'CustomMouseCursor Example and Interactive Test App',
              style:
                  TextStyle(fontSize: 20), //DefaultTextStyle.of(context).style,
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
                  'CustomMouseCursor.asset("assets/cursors/startrek_mousepointer.png", hotX:18, hotY:0)',
              color: Colors.indigoAccent,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetCursorOnly25,
              message: 'Click to Select Asset (Only 1.0 & 2.5x) Cursor',
              note:
                  '(only 1.0x and 2.5x assets present) (should be identical to above)',
              details:
                  'CustomMouseCursor.asset("assets/cursors/startrek_mousepointer25Only.png", hotX:18, hotY:0)',
              color: Colors.blue,
              selectCursorCallback: selectCursorCallback,
            ),
            CursorTesterSelectorRegion(
              assetNative8x,
              message: 'Click to Select 8x DPR ExactAsset Cursor',
              note:
                  '(single 8.0x exactAsset specified) (should be identical to above)',
              details:
                  'CustomMouseCursor.exactAsset("assets/cursors/star-trek-mouse-pointer-cursor292x512.png", hotX: 144, hotY: 0, nativeDevicePixelRatio: 8.0);',
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
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          )),
                    if (note2 != null) const SizedBox(width: 10),
                    if (note2 != null)
                      Text(note2!,
                          style: const TextStyle(
                            fontSize: 16,
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

/*
Future<img2.Image> getImage(Uint8List bytes) async {
  img = img2.decodePng(bytes)!;
  return img;
}
*/
