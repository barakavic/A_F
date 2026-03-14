import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? (throw Exception('API_BASE_URL not found in .env'));
  
  // Base URL for static assets (strips /api/v1)
  static String get rootUrl => baseUrl.replaceAll('/api/v1', '');

  // Auth Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';
  static String get registerContributor => '$baseUrl/auth/register/contributor';
  static String get registerFundraiser => '$baseUrl/auth/register/fundraiser';

  // Campaign Endpoints
  static String get campaigns => '$baseUrl/campaigns'; // No trailing slash anymore
  static String get myCampaigns => '$baseUrl/campaigns/my-campaigns';
  static String get fundraiserStats => '$baseUrl/campaigns/fundraiser/stats';
  static String launchCampaign(String id) => '$baseUrl/campaigns/$id/launch';
  static String campaignProgress(String id) => '$baseUrl/campaigns/$id/progress';
  static String campaignTimeline(String id) => '$baseUrl/campaigns/$id/timeline';
  static String cancelCampaign(String id) => '$baseUrl/campaigns/$id/cancel';

  // Contribution & Escrow
  static String get contributions => '$baseUrl/contributions/';
  static String get myContributions => '$baseUrl/contributions/my-contributions';
  static String get contributorStats => '$baseUrl/contributions/stats';
  static String get walletStats => '$baseUrl/contributions/wallet-stats';
  static String get escrowStatus => '$baseUrl/escrow/';

  // Voting
  static String get submitVote => '$baseUrl/votes/submit';
  static String get voteResults => '$baseUrl/votes/results';
  static String get waiveVote => '$baseUrl/votes/waive';
  static String get pendingVotes => '$baseUrl/votes/pending';

  // Payments
  static String get stkPush => '$baseUrl/payments/stk-push';

  // Simulation (Tester Tool)
  static String simulateAdvance(String id) => '$baseUrl/simulation/$id/advance';

  // Network Settings
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
