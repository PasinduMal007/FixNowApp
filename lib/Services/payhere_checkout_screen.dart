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

    final returnUrl = (widget.payload['return_url'] ?? '').toString().trim();
    final cancelUrl = (widget.payload['cancel_url'] ?? '').toString().trim();

    final html = _buildAutoSubmitHtml(widget.payload);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;

            if (_isSameTarget(url, returnUrl)) {
              _popOnce(true);
              return NavigationDecision.prevent;
            }

            if (_isSameTarget(url, cancelUrl)) {
              _popOnce(false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        html,
        baseUrl: 'https://fixnow-app-75722.web.app', // your hosted domain
      );
  }

  void _popOnce(bool result) {
    if (_popped) return;
    _popped = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  bool _isSameTarget(String current, String target) {
    if (target.isEmpty) return false;
    return current.startsWith(target);
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');

  String _amount2dp(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toStringAsFixed(2);
    final n = num.tryParse(v.toString().trim());
    return n != null ? n.toStringAsFixed(2) : v.toString().trim();
  }

  String _buildAutoSubmitHtml(Map<String, dynamic> payload) {
    String s(dynamic v) => (v ?? '').toString().trim();

    final checkoutUrl = s(payload['checkoutUrl']).isNotEmpty
        ? s(payload['checkoutUrl'])
        : 'https://sandbox.payhere.lk/pay/checkout';

    final formFields = <String, String>{
      'merchant_id': s(payload['merchant_id']),
      'return_url': s(payload['return_url']),
      'cancel_url': s(payload['cancel_url']),
      'notify_url': s(payload['notify_url']),
      'order_id': s(payload['order_id']),
      'items': s(payload['items']),
      'currency': s(payload['currency']),
      'amount': _amount2dp(payload['amount']),
      'first_name': s(payload['first_name']),
      'last_name': s(payload['last_name']),
      'email': s(payload['email']),
      'phone': s(payload['phone']),
      'address': s(payload['address']),
      'city': s(payload['city']),
      'country': s(payload['country']),
      'hash': s(payload['hash']),
    };

    // Keep required fields even if empty (so you catch it early)
    final requiredKeys = <String>{
      'merchant_id',
      'return_url',
      'cancel_url',
      'notify_url',
      'order_id',
      'items',
      'currency',
      'amount',
      'first_name',
      'last_name',
      'email',
      'phone',
      'address',
      'city',
      'country',
      'hash',
    };

    // Remove only non-required empties
    formFields.removeWhere((k, v) => v.isEmpty && !requiredKeys.contains(k));

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
  <p style="font-family: Arial; padding: 12px;">Redirecting to PayHere...</p>
  <form id="payhereForm" method="post" action="${_escape(checkoutUrl)}">
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
