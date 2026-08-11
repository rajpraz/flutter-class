import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/utils/error_mapper.dart';
import 'package:untitled3/features/payments/domain/entities/esewa_initiation.dart';
import 'package:untitled3/features/payments/presentation/providers/payment_providers.dart';

/// eSewa's ePay v2 API takes a *form POST* of signed fields, not a plain
/// GET URL — there's no native eSewa SDK for Flutter (unlike Khalti, which
/// ships `khalti_flutter`), so the standard mobile-integration approach is
/// to load a tiny self-submitting HTML form into a WebView pointed at
/// eSewa's hosted payment page, then watch for the redirect back to a
/// (non-resolving, purely-recognized) success/failure marker URL.
///
/// **Sandbox only.** `_formUrl` below is eSewa's rc- (release-candidate/
/// test) endpoint. Swap it for `https://epay.esewa.com.np/api/epay/main/v2/form`
/// before a production deploy — this file has no environment-awareness of
/// its own (the client has no build-time env concept the way
/// functions/src/config.ts does), so this is a manual step, called out here
/// deliberately rather than silently defaulting to sandbox in production.
///
/// Server-side verification (`verifyEsewaPayment`) is what actually confirms
/// payment — reaching the success marker URL only means eSewa *reported*
/// success in its own redirect, which this page never trusts on its own,
/// exactly like the Khalti flow never trusts the SDK's `onSuccess` alone.
class EsewaPaymentPage extends ConsumerStatefulWidget {
  final String orderId;

  const EsewaPaymentPage({super.key, required this.orderId});

  @override
  ConsumerState<EsewaPaymentPage> createState() => _EsewaPaymentPageState();
}

class _EsewaPaymentPageState extends ConsumerState<EsewaPaymentPage> {
  static const _formUrl = 'https://rc-epay.esewa.com.np/api/epay/main/v2/form';
  static const _successMarker = 'https://poojapasal.app/esewa/success';
  static const _failureMarker = 'https://poojapasal.app/esewa/failure';

  WebViewController? _controller;
  bool _initiating = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initiate();
  }

  Future<void> _initiate() async {
    try {
      final EsewaInitiation fields =
          await ref.read(paymentControllerProvider.notifier).initiateEsewa(widget.orderId);
      if (!mounted) return;
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: _handleNavigation,
        ))
        ..loadHtmlString(_buildAutoSubmitHtml(fields), baseUrl: _formUrl);
      setState(() {
        _controller = controller;
        _initiating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initiating = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }

  String _buildAutoSubmitHtml(EsewaInitiation fields) {
    // amount + tax_amount + service/delivery charges must sum to
    // total_amount per eSewa's own validation; only total_amount,
    // transaction_uuid, and product_code are actually signed (see
    // functions/src/payments/esewaVerify.ts), so the rest are zeroed.
    return '''
<!DOCTYPE html>
<html>
<body onload="document.forms[0].submit()">
  <form action="$_formUrl" method="POST">
    <input type="hidden" name="amount" value="${fields.totalAmount}" />
    <input type="hidden" name="tax_amount" value="0" />
    <input type="hidden" name="total_amount" value="${fields.totalAmount}" />
    <input type="hidden" name="transaction_uuid" value="${fields.transactionUuid}" />
    <input type="hidden" name="product_code" value="${fields.productCode}" />
    <input type="hidden" name="product_service_charge" value="0" />
    <input type="hidden" name="product_delivery_charge" value="0" />
    <input type="hidden" name="success_url" value="$_successMarker" />
    <input type="hidden" name="failure_url" value="$_failureMarker" />
    <input type="hidden" name="signed_field_names" value="${fields.signedFieldNames}" />
    <input type="hidden" name="signature" value="${fields.signature}" />
  </form>
</body>
</html>
''';
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    if (request.url.startsWith(_successMarker)) {
      _onRedirectSucceeded();
      return NavigationDecision.prevent;
    }
    if (request.url.startsWith(_failureMarker)) {
      Navigator.of(context).pop(false);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _onRedirectSucceeded() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      // eSewa's redirect claiming success is never trusted on its own —
      // this call independently confirms with eSewa's server-to-server
      // status API before the order is ever marked paid.
      await ref.read(paymentControllerProvider.notifier).verifyEsewa(widget.orderId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pay with eSewa')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Back to Checkout'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null) WebViewWidget(controller: _controller!),
                if (_initiating || _verifying)
                  Container(
                    color: Colors.black26,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            _verifying ? 'Confirming payment...' : 'Connecting to eSewa...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
