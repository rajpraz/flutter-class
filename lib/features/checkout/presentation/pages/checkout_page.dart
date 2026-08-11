import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/utils/error_mapper.dart';
import 'package:untitled3/features/addresses/domain/entities/address.dart';
import 'package:untitled3/features/addresses/presentation/providers/address_providers.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';
import 'package:untitled3/features/cart/domain/entities/cart_item.dart';
import 'package:untitled3/features/cart/domain/pricing_service.dart';
import 'package:untitled3/features/cart/presentation/providers/cart_providers.dart';
import 'package:untitled3/features/orders/domain/entities/order.dart';
import 'package:untitled3/features/orders/presentation/providers/order_providers.dart';
import 'package:untitled3/features/payments/presentation/providers/payment_providers.dart';

enum PaymentMethod { esewa, cod, khalti }

class CheckoutPage extends ConsumerStatefulWidget {
  final double price;
  const CheckoutPage({super.key, required this.price});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String currentAddress = '';
  double latitude = 0.0;
  double longitude = 0.0;
  List<CartItem> cartItems = [];
  bool _loadingCart = true;
  bool _placingOrder = false;
  bool _locatingAddress = true;
  String? _locationError;
  PaymentMethod? selectedPaymentMethod;

  /// Set when the buyer picked one of their saved addresses instead of
  /// live-detected/manually-entered location. Cleared if they switch back.
  Address? _selectedAddress;

  /// Generated once per checkout attempt (not per network call), so a retry
  /// after a timeout reuses the same key and functions/src/orders/
  /// createOrder.ts's idempotency check prevents a duplicate order.
  late final String _idempotencyKey =
      '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    loadCartItems();
    _initAddress();
  }

  /// Prefers the buyer's default saved address, if any, over live
  /// geolocation — falls back to detecting location for buyers with no
  /// saved addresses yet.
  Future<void> _initAddress() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid != null) {
      try {
        final addresses = await ref.read(addressesProvider(uid).future);
        Address? preferred;
        for (final address in addresses) {
          if (address.isDefault) {
            preferred = address;
            break;
          }
        }
        preferred ??= addresses.isNotEmpty ? addresses.first : null;
        if (preferred != null && mounted) {
          setState(() {
            _selectedAddress = preferred;
            currentAddress = preferred!.formatted;
            _locatingAddress = false;
          });
          return;
        }
      } catch (_) {
        // Fall through to live geolocation below.
      }
    }
    if (mounted) getCurrentLocation();
  }

  Widget buildCheckoutImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: AppColors.card,
        child: const Icon(Icons.temple_hindu, color: AppColors.primary),
      );
    }
    return Image.network(
      imagePath,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          color: Colors.orange.shade100,
          child: const Icon(Icons.temple_hindu, color: Colors.deepOrange),
        );
      },
    );
  }

  Future<void> loadCartItems() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingCart = false);
      return;
    }
    try {
      final items = await ref.read(cartRepositoryProvider).streamCart(uid).first;
      if (!mounted) return;
      setState(() {
        cartItems = items;
        _loadingCart = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCart = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load cart: ${friendlyErrorMessage(e)}')));
    }
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      _locatingAddress = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are turned off. Enable them or enter your address manually.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied. Enter your address manually instead.';
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      latitude = position.latitude;
      longitude = position.longitude;

      final placemarks =
          await Geocoding().placemarkFromCoordinates(latitude, longitude);
      final place = placemarks.first;
      if (!mounted) return;
      setState(() {
        currentAddress =
            '${place.subLocality}, ${place.locality}, ${place.country}';
        _locatingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locatingAddress = false;
        _locationError = e is String
            ? e
            : 'Could not detect your location. Enter your address manually.';
      });
    }
  }

  void _showOrderPlacedDialog({required bool paid}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order placed successfully'),
          content: Text(paid
              ? 'Your puja essentials are being prepared for delivery.'
              : 'Your order has been placed. Pay Rs.${(widget.price + PricingService.deliveryFee).toStringAsFixed(2)} on delivery.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(RouteNames.home);
              },
              child: const Text('Continue shopping'),
            ),
          ],
        );
      },
    );
  }

  /// Creates the order via the trusted `createOrder` Cloud Function (see
  /// lib/features/orders/data/datasources/order_remote_data_source.dart) —
  /// the server re-reads product prices/stock and computes the
  /// authoritative total; nothing here decides pricing or touches
  /// Firestore directly. Order-placed notifications are sent by the
  /// backend (functions/src/notifications/onOrderWrite.ts) once deployed,
  /// not written by this client.
  Future<void> _completeCodOrder() async {
    if (cartItems.isEmpty) return;
    setState(() => _placingOrder = true);
    try {
      await ref.read(orderControllerProvider.notifier).placeOrder(
            items: cartItems,
            shippingAddress: currentAddress,
            paymentMethod: 'cod',
            idempotencyKey: _idempotencyKey,
          );
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid != null) await ref.read(cartControllerProvider.notifier).clearCart(uid);
      _showOrderPlacedDialog(paid: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  /// Khalti flow: create the order first (server computes the
  /// authoritative total, used as the exact amount charged), then launch
  /// Khalti with that amount. `onSuccess` is only the SDK reporting the
  /// wallet flow finished — it is never trusted as proof of payment; the
  /// order stays `paymentStatus: pending` until `verifyKhaltiPayment`
  /// independently confirms it with Khalti's server-side lookup API.
  Future<void> _completeKhaltiOrder() async {
    if (cartItems.isEmpty || !mounted) return;
    setState(() => _placingOrder = true);
    final CreateOrderResult order;
    try {
      order = await ref.read(orderControllerProvider.notifier).placeOrder(
            items: cartItems,
            shippingAddress: currentAddress,
            paymentMethod: 'khalti',
            idempotencyKey: _idempotencyKey,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _placingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
      return;
    }
    if (mounted) setState(() => _placingOrder = false);
    if (!mounted) return;

    KhaltiScope.of(context).pay(
        config: PaymentConfig(
            amount: (order.totalAmount * 100).round(),
            productIdentity: order.orderId,
            productName: 'Pooja Pasal Order'),
        preferences: [
          PaymentPreference.khalti,
          PaymentPreference.connectIPS,
          PaymentPreference.eBanking,
        ],
        onSuccess: (success) async {
          if (!mounted) return;
          setState(() => _placingOrder = true);
          try {
            await ref
                .read(paymentControllerProvider.notifier)
                .verifyKhalti(orderId: order.orderId, pidx: success.idx);
            final uid = ref.read(authRepositoryProvider).currentUser?.uid;
            if (uid != null) await ref.read(cartControllerProvider.notifier).clearCart(uid);
            _showOrderPlacedDialog(paid: true);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Order placed, but payment could not be confirmed: ${friendlyErrorMessage(e)} Please check My Orders or contact support.')));
          } finally {
            if (mounted) setState(() => _placingOrder = false);
          }
        },
        onFailure: (failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Payment failed: ${failure.message}. Your order was created and is waiting for payment.')),
          );
        });
  }

  /// eSewa flow: create the order first (same reasoning as Khalti — the
  /// server-computed total is what's actually charged), then push the
  /// WebView payment page. That page itself calls `verifyEsewaPayment`
  /// before ever popping `true` — this method never marks anything paid
  /// based on the WebView redirect alone.
  Future<void> _completeEsewaOrder() async {
    if (cartItems.isEmpty || !mounted) return;
    setState(() => _placingOrder = true);
    final CreateOrderResult order;
    try {
      order = await ref.read(orderControllerProvider.notifier).placeOrder(
            items: cartItems,
            shippingAddress: currentAddress,
            paymentMethod: 'esewa',
            idempotencyKey: _idempotencyKey,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _placingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
      return;
    }
    if (mounted) setState(() => _placingOrder = false);
    if (!mounted) return;

    final paid = await context.push<bool>(RouteNames.esewaPaymentPath(order.orderId));
    if (!mounted) return;
    if (paid == true) {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid != null) await ref.read(cartControllerProvider.notifier).clearCart(uid);
      _showOrderPlacedDialog(paid: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Payment was not completed. Your order was created and is waiting for payment — you can retry from My Orders.')));
    }
  }

  void proceedToPayment() {
    if (currentAddress.isEmpty || selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please choose a delivery address and payment method')),
      );
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (selectedPaymentMethod == PaymentMethod.khalti) {
      _completeKhaltiOrder();
      return;
    }
    if (selectedPaymentMethod == PaymentMethod.esewa) {
      _completeEsewaOrder();
      return;
    }

    _completeCodOrder();
  }

  Widget _paymentTile(PaymentMethod method, String label, IconData icon, Color color,
      {bool enabled = true}) {
    final selected = selectedPaymentMethod == method;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? () => setState(() => selectedPaymentMethod = method) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.border, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(enabled ? label : '$label (Coming soon)',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: selectedPaymentMethod,
                activeColor: AppColors.accent,
                onChanged: enabled ? (value) => setState(() => selectedPaymentMethod = value) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _loadingCart || _placingOrder;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _loadingCart
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      const Text('Deliver to',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _locationError != null
                                    ? AppColors.error
                                    : AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    _locationError != null
                                        ? Icons.location_off_outlined
                                        : Icons.location_on_outlined,
                                    color: _locationError != null
                                        ? AppColors.error
                                        : AppColors.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _locatingAddress
                                      ? const Row(
                                          children: [
                                            SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2)),
                                            SizedBox(width: 10),
                                            Text('Detecting your location...'),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (_selectedAddress != null)
                                              Text(_selectedAddress!.label,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.accent)),
                                            Text(
                                              currentAddress.isEmpty
                                                  ? (_locationError ?? 'No address set')
                                                  : currentAddress,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _locationError != null
                                                      ? AppColors.error
                                                      : AppColors.text),
                                            ),
                                          ],
                                        ),
                                ),
                                TextButton(
                                  onPressed: () => _showAddressPicker(context),
                                  child: const Text('Change',
                                      style: TextStyle(color: AppColors.accent)),
                                ),
                              ],
                            ),
                            if (_locationError != null && !_locatingAddress)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 34),
                                child: TextButton.icon(
                                  onPressed: getCurrentLocation,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry detection'),
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      alignment: Alignment.centerLeft),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Delivery Time',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: AppColors.accent),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('Standard Delivery (1-2 Days)')),
                            Text('Rs.${PricingService.deliveryFee.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Payment Method',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _paymentTile(PaymentMethod.khalti, 'Khalti', Icons.account_balance_wallet,
                          AppColors.khaltiPurple),
                      _paymentTile(PaymentMethod.esewa, 'eSewa', Icons.payments_outlined,
                          AppColors.success),
                      _paymentTile(PaymentMethod.cod, 'Cash on Delivery', Icons.money,
                          AppColors.muted),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), color: AppColors.surface,
                            border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Summary',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Subtotal'),
                              Text('Rs.${widget.price.toStringAsFixed(2)}'),
                            ]),
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Discount'),
                              Text('- Rs.${PricingService.discount.toStringAsFixed(0)}'),
                            ]),
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Delivery'),
                              Text('Rs.${PricingService.deliveryFee.toStringAsFixed(0)}'),
                            ]),
                            const Divider(height: 18),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Total Payable',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Rs.${(widget.price + PricingService.deliveryFee).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Items in your order',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (cartItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Your cart is empty', style: TextStyle(color: AppColors.muted)),
                        ),
                      ...cartItems.map((item) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: buildCheckoutImage(item.image)),
                              title: Text(item.name),
                              subtitle: Text('Qty: ${item.qty}'),
                              trailing: Text('Rs.${item.subtotal.toStringAsFixed(2)}'),
                            ),
                          )),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isBusy ? null : proceedToPayment,
                          child: const Text('Place Order',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                              'Total Payable: Rs.${(widget.price + PricingService.deliveryFee).toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.muted)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_placingOrder)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  void _showAddressPicker(BuildContext context) {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose delivery address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (uid != null)
              Consumer(
                builder: (context, ref, _) {
                  final addressesAsync = ref.watch(addressesProvider(uid));
                  return addressesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, st) => const SizedBox.shrink(),
                    data: (addresses) {
                      if (addresses.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: addresses
                            .map((address) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.location_on_outlined,
                                      color: AppColors.accent),
                                  title: Text(address.label,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${address.recipientName}\n${address.fullAddress}'),
                                  isThreeLine: true,
                                  onTap: () {
                                    setState(() {
                                      _selectedAddress = address;
                                      currentAddress = address.formatted;
                                      _locationError = null;
                                      _locatingAddress = false;
                                    });
                                    Navigator.pop(sheetContext);
                                  },
                                ))
                            .toList(),
                      );
                    },
                  );
                },
              ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.my_location, color: AppColors.accent),
              title: const Text('Use my current location'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedAddress = null);
                getCurrentLocation();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_location_alt_outlined, color: AppColors.accent),
              title: const Text('Enter address manually'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedAddress = null);
                _showDetailsSheet(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact & delivery details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 10),
            TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Delivery address')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (addressController.text.trim().isNotEmpty) {
                    setState(() => currentAddress = addressController.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
