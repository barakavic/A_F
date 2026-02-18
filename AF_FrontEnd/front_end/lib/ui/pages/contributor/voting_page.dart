import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/vote_repository.dart';
import 'pending_votes_page.dart';

class VotingPage extends StatefulWidget {
  final PendingVote vote;

  const VotingPage({super.key, required this.vote});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  bool _isLoading = false;
  String? _selectedVote;

  void _submitVote(String value) async {
    setState(() {
      _selectedVote = value;
      _isLoading = true;
    });

    // Simulate Digital Signing Delay
    await Future.delayed(const Duration(seconds: 2));

    // Mocking the cryptographic signature for the panel demo
    final String mockSignature = "0x${widget.vote.milestoneId.replaceAll('-', '')}demo${value == 'yes' ? '1' : '0'}sig";
    final String mockNonce = DateTime.now().millisecondsSinceEpoch.toString();

    final repo = VoteRepository();
    final success = await repo.submitVote(
      milestoneId: widget.vote.milestoneId,
      voteValue: value,
      signature: mockSignature,
      nonce: mockNonce,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit vote. Re-check your connection."), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            const Text("Vote Sealed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              "Your choice has been cryptographically signed and added to the ledger.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to pending list
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text("BACK TO LIST"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("Review Evidence", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading ? _buildSigningState() : _buildReviewState(),
    );
  }

  Widget _buildSigningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          const Text("GENERATING DIGITAL SEAL", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Text(
            "Signing payload for Milestone ${widget.vote.milestoneNumber}...\nThis ensures your vote cannot be tampered with.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.vote.campaignTitle, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text("Milestone ${widget.vote.milestoneNumber}: ${widget.vote.description}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          const Text("Submitted Evidence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildEvidencePreview(),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("FUNDRAISER'S COMMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  widget.vote.evidenceDescription ?? "No additional comments provided by the fundraiser.",
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          
          const Text("Cast Your Vote", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Do you approve the release of funds for this phase?", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _voteButton("YES, APPROVE", Colors.green, "yes"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _voteButton("NO, REJECT", Colors.red, "no"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text("ABSTAIN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage("https://via.placeholder.com/600x400?text=Milestone+Evidence+Photo"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
        ),
        child: const Center(child: Icon(Icons.zoom_in, color: Colors.white, size: 48)),
      ),
    );
  }

  Widget _voteButton(String label, Color color, String value) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () => _submitVote(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
