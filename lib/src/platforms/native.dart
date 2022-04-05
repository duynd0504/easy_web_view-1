import 'dart:io';
import 'dart:ui';

import 'package:flutter/src/widgets/framework.dart';
import 'package:webview_flutter/webview_flutter.dart' as wv;

import '../extensions.dart';
import 'base.dart';

class NativeWebView extends WebView {
  const NativeWebView({
    required String src,
    required double? width,
    required double? height,
    required void Function()? onLoaded,
    required this.options,
  }) : super(
          src: src,
          width: width,
          height: height,
          onLoaded: onLoaded,
        );

  final WebViewOptions options;

  @override
  State<WebView> createState() => NativeWebViewState();
}

class NativeWebViewState extends WebViewState<NativeWebView> {
  late wv.WebViewController controller;

  @override
  void initState() {
    super.initState();

    // Enable hybrid composition.
    if (Platform.isAndroid) wv.WebView.platform = wv.SurfaceAndroidWebView();

    reload();
  }

  @override
  void didUpdateWidget(covariant NativeWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      reload();
    }
  }

  reload() {
    controller.loadUrl(widget.src.isValidUrl ? widget.src : widget.src.dataUrl);
  }

  @override
  Widget builder(BuildContext context, Size size, String contents) {
    return wv.WebView(
      key: widget.key,
      javascriptMode: wv.JavascriptMode.unrestricted,
      onWebViewCreated: (webViewController) {
        controller = webViewController;
        if (widget.onLoaded != null) {
          widget.onLoaded!();
        }
      },
      navigationDelegate: (navigationRequest) async {
        if (widget.options.navigationDelegate == null) {
          return wv.NavigationDecision.navigate;
        }
        final _navDecision = await widget.options
            .navigationDelegate!(WebNavigationRequest(navigationRequest.url));
        return _navDecision == WebNavigationDecision.prevent
            ? wv.NavigationDecision.prevent
            : wv.NavigationDecision.navigate;
      },
      javascriptChannels: widget.options.crossWindowEvents.isNotEmpty
          ? widget.options.crossWindowEvents
              .map(
                (crossWindowEvent) => wv.JavascriptChannel(
                  name: crossWindowEvent.name,
                  onMessageReceived: (javascriptMessage) =>
                      crossWindowEvent.eventAction(javascriptMessage.message),
                ),
              )
              .toSet()
          : Set<wv.JavascriptChannel>(),
    );
  }
}
