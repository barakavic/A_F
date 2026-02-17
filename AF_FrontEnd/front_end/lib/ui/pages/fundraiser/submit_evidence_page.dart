import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/milestone.dart';
import '../../../data/repositories/campaign_repository.dart';

class SubmitEvidencePage extends StatefulWidget {
  final Milestone milestone;

  const SubmitEvidencePage({super.key, required this.milestone});

  @override
  State<SubmitEvidencePage> createState() => _SubmitEvidencePageState();
}

class _SubmitEvidencePageState extends State<SubmitEvidencePage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  bool _isLoading = false;
  File? _selectedFile;

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final repo = CampaignRepository();
        await repo.submitMilestoneEvidence(
          milestoneId: widget.milestone.id,
          description: _descController.text,
          file: _selectedFile,
        );

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context); // Go back to timeline or dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evidence submitted successfully! Voting period will start soon.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("Submit Proof of Work", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Verify your progress",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Upload images or documents that prove the completion of this milestone.",
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildFilePicker(),
              const SizedBox(height: 32),
              const Text("What was accomplished?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Describe the tasks completed and any challenges overcome...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) => v!.length < 10 ? "Please provide a more detailed description" : null,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT EVIDENCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: () {
        // Mocking file selection for now as we don't have file_picker package context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File picker triggered (Simulation)')),
        );
      },
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none), // Should be dashed in real CSS
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text("Tap to upload photos or PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 4),
            const Text("Max size: 10MB", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
