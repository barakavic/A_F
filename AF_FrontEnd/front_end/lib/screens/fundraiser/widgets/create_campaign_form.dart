import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project.dart';

class CreateCampaignForm extends StatefulWidget {
  final Function(Project) onSubmit;

  const CreateCampaignForm({super.key, required this.onSubmit});

  @override
  State<CreateCampaignForm> createState() => _CreateCampaignFormState();
}

class _CreateCampaignFormState extends State<CreateCampaignForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _goalController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 600, // Fixed height or use dynamic based on content/viewport
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create Campaign", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildTextField("Project Title", _titleController),
            const SizedBox(height: 16),
            _buildTextField("Description", _descController, maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField("Goal (KES)", _goalController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Duration (Months)", _durationController, isNumber: true)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Launch Campaign", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final project = Project(
        title: _titleController.text,
        description: _descController.text,
        goalAmount: double.parse(_goalController.text),
        durationMonths: int.parse(_durationController.text),
        fundraiserId: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", // Hardcoded Test Fundraiser ID
      );

      await widget.onSubmit(project);
      
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
