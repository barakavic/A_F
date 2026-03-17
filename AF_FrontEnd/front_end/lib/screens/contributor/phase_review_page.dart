import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/pending_milestone.dart';
import '../../data/services/voting_service.dart';
import '../../data/services/socket_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/crypto_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import '../../ui/pages/contributor/pending_votes_page.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'phase_review_components/phase_review_header.dart';
import 'phase_review_components/phase_budget_card.dart';
import 'phase_review_components/evidence_section.dart';
import 'phase_review_components/phase_review_summary.dart';

class PhaseReviewPage extends ConsumerStatefulWidget {
  final PendingMilestone milestone;
  const PhaseReviewPage({super.key, required this.milestone});
 
  @override
  ConsumerState<PhaseReviewPage> createState() => _PhaseReviewPageState();
}
 
class _PhaseReviewPageState extends ConsumerState<PhaseReviewPage> {
  final VotingService _votingService = VotingService();
  final SocketService _socketService = SocketService();
  bool _isSubmitting = false;
  double _completionPercent = 0.05; // Initial low value to show it's active

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    print('[SOCKET] Joining Room: ${widget.milestone.campaignId}');
    _socketService.joinCampaign(widget.milestone.campaignId);
    _socketService.onMilestoneUpdate((data) {
      print('[SOCKET] Data received for room: ${data['milestone_id']} | My ID: ${widget.milestone.milestoneId}');
      if (data['milestone_id'] == widget.milestone.milestoneId) {
        if (data.containsKey('completion_percentage') && mounted) {
          setState(() {
            final rawValue = data['completion_percentage'];
            double percent = 1.0;
            if (rawValue is num) percent = rawValue.toDouble() / 100.0;
            else if (rawValue is String) percent = (double.tryParse(rawValue) ?? 100.0) / 100.0;
            _completionPercent = percent;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _socketService.leaveCampaign(widget.milestone.campaignId);
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(amount);
  }

  Future<void> _submitVote(String voteValue) async {
    setState(() => _isSubmitting = true);
    
    // For now, we simulate the signature and nonce as we haven't implemented digital signing in the UI yet
    // In a real ASCENT implementation, this would involve a cryptographic signature from the user's private key
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final email = authProvider.userEmail;
      if (email == null) {
        throw Exception("Identity Error: Logged in user has no associated email for signing.");
      }
      print("[VOTING_DEBUG] Using email for signature: $email");
      
      // 1. Generate Deterministic Key for current user
      final privateKey = CryptoUtils.getDeterministicKey(email);
      
      // 2. Standardized Nonce
      final nonce = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 3. Real Cryptographic Signature
      final signature = CryptoUtils.signVote(
        privateKey: privateKey,
        campaignId: widget.milestone.campaignId,
        milestoneId: widget.milestone.milestoneId,
        voteValue: voteValue,
        nonce: nonce,
      );

      final success = await _votingService.submitVote(
        campaignId: widget.milestone.campaignId,
        milestoneId: widget.milestone.milestoneId,
        voteValue: voteValue,
        signature: signature,
        nonce: nonce,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          // Invalidate the pending votes list to ensure it's fresh when we go back
          ref.invalidate(pendingVotesProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vote $voteValue submitted successfully!')),
          );
          Navigator.pop(context, true); // Return true to indicate a vote was cast
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit vote. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Phase Review", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhaseReviewHeader(milestone: widget.milestone),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Phase Completion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      "${widget.milestone.daysLeft} days remaining", 
                      style: TextStyle(
                        color: widget.milestone.daysLeft < 3 ? Colors.red : Colors.orange.shade800, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w600
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  tween: Tween<double>(begin: 0, end: _completionPercent),
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor: AlwaysStoppedAnimation<Color>(value >= 1.0 ? Colors.green : Colors.blue),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                PhaseBudgetCard(milestone: widget.milestone),
                
                const SizedBox(height: 32),
                
                EvidenceSection(milestone: widget.milestone),

                const SizedBox(height: 32),
                
                // Phase Efficiency Summary
                PhaseReviewSummary(milestone: widget.milestone),
                
                const SizedBox(height: 48),
                
                // Decision Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitVote('no'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitVote('yes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

}
