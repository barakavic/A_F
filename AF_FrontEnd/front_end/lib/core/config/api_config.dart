class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String registerContributor = '$baseUrl/auth/register/contributor';
  static const String registerFundraiser = '$baseUrl/auth/register/fundraiser';

  // Campaign Endpoints
  static const String campaigns = '$baseUrl/campaigns';
  static const String myCampaigns = '$baseUrl/campaigns/my-campaigns';

  // Contribution & Escrow
  static const String contributions = '$baseUrl/contributions';
  static const String escrowStatus = '$baseUrl/escrow';

  // Voting
  static const String submitVote = '$baseUrl/votes/submit';
  static const String voteResults = '$baseUrl/votes/results';
  static const String waiveVote = '$baseUrl/votes/waive';

  // Payments
  static const String stkPush = '$baseUrl/payments/stk-push';

  // Network Settings
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
