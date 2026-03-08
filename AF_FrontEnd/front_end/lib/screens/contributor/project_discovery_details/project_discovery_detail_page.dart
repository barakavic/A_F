import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/project.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../providers/project_provider.dart';
import '../../../../data/services/socket_service.dart';
import 'widgets/project_header.dart';
import 'widgets/project_stats_row.dart';
import 'widgets/project_funding_progress.dart';
import 'widgets/project_fundraiser_trust.dart';
import 'widgets/project_funding_bar.dart';

class ProjectDiscoveryDetail extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDiscoveryDetail({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<ProjectDiscoveryDetail> createState() =>
      _ProjectDiscoveryDetailState();
}

class _ProjectDiscoveryDetailState
    extends ConsumerState<ProjectDiscoveryDetail> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(text: "254");
  final PaymentRepository _paymentRepository = PaymentRepository();
  bool _isSubmitting = false;
  String? _amountError;

  void _validateAmount(String value, double goal, double raised) {
    if (value.isEmpty) {
      setState(() => _amountError = null);
      return;
    }
    final amount = double.tryParse(value);
    final remaining = goal - raised;
    setState(() {
      if (amount == null) {
        _amountError = "Invalid amount";
      } else if (amount > remaining) {
        _amountError = "Max is KES ${remaining.toInt()}";
      } else if (amount <= 0) {
        _amountError = "Must be > 0";
      } else {
        _amountError = null;
      }
    });
  }

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
          Navigator.of(context).popUntil((route) => route is PageRoute);
          _showPaymentConfirmedDialog();
        }
      }
    });
  }

  void _showPaymentConfirmedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Payment Confirmed!"),
        content: const Text(
            "Thank you for supporting this project! Your contribution has been added."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SocketService().socket.off('payment_received');
    SocketService().leaveCampaign(widget.project.id!);
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleFunding() async {
    final amountText = _amountController.text;
    final phoneText = _phoneController.text;

    if (amountText.isEmpty) {
      _showSnackBar("Please enter an amount");
      return;
    }

    if (phoneText.isNotEmpty && phoneText != "254") {
      if (!phoneText.startsWith("254") || phoneText.length != 12) {
        _showSnackBar("Please enter a valid M-Pesa number (254...)");
        return;
      }
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar("Invalid amount");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _paymentRepository.initiateStkPush(
        campaignId: widget.project.id!,
        amount: amount,
        phoneNumber:
            (phoneText == "254" || phoneText.isEmpty) ? null : phoneText,
      );

      if (mounted) {
        _showRequestSentDialog(result['message']);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Payment failed: $e");
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRequestSentDialog(String? message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Sent!"),
        content: Text(message ??
            "Please enter your M-Pesa PIN on your phone to complete the contribution."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveProjectAsync =
        ref.watch(projectDetailProvider(widget.project.id!));
    final project = liveProjectAsync.value ?? widget.project;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.refresh(projectDetailProvider(widget.project.id!).future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ProjectHeader(project: project),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProjectStatsRow(
                          daysLeft: project.daysLeft,
                          backersCount: project.backersCount,
                        ),
                        const SizedBox(height: 24),
                        ProjectFundingProgress(
                          raised: project.raisedAmount,
                          goal: project.goalAmount,
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "About Project",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          project.description,
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.6,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        ProjectFundraiserTrust(
                          fundraiserName: project.fundraiserName,
                        ),
                        const SizedBox(height: 160),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProjectFundingBar(
            phoneController: _phoneController,
            amountController: _amountController,
            amountError: _amountError,
            isSubmitting: _isSubmitting,
            onFundPressed: _handleFunding,
            onAmountChanged: (val) =>
                _validateAmount(val, project.goalAmount, project.raisedAmount),
          ),
        ],
      ),
    );
  }
}
