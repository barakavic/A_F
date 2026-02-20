class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://adbe-102-213-241-213.ngrok-free.app/api/v1';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String registerContributor = '$baseUrl/auth/register/contributor';
  static const String registerFundraiser = '$baseUrl/auth/register/fundraiser';

  // Campaign Endpoints
  static const String campaigns = '$baseUrl/campaigns/'; // Trailing slash for POST /
  static const String myCampaigns = '$baseUrl/campaigns/my-campaigns/';
  static String launchCampaign(String id) => '$baseUrl/campaigns/$id/launch';
  static String campaignProgress(String id) => '$baseUrl/campaigns/$id/progress';
  static String campaignTimeline(String id) => '$baseUrl/campaigns/$id/timeline';
  static String cancelCampaign(String id) => '$baseUrl/campaigns/$id/cancel';

  // Contribution & Escrow
  static const String contributions = '$baseUrl/contributions/';
  static const String myContributions = '$baseUrl/contributions/my-contributions';
  static const String escrowStatus = '$baseUrl/escrow/';

  // Voting
  static const String submitVote = '$baseUrl/votes/submit';
  static const String voteResults = '$baseUrl/votes/results';
  static const String waiveVote = '$baseUrl/votes/waive';
  static const String pendingVotes = '$baseUrl/votes/pending';

  // Payments
  static const String stkPush = '$baseUrl/payments/stk-push';

  // Network Settings
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
