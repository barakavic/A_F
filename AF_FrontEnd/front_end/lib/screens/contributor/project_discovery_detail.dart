import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/project.dart';
import '../../core/config/api_config.dart';
import '../../data/repositories/contribution_repository.dart';
import '../../data/repositories/payment_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/project_provider.dart';
import '../../data/services/socket_service.dart';

class ProjectDiscoveryDetail extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDiscoveryDetail({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<ProjectDiscoveryDetail> createState() => _ProjectDiscoveryDetailState();
}

class _ProjectDiscoveryDetailState extends ConsumerState<ProjectDiscoveryDetail> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: "254");
  final PaymentRepository _paymentRepository = PaymentRepository();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    SocketService().joinCampaign(widget.project.id!);
    
    SocketService().socket.on('payment_received', (data) {
      if (data != null && data['campaign_id'] == widget.project.id) {
        ref.invalidate(projectDetailProvider(widget.project.id!));
        ref.invalidate(activeProjectsProvider);
        
        _amountController.clear();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Payment Confirmed!"),
              content: const Text("Thank you for supporting this project! Your contribution has been added."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Okay"),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('payment_received');
    SocketService().leaveCampaign(widget.project.id!);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleFunding() async {
    final amountText = _amountController.text;
    final phoneText = _phoneController.text;

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an amount")));
      return;
    }

    if (phoneText.isNotEmpty && phoneText != "254") {
      if (!phoneText.startsWith("254") || phoneText.length != 12) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid M-Pesa number (254...)")));
        return;
      }
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid amount")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _paymentRepository.initiateStkPush(
        campaignId: widget.project.id!,
        amount: amount,
        phoneNumber: (phoneText == "254" || phoneText.isEmpty) ? null : phoneText,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Request Sent!"),
            content: Text(result['message'] ?? "Please enter your M-Pesa PIN on your phone to complete the contribution."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                }, 
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for live project updates, fall back to the initial project if loading/missing
    final liveProjectAsync = ref.watch(projectDetailProvider(widget.project.id!));
    final project = liveProjectAsync.value ?? widget.project;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.refresh(projectDetailProvider(widget.project.id!).future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // Premium Header with Image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      (() {
                        String? coverUrl = project.coverImageUrl;
                        if (coverUrl != null && coverUrl.startsWith('/static/')) {
                          coverUrl = '${ApiConfig.rootUrl}$coverUrl';
                        }
                        
                        return coverUrl != null 
                          ? Image.network(
                              coverUrl, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey.shade400),
                              ),
                            )
                          : Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.rocket_launch_outlined, size: 60, color: AppColors.primary.withOpacity(0.4)),
                            );
                      })(),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black45, Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                project.category,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              project.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "by ${project.fundraiserName ?? 'Verified Fundraiser'}",
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Funding Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBadge(Icons.timer_outlined, "${project.daysLeft} Days Left", Colors.blue),
                          _buildStatBadge(Icons.people_outline, "${project.backersCount} Backers", Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("${((project.raisedAmount / (project.goalAmount > 0 ? project.goalAmount : 1.0)) * 100).toInt()}%", 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (project.raisedAmount / (project.goalAmount > 0 ? project.goalAmount : 1.0)),
                              minHeight: 12,
                              backgroundColor: const Color(0xFFEEEEEE),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "KES ${project.raisedAmount.toInt()} raised of KES ${project.goalAmount.toInt()} goal",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Description
                      const Text(
                        "About Project",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.description,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15),
                      ),
                      
                      const SizedBox(height: 32),

                      // Fundraiser Trust
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              child: Icon(Icons.person_outline, color: Colors.grey.shade400, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(project.fundraiserName ?? 'Verified Fundraiser', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text("Verified Organization", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.grey),
                              onPressed: () {},
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 160), // Increased buffer to clear sticky button bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),

          // Sticky Bottom Action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  hintText: "Phone (254...)",
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  hintText: "Amount",
                                  border: InputBorder.none,
                                  prefixText: "KES ",
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _handleFunding,
                        child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Fund Project", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
