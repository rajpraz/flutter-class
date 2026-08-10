import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/cart_item.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cart_service.dart';
import 'package:untitled3/services/notification_service.dart';
import 'package:untitled3/services/order_service.dart';
import 'package:untitled3/services/pricing_service.dart';
import 'homepage.dart';

enum PaymentMethod { esewa, cod, khalti }

class CheckoutPage extends StatefulWidget {
  final double price;
  CheckoutPage({super.key, required this.price});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
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

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    loadCartItems();
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
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingCart = false);
      return;
    }
    try {
      final items = await CartService.streamCart(uid).first;
      if (!mounted) return;
      setState(() {
        cartItems = items;
        _loadingCart = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCart = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load cart: ${e.toString()}')));
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

  Future<void> _completeOrder() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null || cartItems.isEmpty) return;

    setState(() => _placingOrder = true);
    try {
      final orderId = await OrderService.createOrder(
        buyerId: uid,
        items: cartItems,
        shippingAddress: currentAddress,
      );
      await CartService.clearCart(uid);
      try {
        await NotificationService.create(
          uid: uid,
          title: 'Order placed',
          body: 'Your order of ${cartItems.length} item(s) has been placed and is being prepared.',
          type: 'order_placed',
          orderId: orderId,
        );
      } catch (_) {
        // Best-effort: a failed notification write shouldn't block order success.
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Order placed successfully'),
            content: const Text(
                'Your puja essentials are being prepared for delivery.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false);
                },
                child: const Text('Continue shopping'),
              ),
            ],
          );
        },
      );
    } on OrderValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not place order: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  void proceedToPayment() {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        currentAddress.isEmpty ||
        emailController.text.isEmpty ||
        selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill all fields and select a payment method')),
      );
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (selectedPaymentMethod != PaymentMethod.khalti) {
      // eSewa / Cash on Delivery: no live gateway wired up yet, so we place
      // the order directly.
      _completeOrder();
      return;
    }

    final totalAmount = widget.price + PricingService.deliveryFee;

    KhaltiScope.of(context).pay(
        config: PaymentConfig(
            amount: (totalAmount * 100).toInt(),
            productIdentity: 'puja-pasal',
            productName: 'Pooja Pasal Order'),
        preferences: [
          PaymentPreference.khalti,
          PaymentPreference.connectIPS,
          PaymentPreference.eBanking,
        ],
        onSuccess: (success) => _completeOrder(),
        onFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${failure.message}')),
          );
        });
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
                                      : Text(
                                          currentAddress.isEmpty
                                              ? (_locationError ??
                                                  'No address set')
                                              : currentAddress,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _locationError != null
                                                  ? AppColors.error
                                                  : AppColors.text),
                                        ),
                                ),
                                TextButton(
                                  onPressed: () => _showDetailsSheet(context),
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
                          AppColors.success,
                          enabled: false),
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
