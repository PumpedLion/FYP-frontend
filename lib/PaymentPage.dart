// lib/PaymentPage.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditionally import flutter_inappwebview
// It will throw errors if used on Windows desktop or Web without safeguards,
// so we only initialize/use it if we are on mobile.
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'services/payment_service.dart';
import 'services/auth_service.dart';

class PaymentPage extends StatefulWidget {
  final dynamic manuscript;

  const PaymentPage({super.key, required this.manuscript});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  static const _salmonColor = Color(0xFFFF8B7D);
  static const _khaltiColor = Color(0xFF5C2D91);
  static const _esewaColor = Color(0xFF60BB46);

  String _selectedGateway = 'KHALTI';
  bool _isLoading = false;

  // Manual verification states for browser-based flows
  bool _isPendingVerification = false;
  String? _pendingPidx;
  Timer? _pollingTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Are we on an embedded platform? (Android / iOS)
  bool get _canUseWebView {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _stopPolling();
    _animController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Don't poll if a request is currently in flight
      if (!_isLoading && mounted && _isPendingVerification) {
        _verifyManualFallback(isAutoPolling: true);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  double get _price => (widget.manuscript['price'] ?? 0).toDouble();
  int get _manuscriptId => widget.manuscript['id'];
  String get _title => widget.manuscript['title'] ?? 'Untitled';
  String get _coverUrl => widget.manuscript['coverUrl'] ?? '';

  // ─── Entry Point ────────────────────────────────────────────────────────────
  Future<void> _startPayment() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedGateway == 'KHALTI') {
        await _handleKhaltiPayment();
      } else {
        await _handleEsewaPayment();
      }
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Khalti ─────────────────────────────────────────────────────────────────
  Future<void> _handleKhaltiPayment() async {
    final result = await PaymentService.initKhaltiPayment(_manuscriptId);
    if (result['payment_url'] == null) {
      _showError(result['message'] ?? 'Failed to initiate Khalti payment');
      return;
    }
    
    final redirectUrl = result['payment_url'] as String;
    _pendingPidx = result['pidx'] as String?;

    if (_canUseWebView) {
      _openInAppWebView(redirectUrl);
    } else {
      await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() => _isPendingVerification = true);
        _startPolling();
      }
    }
  }

  // ─── eSewa ──────────────────────────────────────────────────────────────────
  Future<void> _handleEsewaPayment() async {
    final token = await AuthService.getToken();
    if (token == null) {
      _showError('Authentication required');
      return;
    }

    final result = await PaymentService.initEsewaPayment(_manuscriptId);
    if (result['payment_url'] == null || result['formData'] == null) {
      _showError(result['message'] ?? 'Failed to initiate eSewa payment');
      return;
    }

    final paymentUrl = result['payment_url'] as String;
    final formData = Map<String, String>.from(result['formData']);

    if (_canUseWebView) {
      // Mobile: opens an in-app WebView that intercepts the eSewa redirect
      _openInAppWebViewForEsewa(paymentUrl, formData);
    } else {
      // Web/Desktop fallback: open the backend's HTML form endpoint in browser.
      // Note: data: URI auto-submit is blocked by Chrome 60+, so we use the
      // backend ?type=html endpoint which returns a proper hosted HTML page.
      final token = await AuthService.getToken();
      if (token == null) {
        _showError('Authentication required');
        return;
      }
      final formUrl = Uri.parse(
        'https://fyp-backend-qzhc.onrender.com/api/payments/esewa/init-form?manuscriptId=$_manuscriptId&token=${Uri.encodeComponent(token)}',
      );
      await launchUrl(formUrl, mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() => _isPendingVerification = true);
        _startPolling();
      }
    }
  }

  // ─── InAppWebView Overlays (Mobile Only) ──────────────────────────────────
  void _openInAppWebView(String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WebViewOverlay(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        // For Khalti: passes the full redirect URL
        onReturnUrlCalled: (payload) => _handleWebViewRedirect(payload),
      ),
    );
  }

  void _openInAppWebViewForEsewa(String url, Map<String, String> formData) {
    final bodyData = formData.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WebViewOverlay(
        initialUrlRequest: URLRequest(
          url: WebUri(url),
          method: 'POST',
          body: Uint8List.fromList(utf8.encode(bodyData)),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        // For eSewa: passes either 'data:<base64>' on success or 'failure' on failure
        onReturnUrlCalled: (payload) => _handleWebViewRedirect(payload),
      ),
    );
  }

  Future<void> _handleWebViewRedirect(String payload) async {
    Navigator.pop(context); // Close the webview overlay
    setState(() => _isLoading = true);
    Map<String, dynamic> verify;

    if (_selectedGateway == 'KHALTI') {
      if (_pendingPidx == null) {
        _showError('Missing Khalti transaction ID');
        setState(() => _isLoading = false);
        return;
      }
      verify = await PaymentService.verifyKhaltiPayment(_pendingPidx!, _manuscriptId);
    } else {
      // eSewa: payload is either 'data:<base64>' for success or 'failure' for failure
      if (payload == 'failure') {
        _showError('Payment failed or was cancelled.');
        setState(() => _isLoading = false);
        return;
      }
      if (payload.startsWith('khalti:')) {
        // Khalti returns with ?pidx=...&status=Completed
        final uri = Uri.tryParse(payload.substring(7));
        final status = uri?.queryParameters['status'];
        final returnedPidx = uri?.queryParameters['pidx'];
        
        if (status != 'Completed' || returnedPidx == null) {
           _showError('Khalti payment failed or cancelled (Status: ${status ?? "Unknown"}).');
           setState(() => _isLoading = false);
           return;
        }
        
        verify = await PaymentService.verifyKhaltiPayment(returnedPidx, _manuscriptId);
      } else if (payload.startsWith('data:')) {
        final base64Data = payload.substring(5); // strip 'data:' prefix
        verify = await PaymentService.verifyEsewaPayment(base64Data, _manuscriptId);
      } else {
        // Fallback: server-side poll
        verify = await PaymentService.verifyEsewaByManuscript(_manuscriptId);
      }
    }

    setState(() => _isLoading = false);

    if (verify['purchased'] == true) {
      _showSuccessAndReturn();
    } else {
      _showError(verify['message'] ?? 'Payment failed or was cancelled.');
    }
  }

  // ─── Manual Verify (Web / Desktop Fallbacks) ────────────────────────────────
  Future<void> _verifyManualFallback({bool isAutoPolling = false}) async {
    // Only show loading indicator if user clicked manually
    if (!isAutoPolling) {
      setState(() => _isLoading = true);
    }
    Map<String, dynamic> verify;

    if (_selectedGateway == 'KHALTI') {
      if (_pendingPidx == null) {
        if (!isAutoPolling) _showError('Missing payment ID. Tap "Pay" first.');
        if (!isAutoPolling) setState(() => _isLoading = false);
        return;
      }
      verify = await PaymentService.verifyKhaltiPayment(_pendingPidx!, _manuscriptId);
    } else {
      verify = await PaymentService.verifyEsewaByManuscript(_manuscriptId);
    }

    if (mounted) setState(() => _isLoading = false);

    if (verify['purchased'] == true) {
      _stopPolling();
      if (mounted) setState(() => _isPendingVerification = false);
      _showSuccessAndReturn();
    } else {
      if (!isAutoPolling) {
        _showError(verify['message'] ??
            'Payment not confirmed yet. Please complete the payment in the browser first.');
      }
    }
  }

  void _showSuccessAndReturn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 18),
            Text('Unlocked!',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24, color: const Color(0xFF1D2939))),
            const SizedBox(height: 8),
            Text('"$_title" is now unlocked.\nEnjoy reading!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _salmonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Reading',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Unlock Manuscript',
            style: GoogleFonts.dmSerifDisplay(
                color: const Color(0xFF1D2939), fontSize: 20)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _manuscriptCard(),
              const SizedBox(height: 28),

              if (_isPendingVerification)
                _pendingVerificationWidget()
              else ...[
                Text('Choose Payment Method',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade900)),
                const SizedBox(height: 16),

                _gatewayCard(
                    gateway: 'KHALTI',
                    label: 'Khalti',
                    subtitle: 'Pay securely with your Khalti wallet',
                    color: _khaltiColor,
                    logo: '🟣'),
                const SizedBox(height: 12),
                _gatewayCard(
                    gateway: 'ESEWA',
                    label: 'eSewa',
                    subtitle: 'Pay securely with your eSewa wallet',
                    color: _esewaColor,
                    logo: '🟢'),

                const SizedBox(height: 28),
                _benefitsCard(),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedGateway == 'KHALTI'
                          ? _khaltiColor
                          : _esewaColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Pay NPR ${_price.toStringAsFixed(0)} via '
                            '${_selectedGateway == 'KHALTI' ? 'Khalti' : 'eSewa'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('Your payment is secure & encrypted.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manuscriptCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_salmonColor.withOpacity(0.9), _salmonColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _salmonColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _coverUrl.isNotEmpty
                ? Image.network(_coverUrl,
                    width: 70, height: 100, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder())
                : _coverPlaceholder(),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title,
                    style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('NPR ${_price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingVerificationWidget() {
    final color =
        _selectedGateway == 'KHALTI' ? _khaltiColor : _esewaColor;
    final name = _selectedGateway == 'KHALTI' ? 'Khalti' : 'eSewa';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08), shape: BoxShape.circle),
            child:
                Icon(Icons.open_in_browser_rounded, size: 44, color: color),
          ),
          const SizedBox(height: 20),
          Text('Complete Payment in Browser',
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22, color: const Color(0xFF1D2939)),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'A browser window opened with the $name payment page.\n'
            'Complete the payment there, then tap the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _verifyManualFallback(isAutoPolling: false),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: const Text('I Have Completed the Payment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _salmonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              _stopPolling();
              setState(() => _isPendingVerification = false);
            },
            child: Text('Go Back',
                style: TextStyle(color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What you get',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700)),
          const SizedBox(height: 12),
          _benefitRow(Icons.book_outlined, 'Full access to all chapters'),
          _benefitRow(Icons.all_inclusive, 'Lifetime access — pay once'),
          _benefitRow(Icons.security_rounded,
              'Secure via ${_selectedGateway == 'KHALTI' ? 'Khalti' : 'eSewa'}'),
        ],
      ),
    );
  }

  Widget _gatewayCard({
    required String gateway,
    required String label,
    required String subtitle,
    required Color color,
    required String logo,
  }) {
    final isSelected = _selectedGateway == gateway;
    return GestureDetector(
      onTap: () => setState(() => _selectedGateway = gateway),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(logo, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? color : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _salmonColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 70, height: 100,
      decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.menu_book, color: Colors.grey.shade400, size: 32),
    );
  }
}

// ─── Shared Mobile WebView Overlay ──────────────────────────────────────────
class _WebViewOverlay extends StatefulWidget {
  final URLRequest initialUrlRequest;
  final ValueChanged<String> onReturnUrlCalled;

  const _WebViewOverlay({
    required this.initialUrlRequest,
    required this.onReturnUrlCalled,
  });

  @override
  State<_WebViewOverlay> createState() => _WebViewOverlayState();
}

class _WebViewOverlayState extends State<_WebViewOverlay> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Secure Checkout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          // Progress Bar
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 3, color: Color(0xFFFF8B7D)),
            
          // WebView Container
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: widget.initialUrlRequest,
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
              ),
              onWebViewCreated: (controller) => _webViewController = controller,
              // shouldOverrideUrlLoading fires BEFORE the network request is made.
              // This is critical for eSewa/Khalti: it intercepts the redirect to our
              // localhost successUrl before Chrome/WebView tries to load it.
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url?.toString();
                if (_interceptUrl(url)) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStart: (controller, url) {
                if (mounted) setState(() => _isLoading = true);
                // Belt-and-suspenders: also check on load start
                _checkUrlForReturn(url?.toString());
              },
              onLoadStop: (controller, url) {
                if (mounted) setState(() => _isLoading = false);
                _checkUrlForReturn(url?.toString());
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Called from shouldOverrideUrlLoading — returns true if we intercepted.
  bool _interceptUrl(String? urlStr) {
    if (urlStr == null) return false;
    if (urlStr.contains('/esewa/return') || urlStr.contains('/esewa/failure') || 
        urlStr.contains('/khalti/return') || urlStr.contains('/khalti/failure')) {
      _checkUrlForReturn(urlStr);
      return true; // cancel the navigation
    }
    return false;
  }

  void _checkUrlForReturn(String? urlStr) {
    if (urlStr == null) return;

    // Detect eSewa success redirect — extract the base64 data param
    if (urlStr.contains('/esewa/return')) {
      final uri = Uri.tryParse(urlStr);
      final data = uri?.queryParameters['data'];
      if (data != null && data.isNotEmpty) {
        widget.onReturnUrlCalled('data:$data');
      } else {
        widget.onReturnUrlCalled('failure');
      }
      return;
    }

    // Detect eSewa failure redirect
    if (urlStr.contains('/esewa/failure')) {
      widget.onReturnUrlCalled('failure');
      return;
    }

    // Khalti return/failure
    if (urlStr.contains('/api/payments/khalti/') &&
        (urlStr.contains('/return') || urlStr.contains('/failure'))) {
      widget.onReturnUrlCalled('khalti:$urlStr');
    }
  }
}
