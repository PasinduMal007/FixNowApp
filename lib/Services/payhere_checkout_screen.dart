import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayHereCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const PayHereCheckoutScreen({super.key, required this.payload});

  @override
  State<PayHereCheckoutScreen> createState() => _PayHereCheckoutScreenState();
}

class _PayHereCheckoutScreenState extends State<PayHereCheckoutScreen> {
  late final WebViewController _controller;

  bool _popped = false;

  @override
  void initState() {
    super.initState();

    final html = _buildAutoSubmitHtml(widget.payload);

    final returnUrl = (widget.payload['return_url'] ?? '').toString();
    final cancelUrl = (widget.payload['cancel_url'] ?? '').toString();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;

            // Close when PayHere redirects to return/cancel
            if (_isSameTarget(url, returnUrl)) {
              _popOnce(true); // user completed checkout
              return NavigationDecision.prevent;
            }

            if (_isSameTarget(url, cancelUrl)) {
              _popOnce(false); // user cancelled
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: 'https://fixnow-app-75722.web.app');
  }

  void _popOnce(bool result) {
    if (_popped) return;
    _popped = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  bool _isSameTarget(String current, String target) {
    if (target.isEmpty) return false;

    // Simple startsWith is enough for most cases:
    // - fixnow://payment-success
    // - https://yourdomain.com/payment/success
    return current.startsWith(target);
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');

  String _buildAutoSubmitHtml(Map<String, dynamic> payload) {
    final checkoutUrl = (payload['checkoutUrl'] ?? '').toString();

    final formFields = <String, String>{
      'merchant_id': (payload['merchant_id'] ?? '').toString(),
      'return_url': (payload['return_url'] ?? '').toString(),
      'cancel_url': (payload['cancel_url'] ?? '').toString(),
      'notify_url': (payload['notify_url'] ?? '').toString(),
      'order_id': (payload['order_id'] ?? '').toString(),
      'items': (payload['items'] ?? '').toString(),
      'currency': (payload['currency'] ?? '').toString(),
      'amount': (payload['amount'] ?? '').toString(),
      'first_name': (payload['first_name'] ?? '').toString(),
      'last_name': (payload['last_name'] ?? '').toString(),
      'email': (payload['email'] ?? '').toString(),
      'phone': (payload['phone'] ?? '').toString(),
      'address': (payload['address'] ?? '').toString(),
      'city': (payload['city'] ?? '').toString(),
      'country': (payload['country'] ?? '').toString(),
      'hash': (payload['hash'] ?? '').toString(),
    };

    final inputs = formFields.entries
        .map(
          (e) =>
              '<input type="hidden" name="${_escape(e.key)}" value="${_escape(e.value)}" />',
        )
        .join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <p style="font-family: Arial; padding: 12px; text-align: center;">Redirecting to PayHere...</p>
  <div style="text-align: center; margin-top: 20px;">
    <button onclick="document.getElementById('payhereForm').submit()" style="padding: 10px 20px; font-size: 16px; background-color: #4A7FFF; color: white; border: none; border-radius: 5px; cursor: pointer;">
      Click here if not redirected
    </button>
  </div>
  <form id="payhereForm" method="post" action="$checkoutUrl">
    $inputs
  </form>
  <script>
    document.getElementById("payhereForm").submit();
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayHere Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _popOnce(false),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
