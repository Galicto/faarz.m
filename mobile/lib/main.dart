import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FAARZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF060709),
      ),
      home: const WebAppScreen(),
    );
  }
}

class WebAppScreen extends StatefulWidget {
  const WebAppScreen({super.key});

  @override
  State<WebAppScreen> createState() => _WebAppScreenState();
}

class _WebAppScreenState extends State<WebAppScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _controllerReady = false;
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _requestPermissions();
    await _startLocalServer();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.photos,
    ].request();
  }

  Future<void> _startLocalServer() async {
    final String htmlContent = await rootBundle.loadString('assets/index.html');

    // Local HTTP server so external CDN scripts (Leaflet maps) can load
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final int port = _server!.port;

    _server!.listen((HttpRequest request) {
      request.response
        ..headers.contentType = ContentType.html
        ..write(htmlContent)
        ..close();
    });

    // Configure WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF060709))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    // Android-specific: geolocation + file chooser for photo upload
    if (_controller.platform is AndroidWebViewController) {
      final ac = _controller.platform as AndroidWebViewController;

      // Auto-grant geolocation for map
      await ac.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(allow: true, retain: true);
        },
        onHidePrompt: () {},
      );

      // Handle file upload / camera capture
      await ac.setOnShowFileSelector((FileSelectorParams params) async {
        final ImagePicker picker = ImagePicker();

        // Show a bottom sheet to let user choose camera or gallery
        final source = await showModalBottomSheet<ImageSource>(
          context: context,
          backgroundColor: const Color(0xFF1a2330),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Upload Photo',
                    style: TextStyle(
                      color: Color(0xFFb8f928),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Color(0xFFb8f928)),
                    title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: Color(0xFFff9f0a)),
                    title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );

        if (source == null) return [];

        final XFile? image = await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1200,
        );

        if (image == null) return [];
        return [image.path];
      });

      // Performance: enable hardware acceleration, smooth scrolling
      await ac.setMediaPlaybackRequiresUserGesture(false);
    }

    await _controller.loadRequest(Uri.parse('http://127.0.0.1:$port'));

    if (mounted) setState(() => _controllerReady = true);
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060709),
      body: Stack(
        children: [
          if (_controllerReady)
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF060709),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFb8f928),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
