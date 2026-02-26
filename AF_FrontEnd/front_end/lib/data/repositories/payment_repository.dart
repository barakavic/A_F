import '../api/payment_api.dart';

class PaymentRepository {
  final PaymentApi _api = PaymentApi();

  Future<Map<String, dynamic>> initiateStkPush({
    required String campaignId,
    required double amount,
    String? phoneNumber,
  }) async {
    try {
      return await _api.initiateStkPush(
        campaignId: campaignId,
        amount: amount,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      rethrow;
    }
  }
}
