import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:front_end/providers/campaign_wizard_provider.dart';
import 'wizard_shared_widgets.dart';

class Step1BasicInfo extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descController;

  const Step1BasicInfo({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's your project about?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Provide a clear and compelling title and description for your campaign.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            WizardTextField(
              label: "Campaign Title",
              controller: titleController,
              hint: "e.g., Clean Water for Kitui",
              validator: (v) => v!.length < 5 ? "Title is too short" : null,
            ),
            const SizedBox(height: 24),
            WizardTextField(
              label: "Story & Description",
              controller: descController,
              hint: "Explain why this project matters...",
              maxLines: 6,
              validator: (v) => v!.length < 20 ? "Description is too short" : null,
            ),
            const SizedBox(height: 24),
            _buildImagePicker(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(WidgetRef ref) {
    final state = ref.watch(campaignWizardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Cover Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              ref.read(campaignWizardProvider.notifier).updateCoverImage(image.path);
            }
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: state.coverImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(state.coverImagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text("Tap to add a cover photo", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
