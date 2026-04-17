import 'dart:async';

import 'package:cross/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String _recaptchaSiteKey = '6LeAvq4sAAAAAJKps85dI_qFhLcB1nDq2JEXjy3T';

const String _captchaHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background-color: #1a1a2e;
    }
  </style>
  <script src="https://www.google.com/recaptcha/api.js?onload=onRecaptchaLoad&render=explicit" async defer></script>
  <script>
    function onRecaptchaLoad() {
      grecaptcha.render('captcha-container', {
        'sitekey': '$_recaptchaSiteKey',
        'theme': 'dark',
        'callback': function(token) {
          if (window.CaptchaChannel) {
            CaptchaChannel.postMessage(token);
          }
        }
      });
    }
  </script>
</head>
<body>
  <div id="captcha-container"></div>
</body>
</html>
''';

class CaptchaChallengeScreen extends StatefulWidget {
  const CaptchaChallengeScreen({super.key});

  @override
  State<CaptchaChallengeScreen> createState() => _CaptchaChallengeScreenState();
}

class _CaptchaChallengeScreenState extends State<CaptchaChallengeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  Timer? _timeoutTimer;
  bool _tokenReturned = false;

  @override
  void initState() {
    super.initState();
    _log('CAPTCHA challenge started');

    _controller = WebViewController()
      ..setBackgroundColor(const Color(0xFF1a1a2e))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CaptchaChannel',
        onMessageReceived: (message) {
          final token = message.message.trim();
          if (token.isNotEmpty && mounted && !_tokenReturned) {
            _tokenReturned = true;
            _timeoutTimer?.cancel();
            _log('CAPTCHA token received via JS channel');
            Navigator.of(context).pop(token);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            _log('CAPTCHA page finished loading');
            setState(() {
              _isLoading = false;
            });
            _timeoutTimer?.cancel();
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            _log('CAPTCHA web resource error: ${error.description}');
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
          },
        ),
      )
      ..loadHtmlString(_captchaHtml, baseUrl: 'https://www.pulsify.page');

    _timeoutTimer = Timer(const Duration(seconds: 25), () {
      if (!mounted || _tokenReturned) return;
      if (_isLoading && _error == null) {
        _log('CAPTCHA loading timed out');
        setState(() {
          _error = 'CAPTCHA took too long to load. Please try again.';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[CaptchaChallenge] $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verify CAPTCHA',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _error == null
                ? WebViewWidget(controller: _controller)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              _timeoutTimer?.cancel();
                              _timeoutTimer = Timer(const Duration(seconds: 25), () {
                                if (!mounted || _tokenReturned) return;
                                if (_isLoading && _error == null) {
                                  _log('CAPTCHA retry loading timed out');
                                  setState(() {
                                    _error = 'CAPTCHA took too long to load. Please try again.';
                                    _isLoading = false;
                                  });
                                }
                              });
                              _controller.loadHtmlString(_captchaHtml);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
