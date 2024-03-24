import 'dart:async';
import 'error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OneSignal.initialize("2e64fbf3-5c2b-448c-a6e8-78bf2f494b9e");

  runApp(const MyApp());
}

var webUrl = "https://bacodehub.github.io/main/";
Color temaRengi = Colors.black;
Color karsitrenk = calculateContrastColor(temaRengi) > 128 ? Colors.black : Colors.white;

int calculateContrastColor(Color color) {
  int averageColor = ((color.red + color.green + color.blue) / 3).round();
  return averageColor;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: temaRengi,
      systemNavigationBarColor: temaRengi,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Web Site App',
      theme: ThemeData(primaryColor: Colors.black),
      debugShowCheckedModeBanner: false,
      home: const MyWebView(),
    );
  }
}

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyWebViewState createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late InAppWebViewController _webViewController;
  PullToRefreshController? pullToRefreshController;
  bool isLoading = true;
  bool showErrorPage = false;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              backgroundColor: temaRengi,
              color: karsitrenk,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _webViewController.loadUrl(
                    urlRequest:
                        URLRequest(url: await _webViewController.getUrl()));
              }
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: temaRengi,
      body: Stack(
        children: [
          if (isLoading) buildLoadingIndicator(),
          buildWebView(),
        ],
      ),
    );
  }

  Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget buildWebView() {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          _onPopInvoked();
        }
      },
      child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
            bottomRight: Radius.circular(30.0),
            bottomLeft: Radius.circular(30.0),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(webUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,
                    iframeAllowFullscreen: true,
                  ),
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    pullToRefreshController?.endRefreshing();
                    Uri uri = navigationAction.request.url!;
                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if ("intent://".contains(uri.scheme)) {
                        String arananKisim =
                            "https://${uri.toString().substring(uri.toString().indexOf("intent://") + "intent://".length, uri.toString().indexOf("&"))}";
                        uri = Uri.parse(arananKisim);
                      }

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    Timer(const Duration(seconds: 1), () {
                      setState(() {
                        isLoading = false;
                      });
                    });
                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController?.endRefreshing();
                  },
                  // ignore: deprecated_member_use
                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      isLoading = false;
                    });

                    Color backgroundcolor =
                        calculateContrastColor(temaRengi) < 120
                            ? Colors.white
                            : Colors.red;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: backgroundcolor,
                      content: Text(
                        message == "net::ERR_INTERNET_DISCONNECTED"
                            ? "İnternet bağlantısı kesildi"
                            : message,
                        style: TextStyle(
                            color: backgroundcolor == Colors.white
                                ? Colors.black
                                : Colors.white),
                      ),
                    ));
                    setState(() {
                      showErrorPage = true;
                    });
                  },
                ),
                if (showErrorPage) const CustomErrorPage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPopInvoked() {
    _webViewController.canGoBack().then((value) {
      if (showErrorPage) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyWebView()),
        );
      }
      if (value) {
        _webViewController.goBack();
        return false;
      } else {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Uygulamadan çıkmak istiyor musunuz?',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all<Color>(
                    temaRengi.withOpacity(0.1),
                  ),
                ),
                child: const Text(
                  'Hayır',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all<Color>(
                    temaRengi.withOpacity(0.1),
                  ),
                ),
                child: const Text(
                  'Evet',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      }
    });
  }
}
