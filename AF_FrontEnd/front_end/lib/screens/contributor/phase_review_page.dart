import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/pending_milestone.dart';
import '../../data/services/voting_service.dart';
import '../../data/services/socket_service.dart';

class PhaseReviewPage extends StatefulWidget {
  final PendingMilestone milestone;
  const PhaseReviewPage({super.key, required this.milestone});

  @override
  State<PhaseReviewPage> createState() => _PhaseReviewPageState();
}

class _PhaseReviewPageState extends State<PhaseReviewPage> {
  final VotingService _votingService = VotingService();
  final SocketService _socketService = SocketService();
  bool _isSubmitting = false;
  double _completionPercent = 1.0; // Standard value for review phase

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    _socketService.joinCampaign(widget.milestone.campaignId);
    _socketService.onMilestoneUpdate((data) {
      if (data['milestone_id'] == widget.milestone.milestoneId) {
        if (data.containsKey('completion_percentage') && mounted) {
          setState(() {
            _completionPercent = (data['completion_percentage'] as num).toDouble() / 100.0;
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
    final success = await _votingService.submitVote(
      milestoneId: widget.milestone.milestoneId,
      voteValue: voteValue,
      signature: "0x_MOCKED_SIGNATURE_FOR_DEMO",
      nonce: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phase #${widget.milestone.milestoneNumber}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(widget.milestone.description, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Possible payout", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          _formatCurrency(widget.milestone.releaseAmount), 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Campaign: ${widget.milestone.campaignTitle}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                ),
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
                
                // Milestone Budget
                _buildSectionHeader("Milestone Budget Breakdown"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildBudgetItem(widget.milestone.description, _formatCurrency(widget.milestone.releaseAmount)),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Release", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_formatCurrency(widget.milestone.releaseAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Visual Proof
                _buildSectionHeader("Visual Proof of Work"),
                const SizedBox(height: 12),
                if (widget.milestone.evidenceDescription != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.milestone.evidenceDescription!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(child: _buildProofImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCw3C5G0dkQgnt7XH-bjglpq7lBhzQ0uOZ4w&s')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProofImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRFd_dd5_OV72E2FVWIzny8iM9YbjYKDVtoIw&s')),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Phase Efficiency Summary
                _buildPhaseEfficiencySummary(),
                
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

  Widget _buildPhaseEfficiencySummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PhaseSummaryItem(label: "Ttl Payout Expected", value: _formatCurrency(widget.milestone.releaseAmount)),
              _PhaseSummaryItem(label: "Proof Status", value: widget.milestone.evidenceDescription != null ? "Provided" : "Pending Detail"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Phase Status: ", style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildStatusPill("Ready for Vote", Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildBudgetItem(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProofImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(url, height: 120, fit: BoxFit.cover),
    );
  }
}

class _PhaseSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _PhaseSummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
