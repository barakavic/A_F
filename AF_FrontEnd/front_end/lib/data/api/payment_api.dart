import 'api_client.dart';
import '../../core/config/api_config.dart';

class PaymentApi {
  final ApiClient _apiClient = ApiClient();

  /// Initiate an M-Pesa STK Push
  Future<Map<String, dynamic>> initiateStkPush({
    required String campaignId,
    required double amount,
    String? phoneNumber,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'campaign_id': campaignId,
        'amount': amount,
      };
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        data['phone_number'] = phoneNumber;
      }

      final response = await _apiClient.post(
        ApiConfig.stkPush,
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
