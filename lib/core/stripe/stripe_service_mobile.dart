import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/app_constants.dart';

Future<void> initStripe() async {
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  await Stripe.instance.applySettings();
}
